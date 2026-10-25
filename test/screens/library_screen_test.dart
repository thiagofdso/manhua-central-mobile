import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:manhua_mobile/screens/library_screen.dart';
import 'package:manhua_mobile/services/api_service.dart';
import 'package:manhua_mobile/services/storage_service.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  testWidgets('LibraryScreen renders favorites at top and regular items below (RN-04)', (tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path == '/api/library') {
        return http.Response(
          jsonEncode([
            {
              'id': 'lib-fav-1',
              'userId': 'u1',
              'canonicalManhuaId': 1,
              'currentChapter': 25,
              'isFavorite': true,
              'customOrder': 0,
              'updatedAt': 1729700000,
              'canonicalManhua': {
                'id': 1,
                'slug': 'solo-leveling',
                'title': 'Solo Leveling (Favorito)',
                'lastChapter': 100,
                'primaryDomain': 'asurascans.com',
                'urlTemplate': 'https://asurascans.com/{chapter}',
              }
            },
            {
              'id': 'lib-reg-2',
              'userId': 'u1',
              'canonicalManhuaId': 2,
              'currentChapter': 10,
              'isFavorite': false,
              'customOrder': 1,
              'updatedAt': 1729700000,
              'canonicalManhua': {
                'id': 2,
                'slug': 'omniscient-reader',
                'title': 'Omniscient Reader (Lendo)',
                'lastChapter': 50,
                'primaryDomain': 'ravenscans.org',
                'urlTemplate': 'https://ravenscans.org/{chapter}',
              }
            }
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('[]', 200);
    });

    final storage = InMemoryStorageService();
    await storage.saveTokens(accessToken: 'token_mock', refreshToken: 'ref_mock');
    final apiService = ApiService(
      baseUrl: 'http://localhost:8080',
      client: mockClient,
      storage: storage,
    );

    await tester.pumpWidget(
      Provider<ApiService>.value(
        value: apiService,
        child: const MaterialApp(
          home: LibraryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify favorite section exists
    expect(find.text('Favoritos'), findsOneWidget);
    expect(find.text('Solo Leveling (Favorito)'), findsOneWidget);

    // Verify reading section exists
    expect(find.text('Lendo'), findsOneWidget);
    expect(find.text('Omniscient Reader (Lendo)'), findsOneWidget);

    // Verify current chapter progress display
    expect(find.text('Cap. 25 / 100'), findsOneWidget);
    expect(find.text('Cap. 10 / 50'), findsOneWidget);
  });
}
