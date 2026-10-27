import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../models/user_model.dart';

class AuthService {
  AuthService({ApiClient? client, SecureStorage? storage})
    : _client = client ?? ApiClient(),
      _storage = storage ?? const SecureStorage();

  final ApiClient _client;
  final SecureStorage _storage;

  Future<UserModel> login(String username, String password) async {
    final result = await _client.post('/auth/token/', {
      'username': username,
      'password': password,
    });
    if (result is! Map<String, dynamic> || result['access'] is! String) {
      throw const FormatException('The sign-in response was not valid.');
    }
    await _storage.writeAccessToken(result['access'] as String);
    return currentUser();
  }

  Future<void> logout() => _storage.clear();

  Future<UserModel> currentUser() async {
    final result = await _client.get('/auth/me/');
    if (result is! Map<String, dynamic>) {
      throw const FormatException('Profile response was not valid.');
    }
    return UserModel.fromJson(result);
  }

  Future<UserModel?> restoreSession() async {
    if (await _storage.readAccessToken() == null) return null;
    return currentUser();
  }

  Future<void> updateProfile(
    Map<String, Object?> details, {
    String? photoPath,
  }) async {
    if (photoPath == null) {
      await _client.patch('/auth/me/', details);
      return;
    }
    await _client.uploadFile(
      '/auth/me/',
      details.map((key, value) => MapEntry(key, value?.toString() ?? '')),
      filePath: photoPath,
      method: 'PATCH',
    );
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _client.post('/auth/password/change/', {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  Future<void> requestPasswordReset(String email) async {
    await _client.post('/auth/password/reset/', {'email': email});
  }

  Future<UserModel> register(Map<String, Object?> details) async {
    final result = await _client.post('/auth/register/', details);
    if (result is! Map<String, dynamic>) {
      throw const FormatException('Registration response was not valid.');
    }
    return UserModel.fromJson(result);
  }
}
