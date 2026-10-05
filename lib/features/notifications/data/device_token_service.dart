import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';

class DeviceTokenService {
  DeviceTokenService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(ApiClient.defaultBaseUrl);

  final ApiClient _apiClient;

  Future<void> syncCurrentToken() async {
    try {
      if (kIsWeb || Firebase.apps.isEmpty) {
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      await _apiClient.postJson(
        '/auth/device-token/',
        body: {
          'token': token,
          'platform': _platformName(),
        },
      );
    } catch (error) {
      // Notification registration must not block an otherwise valid login.
      debugPrint('Device token sync skipped: $error');
    }
  }

  String _platformName() {
    if (kIsWeb) {
      return 'web';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'web';
    }
  }
}
