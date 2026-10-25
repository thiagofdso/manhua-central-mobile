import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhua_mobile/services/api_service.dart';
import 'package:manhua_mobile/services/fcm_service.dart';
import 'package:manhua_mobile/services/storage_service.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

void main() {
  group('FcmService & Chapter Release Push Notifications', () {
    test('parses FCM remote message payload correctly', () {
      final payload = {
        'notification': {
          'title': 'Novo capítulo lançado!',
          'body': 'Solo Leveling Capítulo 180 já está disponível.',
        },
        'data': {
          'type': 'new_chapter',
          'manhuaSlug': 'solo-leveling',
          'chapter': '180',
          'title': 'Solo Leveling',
        }
      };

      final notification = FcmService.parsePayload(payload);
      expect(notification.manhuaSlug, 'solo-leveling');
      expect(notification.chapter, 180);
      expect(notification.title, 'Novo capítulo lançado!');
      expect(notification.body, 'Solo Leveling Capítulo 180 já está disponível.');
    });

    test('registers FCM device token with backend API', () async {
      bool tokenReceived = false;
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/users/fcm-token' && request.method == 'POST') {
          final body = jsonDecode(request.body);
          if (body['token'] == 'fcm_sample_device_token_xyz') {
            tokenReceived = true;
            return http.Response(jsonEncode({'status': 'ok'}), 200);
          }
        }
        return http.Response('{}', 400);
      });

      final storage = InMemoryStorageService();
      await storage.saveTokens(accessToken: 'sample_jwt', refreshToken: 'sample_refresh');

      final apiService = ApiService(
        baseUrl: 'http://localhost:8080',
        client: mockClient,
        storage: storage,
      );

      final fcmService = FcmService(apiService: apiService);
      final success = await fcmService.registerDeviceToken('fcm_sample_device_token_xyz');

      expect(success, isTrue);
      expect(tokenReceived, isTrue);
    });
  });
}
