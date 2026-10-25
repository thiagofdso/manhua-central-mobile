import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class StorageService {
  Future<void> saveTokens({required String accessToken, required String refreshToken});
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
}

class SecureStorageService implements StorageService {
  final FlutterSecureStorage _storage;
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
  }

  @override
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  @override
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  @override
  Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }
}

class InMemoryStorageService implements StorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _data['access_token'] = accessToken;
    _data['refresh_token'] = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async {
    return _data['access_token'];
  }

  @override
  Future<String?> getRefreshToken() async {
    return _data['refresh_token'];
  }

  @override
  Future<void> clearTokens() async {
    _data.remove('access_token');
    _data.remove('refresh_token');
  }
}
