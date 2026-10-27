import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  const SecureStorage();

  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> writeAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<void> clear() => _storage.deleteAll();
}