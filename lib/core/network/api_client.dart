import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../shared/services/session_store.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(this._baseUrl, {http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _httpClient;

  static String get defaultBaseUrl {
    // Android emulators cannot reach localhost directly, so they use 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }

    return 'http://127.0.0.1:8000/api';
  }

  Future<dynamic> getJson(
    String path, {
    bool authenticated = true,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(authenticated: authenticated),
    );
    return _decodeJson(response);
  }

  Future<dynamic> postJson(
    String path, {
    required Map<String, dynamic> body,
    bool authenticated = true,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(authenticated: authenticated),
      body: jsonEncode(body),
    );
    return _decodeJson(response);
  }

  Future<dynamic> patchJson(
    String path, {
    required Map<String, dynamic> body,
    bool authenticated = true,
  }) async {
    final response = await _httpClient.patch(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(authenticated: authenticated),
      body: jsonEncode(body),
    );
    return _decodeJson(response);
  }

  Future<dynamic> deleteJson(
    String path, {
    bool authenticated = true,
  }) async {
    final response = await _httpClient.delete(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(authenticated: authenticated),
    );
    return _decodeJson(response);
  }

  Future<dynamic> multipartPost(
    String path, {
    required Map<String, String> fields,
    required String fileFieldName,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$path'));
    request.headers.addAll(await _headers(authenticated: true, contentType: false));
    request.fields.addAll(fields);

    // Add the upload only when the user actually picked a photo.
    if (fileBytes != null && fileName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(fileFieldName, fileBytes, filename: fileName),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _decodeJson(response);
  }

  Future<dynamic> multipartPatch(
    String path, {
    required Map<String, String> fields,
    String? fileFieldName,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    final request = http.MultipartRequest('PATCH', Uri.parse('$_baseUrl$path'));
    request.headers.addAll(await _headers(authenticated: true, contentType: false));
    request.fields.addAll(fields);

    if (fileFieldName != null && fileBytes != null && fileName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(fileFieldName, fileBytes, filename: fileName),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _decodeJson(response);
  }

  String resolveUrl(String path) {
    if (path.isEmpty) {
      return '';
    }

    final uri = Uri.tryParse(path);
    if (uri != null && uri.hasScheme) {
      return path;
    }

    final baseUri = Uri.parse(_baseUrl);
    return baseUri.resolve(path).toString();
  }

  Future<Map<String, String>> _headers({
    required bool authenticated,
    bool contentType = true,
  }) async {
    final headers = <String, String>{};
    // JSON is the default for most API calls; multipart requests opt out of it.
    if (contentType) {
      headers['Content-Type'] = 'application/json';
    }

    if (authenticated) {
      // Every authenticated request tries to attach the saved JWT access token.
      await SessionStore.instance.load();
      final token = SessionStore.instance.accessToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  dynamic _decodeJson(http.Response response) {
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = _extractErrorMessage(body);
    throw ApiException(
      message,
      statusCode: response.statusCode,
    );
  }

  String _extractErrorMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      final detail = body['detail'];
      if (detail != null) {
        return detail.toString();
      }

      final fieldMessages = <String>[];
      body.forEach((key, value) {
        if (value is List) {
          fieldMessages.add('$key: ${value.join(', ')}');
        } else {
          fieldMessages.add('$key: $value');
        }
      });

      if (fieldMessages.isNotEmpty) {
        return fieldMessages.join(' | ');
      }
    }

    return 'Request failed.';
  }
}
