import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:manhua_mobile/controllers/auth_controller.dart';
import 'package:manhua_mobile/models/user.dart';
import 'package:manhua_mobile/screens/profile_screen.dart';
import 'package:manhua_mobile/services/api_service.dart';
import 'package:manhua_mobile/services/download_manager.dart';
import 'package:manhua_mobile/services/offline_reader_service.dart';
import 'package:manhua_mobile/services/storage_service.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

void main() {
  group('ProfileScreen & Google Play Account Deletion Compliance', () {
    testWidgets('renders user profile and triggers mandatory in-app account deletion dialog', (tester) async {
      bool deleteCalled = false;
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/users/me' && request.method == 'DELETE') {
          deleteCalled = true;
          return http.Response('', 204);
        }
        return http.Response('{}', 200);
      });

      final storage = InMemoryStorageService();
      await storage.saveTokens(accessToken: 'sample_token', refreshToken: 'sample_refresh');

      final apiService = ApiService(
        baseUrl: 'http://localhost:8080',
        client: mockClient,
        storage: storage,
      );

      final authController = AuthController(apiService: apiService, storage: storage);
      authController.setUserForTesting(User(
        id: 'u123',
        email: 'reader@example.com',
        displayName: 'Test Reader',
        authProvider: AuthProvider.google,
        role: UserRole.reader,
      ));

      final offlineService = OfflineReaderService();
      final downloadManager = DownloadManager(apiService: apiService, offlineService: offlineService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthController>.value(value: authController),
            Provider<ApiService>.value(value: apiService),
            Provider<OfflineReaderService>.value(value: offlineService),
            ChangeNotifierProvider<DownloadManager>.value(value: downloadManager),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify user information
      expect(find.text('Test Reader'), findsOneWidget);
      expect(find.text('reader@example.com'), findsOneWidget);
      expect(find.text('Conectado via Google'), findsOneWidget);

      // Verify mandatory delete button exists
      final deleteButton = find.text('Excluir Minha Conta Definitivamente');
      expect(deleteButton, findsOneWidget);

      // Tap delete button to trigger confirmation modal
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(find.text('Excluir Conta?'), findsOneWidget);
      expect(find.textContaining('Esta ação é permanente e irreversível'), findsOneWidget);

      // Confirm deletion in dialog
      final confirmDelete = find.widgetWithText(ElevatedButton, 'Sim, Excluir');
      expect(confirmDelete, findsOneWidget);
      await tester.tap(confirmDelete);
      await tester.pumpAndSettle();

      expect(deleteCalled, isTrue);
      expect(authController.isAuthenticated, isFalse);
    });
  });
}
