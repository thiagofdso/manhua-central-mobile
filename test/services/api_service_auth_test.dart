import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:manhua_mobile/models/user.dart';
import 'package:manhua_mobile/services/api_service.dart';
import 'package:manhua_mobile/services/storage_service.dart';

void main() {
  group('ApiService & Storage Authentication', () {
    late InMemoryStorageService storage;

    setUp(() {
      storage = InMemoryStorageService();
    });

    test('loginWithGoogle sends idToken to POST /api/auth/google and persists tokens', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/google' && request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          if (body['idToken'] == 'valid_google_id_token_xyz') {
            return http.Response(
              jsonEncode({
                'accessToken': 'jwt_access_token_123',
                'refreshToken': 'jwt_refresh_token_456',
                'user': {
                  'id': 'usr-google-uuid',
                  'email': 'reader@gmail.com',
                  'displayName': 'Google Reader',
                  'avatarUrl': 'https://lh3.googleusercontent.com/avatar.jpg',
                  'authProvider': 'google',
                  'role': 'reader',
                }
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(jsonEncode({'error': 'invalid token'}), 401);
        }
        return http.Response(jsonEncode({'error': 'not found'}), 404);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost:8080',
        client: mockClient,
        storage: storage,
      );

      final result = await apiService.loginWithGoogle('valid_google_id_token_xyz');

      expect(result.user.displayName, equals('Google Reader'));
      expect(result.user.email, equals('reader@gmail.com'));
      expect(result.user.authProvider, equals(AuthProvider.google));

      // Verify tokens are stored in secure storage
      final storedAccessToken = await storage.getAccessToken();
      final storedRefreshToken = await storage.getRefreshToken();
      expect(storedAccessToken, equals('jwt_access_token_123'));
      expect(storedRefreshToken, equals('jwt_refresh_token_456'));
    });

    test('loginWithEmail sends credentials and persists JWT', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/login' && request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          if (body['email'] == 'test@example.com' && body['password'] == 'Secret123!') {
            return http.Response(
              jsonEncode({
                'accessToken': 'jwt_email_token_abc',
                'refreshToken': 'jwt_email_refresh_xyz',
                'user': {
                  'id': 'usr-email-uuid',
                  'email': 'test@example.com',
                  'displayName': 'Standard Reader',
                  'authProvider': 'email',
                  'role': 'reader',
                }
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(jsonEncode({'error': 'invalid credentials'}), 401);
        }
        return http.Response(jsonEncode({'error': 'not found'}), 404);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost:8080',
        client: mockClient,
        storage: storage,
      );

      final result = await apiService.loginWithEmail('test@example.com', 'Secret123!');

      expect(result.user.displayName, equals('Standard Reader'));
      expect(await storage.getAccessToken(), equals('jwt_email_token_abc'));
    });

    test('deleteAccount sends authenticated DELETE /api/users/me and clears tokens', () async {
      await storage.saveTokens(
        accessToken: 'valid_jwt_token',
        refreshToken: 'valid_refresh_token',
      );

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/users/me' && request.method == 'DELETE') {
          final authHeader = request.headers['Authorization'];
          if (authHeader == 'Bearer valid_jwt_token') {
            return http.Response(jsonEncode({'success': true}), 200);
          }
          return http.Response(jsonEncode({'error': 'unauthorized'}), 401);
        }
        return http.Response(jsonEncode({'error': 'not found'}), 404);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost:8080',
        client: mockClient,
        storage: storage,
      );

      final success = await apiService.deleteAccount();
      expect(success, isTrue);

      // Verify tokens were purged from storage
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });
  });
}
