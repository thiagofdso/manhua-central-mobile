import 'dart:async';
import 'api_service.dart';

class ChapterReleaseNotification {
  final String title;
  final String body;
  final String manhuaSlug;
  final int chapter;
  final DateTime receivedAt;

  ChapterReleaseNotification({
    required this.title,
    required this.body,
    required this.manhuaSlug,
    required this.chapter,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();
}

class FcmService {
  final ApiService apiService;
  final StreamController<ChapterReleaseNotification> _controller =
      StreamController<ChapterReleaseNotification>.broadcast();

  FcmService({required this.apiService});

  Stream<ChapterReleaseNotification> get onNotification => _controller.stream;

  static ChapterReleaseNotification parsePayload(Map<String, dynamic> payload) {
    final notification = payload['notification'] as Map<String, dynamic>? ?? {};
    final data = payload['data'] as Map<String, dynamic>? ?? {};

    final title = notification['title'] as String? ?? data['title'] as String? ?? 'Novo Capítulo';
    final body = notification['body'] as String? ?? 'Um novo capítulo foi disponibilizado!';
    final slug = data['manhuaSlug'] as String? ?? '';
    final chapterRaw = data['chapter'];
    final chapter = chapterRaw is int ? chapterRaw : int.tryParse(chapterRaw?.toString() ?? '1') ?? 1;

    return ChapterReleaseNotification(
      title: title,
      body: body,
      manhuaSlug: slug,
      chapter: chapter,
    );
  }

  void handleIncomingMessage(Map<String, dynamic> payload) {
    final notif = parsePayload(payload);
    _controller.add(notif);
  }

  Future<bool> registerDeviceToken(String token) async {
    try {
      await apiService.registerFcmToken(token);
      return true;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _controller.close();
  }
}
