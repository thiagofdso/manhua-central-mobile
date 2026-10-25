import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:manhua_mobile/controllers/auth_controller.dart';
import 'package:manhua_mobile/services/api_service.dart';
import 'package:manhua_mobile/services/storage_service.dart';

void main() {
  group('AuthController Lifecycle', () {
    late InMemoryStorageService storage;

    setUp(() {
      storage = InMemoryStorageService();
    });

    test('loginWithEmail updates currentUser and isAuthenticated', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/auth/login') {
          return http.Response(
            jsonEncode({
              'accessToken': 'jwt_tok',
              'refreshToken': 'jwt_ref',
              'user': {
                'id': 'u1',
                'email': 'reader@manhua.com',
                'displayName': 'Controller Reader',
                'authProvider': 'email',
                'role': 'reader',
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost:8080',
        client: mockClient,
        storage: storage,
      );

      final controller = AuthController(apiService: apiService, storage: storage);
      expect(controller.isAuthenticated, isFalse);

      final success = await controller.loginWithEmail('reader@manhua.com', 'Pass123!');
      expect(success, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentUser?.displayName, equals('Controller Reader'));

      // Logout
      await controller.logout();
      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentUser, isNull);
    });

    test('deleteAccount purges session and resets state', () async {
      await storage.saveTokens(accessToken: 'tok_active', refreshToken: 'tok_ref');

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/users/me' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'id': 'u1',
              'email': 'reader@manhua.com',
              'displayName': 'Reader',
              'authProvider': 'email',
              'role': 'reader',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/users/me' && request.method == 'DELETE') {
          return http.Response(jsonEncode({'success': true}), 200);
        }
        return http.Response('{}', 404);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost:8080',
        client: mockClient,
        storage: storage,
      );

      final controller = AuthController(apiService: apiService, storage: storage);
      await controller.initAuth();
      expect(controller.isAuthenticated, isTrue);

      final deleted = await controller.deleteAccount();
      expect(deleted, isTrue);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentUser, isNull);
    });
  });
}
