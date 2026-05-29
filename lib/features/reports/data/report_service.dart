import 'dart:convert';
import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../../../shared/models/waste_report.dart';

class ReportService {
  ReportService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(ApiClient.defaultBaseUrl);

  final ApiClient _apiClient;

  String resolveMediaUrl(String path) => _apiClient.resolveUrl(path);

  Future<List<WasteReport>> fetchReports() async {
    final response = await _apiClient.getJson('/reports/');
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(WasteReport.fromJson)
          .toList();
    }

    if (response is Map<String, dynamic>) {
      final results = response['results'];
      if (results is List) {
        return results
            .whereType<Map<String, dynamic>>()
            .map(WasteReport.fromJson)
            .toList();
      }
    }

    return const [];
  }

  Future<WasteReport> fetchReportById(int reportId) async {
    final response = await _apiClient.getJson('/reports/$reportId/');
    if (response is Map<String, dynamic>) {
      return WasteReport.fromJson(response);
    }

    throw StateError('Unexpected report response for id $reportId');
  }

  Future<WasteReport> createReport({
    required String description,
    required double latitude,
    required double longitude,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    // Keep the request valid when the user skips a photo.
    final photoBytes = imageBytes ?? base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO7l9XcAAAAASUVORK5CYII=',
    );
    final photoFileName = imageName ?? 'placeholder.png';

    final response = await _apiClient.multipartPost(
      '/reports/',
      fields: {
        'description': description,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
      fileFieldName: 'photo',
      fileBytes: photoBytes,
      fileName: photoFileName,
    );

    return WasteReport.fromJson(response as Map<String, dynamic>);
  }

  Future<WasteReport> updateStatus({
    required int reportId,
    required String status,
  }) async {
    final response = await _apiClient.patchJson(
      '/reports/$reportId/',
      body: {'status': status},
    );
    return WasteReport.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteReport(int reportId) async {
    await _apiClient.deleteJson('/reports/$reportId/');
  }
}
