import 'dart:io';
import 'package:path_provider/path_provider.dart';

class OfflineReaderService {
  final Directory? _customBaseDir;

  OfflineReaderService([this._customBaseDir]);

  Future<Directory> _getBaseDir() async {
    if (_customBaseDir != null) return _customBaseDir;
    final appDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${appDir.path}/downloads');
    if (!downloadDir.existsSync()) {
      downloadDir.createSync(recursive: true);
    }
    return downloadDir;
  }

  Future<Directory> getChapterDir(String slug, int chapter) async {
    final base = await _getBaseDir();
    return Directory('${base.path}/$slug/chapter_$chapter');
  }

  Future<bool> isChapterDownloaded(String slug, int chapter) async {
    final dir = await getChapterDir(slug, chapter);
    if (!dir.existsSync()) return false;
    final files = dir.listSync().whereType<File>().toList();
    return files.isNotEmpty;
  }

  Future<List<File>> getLocalChapterImages(String slug, int chapter) async {
    final dir = await getChapterDir(slug, chapter);
    if (!dir.existsSync()) return [];
    final files = dir.listSync().whereType<File>().toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  Future<File> saveChapterImage(String slug, int chapter, int index, List<int> bytes) async {
    final dir = await getChapterDir(slug, chapter);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final file = File('${dir.path}/page_${index.toString().padLeft(4, '0')}.webp');
    file.writeAsBytesSync(bytes);
    return file;
  }

  Future<void> deleteDownloadedChapter(String slug, int chapter) async {
    final dir = await getChapterDir(slug, chapter);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }

  Future<void> deleteDownloadedManhua(String slug) async {
    final base = await _getBaseDir();
    final dir = Directory('${base.path}/$slug');
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }

  Future<List<String>> getDownloadedManhuaSlugs() async {
    final base = await _getBaseDir();
    if (!base.existsSync()) return [];
    final dirs = base.listSync().whereType<Directory>().toList();
    return dirs.map((d) => d.uri.pathSegments.reversed.elementAt(1)).toList();
  }

  Future<int> getTotalDiskUsageBytes() async {
    final base = await _getBaseDir();
    if (!base.existsSync()) return 0;
    int total = 0;
    try {
      final entities = base.listSync(recursive: true);
      for (final e in entities) {
        if (e is File) {
          total += e.lengthSync();
        }
      }
    } catch (_) {}
    return total;
  }
}
