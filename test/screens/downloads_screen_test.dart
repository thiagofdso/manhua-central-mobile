import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:manhua_mobile/screens/downloads_screen.dart';
import 'package:manhua_mobile/services/api_service.dart';
import 'package:manhua_mobile/services/download_manager.dart';
import 'package:manhua_mobile/services/offline_reader_service.dart';
import 'package:manhua_mobile/services/storage_service.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

void main() {
  group('DownloadsScreen & Disk Management', () {
    late Directory tempDir;
    late OfflineReaderService offlineService;
    late DownloadManager downloadManager;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('manhua_downloads_screen_test_');
      offlineService = OfflineReaderService(tempDir);
      final apiService = ApiService(
        baseUrl: 'http://localhost:8080',
        client: MockClient((req) async => http.Response('{}', 200)),
        storage: InMemoryStorageService(),
      );
      downloadManager = DownloadManager(
        apiService: apiService,
        offlineService: offlineService,
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets('renders disk usage header and perpetual retention notice (ADR-0011)', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DownloadManager>.value(value: downloadManager),
            Provider<OfflineReaderService>.value(value: offlineService),
          ],
          child: const MaterialApp(
            home: DownloadsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Gerenciador de Downloads'), findsOneWidget);
      expect(find.textContaining('Retenção Perpétua'), findsOneWidget);
      expect(find.textContaining('Seus downloads não expiram'), findsOneWidget);
    });

    testWidgets('displays active download task with cancel button', (tester) async {
      final task = DownloadTask(
        slug: 'nano-machine',
        title: 'Nano Machine',
        startChapter: 1,
        endChapter: 10,
        currentChapter: 3,
        totalImages: 20,
        completedImages: 6,
      );
      downloadManager.addTaskForTesting(task);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DownloadManager>.value(value: downloadManager),
            Provider<OfflineReaderService>.value(value: offlineService),
          ],
          child: const MaterialApp(
            home: DownloadsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nano Machine'), findsOneWidget);
      expect(find.textContaining('Capítulo 3 / 10'), findsOneWidget);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);

      // Tap cancel
      await tester.tap(find.byIcon(Icons.cancel_outlined));
      await tester.pumpAndSettle();

      expect(task.isCancelled, isTrue);
    });
  });
}
