import '../../../core/network/api_client.dart';
import '../../notifications/data/device_token_service.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/services/session_store.dart';

class AuthService {
  AuthService({ApiClient? apiClient, DeviceTokenService? deviceTokenService})
      : _apiClient = apiClient ?? ApiClient(ApiClient.defaultBaseUrl),
        _deviceTokenService = deviceTokenService ?? DeviceTokenService();

  final ApiClient _apiClient;
  final DeviceTokenService _deviceTokenService;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    // JWT login returns access and refresh tokens that the app stores locally.
    final response = await _apiClient.postJson(
      '/auth/token/',
      authenticated: false,
      body: {
        'username': username,
        'password': password,
      },
    ) as Map<String, dynamic>;

    await SessionStore.instance.saveTokens(
      accessToken: response['access'] as String,
      refreshToken: response['refresh'] as String,
    );

    await _deviceTokenService.syncCurrentToken();
  }

  Future<UserProfile> fetchProfile() async {
    final response = await _apiClient.getJson('/auth/me/');
    return UserProfile.fromJson(response as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    List<int>? profilePhotoBytes,
    String? profilePhotoName,
    bool removeProfilePhoto = false,
  }) async {
    final response = await _apiClient.multipartPatch(
      '/auth/me/',
      fields: {
        'username': username,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        if (removeProfilePhoto) 'remove_profile_photo': 'true',
      },
      fileFieldName: profilePhotoBytes != null ? 'profile_photo' : null,
      fileBytes: profilePhotoBytes,
      fileName: profilePhotoName,
    );
    return UserProfile.fromJson(response as Map<String, dynamic>);
  }

  String resolveMediaUrl(String path) => _apiClient.resolveUrl(path);

  Future<void> deleteAccount() async {
    await _apiClient.deleteJson('/auth/me/delete/');
    await SessionStore.instance.clear();
  }

  Future<void> register({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String password,
  }) async {
    await _apiClient.postJson(
      '/auth/register/',
      authenticated: false,
      body: {
        'username': username,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'password': password,
      },
    );
  }
}
