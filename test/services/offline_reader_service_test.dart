import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:manhua_mobile/services/offline_reader_service.dart';

void main() {
  test('offline service basic test', () async {
    final tempDir = await Directory.systemTemp.createTemp('offline_test_');
    final service = OfflineReaderService(tempDir);
    final file = await service.saveChapterImage('test', 1, 1, [1, 2, 3]);
    expect(await file.exists(), isTrue);
    expect(await service.isChapterDownloaded('test', 1), isTrue);
    await tempDir.delete(recursive: true);
  });
}
