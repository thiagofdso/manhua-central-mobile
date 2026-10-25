import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhua_mobile/services/api_service.dart';
import 'package:manhua_mobile/services/offline_reader_service.dart';
import 'package:manhua_mobile/services/download_manager.dart';
import 'package:manhua_mobile/services/storage_service.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

void main() {
  group('DownloadManager & Perpetual Retention (ADR-0011)', () {
    late Directory tempDir;
    late OfflineReaderService offlineService;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('manhua_download_test_');
      offlineService = OfflineReaderService(tempDir);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('validates lastChapter ceiling before downloading (RN-03.2)', () async {
      final mockClient = MockClient((request) async => http.Response('{}', 200));
      final apiService = ApiService(
        baseUrl: 'http://localhost:8080',
        client: mockClient,
        storage: InMemoryStorageService(),
      );

      final manager = DownloadManager(
        apiService: apiService,
        offlineService: offlineService,
      );

      expect(
        () => manager.startBatchDownload(
          slug: 'solo-leveling',
          title: 'Solo Leveling',
          startChapter: 1,
          endChapter: 20,
          lastChapter: 15,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('downloads chapter images and stores perpetually without auto-eviction (ADR-0011)', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/reader/chapter-images') {
          return http.Response(
            jsonEncode({
              'slug': 'solo-leveling',
              'title': 'Solo Leveling',
              'chapter': 1,
              'lastChapter': 10,
              'images': [
                {'index': 1, 'url': 'http://img/1.webp', 'proxyUrl': 'http://img/1.webp'},
                {'index': 2, 'url': 'http://img/2.webp', 'proxyUrl': 'http://img/2.webp'},
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.host == 'img') {
          // Return dummy image bytes
          return http.Response.bytes([1, 2, 3, 4], 200);
        }
        return http.Response('{}', 404);
      });

      final apiService = ApiService(
        baseUrl: 'http://localhost:8080',
        client: mockClient,
        storage: InMemoryStorageService(),
      );

      final manager = DownloadManager(
        apiService: apiService,
        offlineService: offlineService,
      );

      await manager.startBatchDownload(
        slug: 'solo-leveling',
        title: 'Solo Leveling',
        startChapter: 1,
        endChapter: 1,
        lastChapter: 10,
      );

      // Verify files exist in offline storage
      final isSaved = await offlineService.isChapterDownloaded('solo-leveling', 1);
      expect(isSaved, isTrue);

      final files = await offlineService.getLocalChapterImages('solo-leveling', 1);
      expect(files.length, 2);

      // Verify perpetual retention: no eviction timer or LRU exists
      expect(manager.hasAutoEviction, isFalse);

      // Verify disk usage is tracked
      final usageBytes = await manager.getTotalDiskUsage();
      expect(usageBytes, greaterThan(0));

      // Verify manual deletion
      await manager.deleteChapter('solo-leveling', 1);
      final isStillSaved = await offlineService.isChapterDownloaded('solo-leveling', 1);
      expect(isStillSaved, isFalse);
    });
  });
}
