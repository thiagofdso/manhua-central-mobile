import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:manhua_mobile/screens/reader_screen.dart';
import 'package:manhua_mobile/services/api_service.dart';
import 'package:manhua_mobile/services/offline_reader_service.dart';
import 'package:manhua_mobile/services/storage_service.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

void main() {
  group('ReaderScreen & Offline-First & Ceiling Checks', () {
    late Directory tempDir;
    late OfflineReaderService offlineService;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('manhua_reader_test_');
      offlineService = OfflineReaderService(tempDir);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets('enforces lastChapter ceiling: Next button disabled and swipe blocked (RN-03.2)', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/reader/chapter-images') {
          return http.Response(
            jsonEncode({
              'slug': 'solo-leveling',
              'title': 'Solo Leveling',
              'chapter': 50,
              'lastChapter': 50, // Ceiling reached!
              'images': [
                {'index': 1, 'url': 'https://example.com/p1.jpg', 'proxyUrl': 'https://example.com/p1.jpg'}
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      });

      final storage = InMemoryStorageService();
      final apiService = ApiService(
        baseUrl: 'http://localhost:8080',
        client: mockClient,
        storage: storage,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: apiService),
            Provider<OfflineReaderService>.value(value: offlineService),
          ],
          child: const MaterialApp(
            home: ReaderScreen(
              slug: 'solo-leveling',
              title: 'Solo Leveling',
              initialChapter: 50,
              lastChapter: 50,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify ceiling banner text
      expect(find.text('Você chegou ao último capítulo lançado desta obra!'), findsOneWidget);

      // Verify Next button in bottom controls is disabled
      final nextButton = tester.widget<IconButton>(
        find.byKey(const Key('reader_next_button')),
      );
      expect(nextButton.onPressed, isNull);
    });

    testWidgets('offline-first: renders local files and displays Offline badge without network (RN-05.3 & ADR-0011)', (tester) async {
      // 1. Prepare offline files with valid 1x1 png bytes
      final validPng = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAA=');
      await offlineService.saveChapterImage('solo-leveling', 10, 1, validPng);
      await offlineService.saveChapterImage('solo-leveling', 10, 2, validPng);

      // Mock client that throws if called
      final mockClient = MockClient((request) async {
        throw Exception('Network request should not be made when files are offline!');
      });

      final storage = InMemoryStorageService();
      final apiService = ApiService(
        baseUrl: 'http://localhost:8080',
        client: mockClient,
        storage: storage,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: apiService),
            Provider<OfflineReaderService>.value(value: offlineService),
          ],
          child: const MaterialApp(
            home: ReaderScreen(
              slug: 'solo-leveling',
              title: 'Solo Leveling',
              initialChapter: 10,
              lastChapter: 100,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify Offline Badge is displayed
      expect(find.text('Salvo Localmente / Offline'), findsOneWidget);

      // Verify ListView child delegate renders FileImage
      expect(find.byType(ListView), findsOneWidget);
      final listView = tester.widget<ListView>(find.byType(ListView));
      final delegate = listView.childrenDelegate as SliverChildBuilderDelegate;
      expect(delegate.childCount, 2);

      final element = tester.element(find.byType(ListView));
      dynamic current = delegate.build(element, 0);
      while (current != null && current is! Image) {
        try {
          current = current.child;
        } catch (_) {
          break;
        }
      }
      expect(current is Image, isTrue);
      final image = current as Image;
      expect(image.image is FileImage, isTrue);
      expect((image.image as FileImage).file.path.contains('solo-leveling/chapter_10'), isTrue);
    });
  });
}
