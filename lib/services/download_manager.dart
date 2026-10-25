import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'offline_reader_service.dart';

class DownloadTask {
  final String slug;
  final String title;
  final int startChapter;
  final int endChapter;
  int currentChapter;
  int totalImages;
  int completedImages;
  bool isCancelled;
  String? errorMessage;

  DownloadTask({
    required this.slug,
    required this.title,
    required this.startChapter,
    required this.endChapter,
    this.currentChapter = 0,
    this.totalImages = 0,
    this.completedImages = 0,
    this.isCancelled = false,
    this.errorMessage,
  });

  double get progress {
    if (totalImages == 0) return 0.0;
    return (completedImages / totalImages).clamp(0.0, 1.0);
  }
}

class DownloadManager extends ChangeNotifier {
  final ApiService apiService;
  final OfflineReaderService offlineService;
  final http.Client? customClient;

  final Map<String, DownloadTask> _tasks = {};

  DownloadManager({
    required this.apiService,
    required this.offlineService,
    this.customClient,
  });

  http.Client get client => customClient ?? apiService.client;

  /// Mandated by ADR-0011: Offline downloads are retained indefinitely.
  /// No automatic TTL, LRU or background cache eviction is permitted.
  bool get hasAutoEviction => false;

  Map<String, DownloadTask> get tasks => Map.unmodifiable(_tasks);

  @visibleForTesting
  void addTaskForTesting(DownloadTask task) {
    _tasks[task.slug] = task;
    notifyListeners();
  }

  DownloadTask? getTask(String slug) => _tasks[slug];

  Future<void> startBatchDownload({
    required String slug,
    required String title,
    required int startChapter,
    required int endChapter,
    int? lastChapter,
  }) async {
    if (startChapter > endChapter) {
      throw ArgumentError('startChapter ($startChapter) cannot be greater than endChapter ($endChapter)');
    }

    if (lastChapter != null && endChapter > lastChapter) {
      throw ArgumentError(
        'endChapter ($endChapter) não pode exceder o teto do último capítulo lançado ($lastChapter)',
      );
    }

    if ((endChapter - startChapter + 1) > 50) {
      throw ArgumentError('Máximo de 50 capítulos por lote de download');
    }

    final task = DownloadTask(
      slug: slug,
      title: title,
      startChapter: startChapter,
      endChapter: endChapter,
      currentChapter: startChapter,
    );
    _tasks[slug] = task;
    notifyListeners();

    try {
      for (int ch = startChapter; ch <= endChapter; ch++) {
        if (task.isCancelled) break;
        task.currentChapter = ch;
        notifyListeners();

        final response = await apiService.getChapterImages(slug, ch);
        task.totalImages += response.images.length;
        notifyListeners();

        for (final img in response.images) {
          if (task.isCancelled) break;

          final imgRes = await client.get(Uri.parse(img.proxyUrl));
          if (imgRes.statusCode == 200) {
            await offlineService.saveChapterImage(
              slug,
              ch,
              img.index,
              imgRes.bodyBytes,
            );
          }
          task.completedImages++;
          notifyListeners();
        }
      }
    } catch (e) {
      task.errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    } finally {
      if (task.isCancelled) {
        _tasks.remove(slug);
        notifyListeners();
      }
    }
  }

  void cancelDownload(String slug) {
    final task = _tasks[slug];
    if (task != null) {
      task.isCancelled = true;
      notifyListeners();
    }
  }

  Future<int> getTotalDiskUsage() async {
    return await offlineService.getTotalDiskUsageBytes();
  }

  Future<void> deleteChapter(String slug, int chapter) async {
    await offlineService.deleteDownloadedChapter(slug, chapter);
    notifyListeners();
  }

  Future<void> deleteManhua(String slug) async {
    await offlineService.deleteDownloadedManhua(slug);
    notifyListeners();
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double dBytes = bytes.toDouble();
    while (dBytes >= 1024 && i < suffixes.length - 1) {
      dBytes /= 1024;
      i++;
    }
    return '${dBytes.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
