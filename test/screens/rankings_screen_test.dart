import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:manhua_mobile/screens/rankings_screen.dart';
import 'package:manhua_mobile/services/api_service.dart';
import 'package:manhua_mobile/services/storage_service.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  testWidgets('RankingsScreen renders tabs and leaderboard cards', (tester) async {
    final mockClient = MockClient((request) async {
      if (request.url.path == '/api/rankings') {
        return http.Response(
          jsonEncode([
            {
              'rank': 1,
              'score': 4.95,
              'canonical': {
                'id': 1,
                'slug': 'solo-leveling',
                'title': 'Solo Leveling',
                'coverUrl': 'https://example.com/cover.jpg',
                'primaryDomain': 'asurascans.com',
                'urlTemplate': 'https://asurascans.com/{chapter}',
                'bayesianRating': 4.95,
                'totalVotes': 1500,
                'totalViews': 500000,
              }
            },
            {
              'rank': 2,
              'score': 4.80,
              'canonical': {
                'id': 2,
                'slug': 'omniscient-reader',
                'title': 'Omniscient Reader',
                'coverUrl': 'https://example.com/cover2.jpg',
                'primaryDomain': 'ravenscans.org',
                'urlTemplate': 'https://ravenscans.org/{chapter}',
                'bayesianRating': 4.80,
                'totalVotes': 850,
                'totalViews': 320000,
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
    final apiService = ApiService(
      baseUrl: 'http://localhost:8080',
      client: mockClient,
      storage: storage,
    );

    await tester.pumpWidget(
      Provider<ApiService>.value(
        value: apiService,
        child: const MaterialApp(
          home: RankingsScreen(),
        ),
      ),
    );

    // Initial loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    // Verify tabs
    expect(find.text('Melhor Votados'), findsOneWidget);
    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('Semana'), findsOneWidget);
    expect(find.text('Geral'), findsOneWidget);

    // Verify leaderboard items
    expect(find.text('Solo Leveling'), findsOneWidget);
    expect(find.text('Omniscient Reader'), findsOneWidget);
    expect(find.text('4.95 ★'), findsOneWidget);
  });
}
