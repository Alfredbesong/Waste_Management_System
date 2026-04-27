import '../../../core/network/api_client.dart';

class ConfirmationService {
  ConfirmationService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(ApiClient.defaultBaseUrl);

  final ApiClient _apiClient;

  Future<void> submitConfirmation({
    required int reportId,
    required bool isCleared,
  }) async {
    await _apiClient.postJson(
      '/confirm/',
      body: {
        'report': reportId,
        'is_cleared': isCleared,
      },
    );
  }
}

