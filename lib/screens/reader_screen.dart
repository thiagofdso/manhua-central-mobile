import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reader.dart';
import '../services/api_service.dart';
import '../services/offline_reader_service.dart';

class ReaderScreen extends StatefulWidget {
  final String slug;
  final String title;
  final int initialChapter;
  final int? lastChapter;
  final String? libraryId;

  const ReaderScreen({
    super.key,
    required this.slug,
    required this.title,
    required this.initialChapter,
    this.lastChapter,
    this.libraryId,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late int _currentChapter;
  late int? _lastChapter;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isOffline = false;
  List<File> _localImages = [];
  List<ChapterImage> _networkImages = [];

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.initialChapter;
    _lastChapter = widget.lastChapter;
    _loadChapter(_currentChapter);
  }

  Future<void> _loadChapter(int chapter) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentChapter = chapter;
    });

    try {
      final offlineService = Provider.of<OfflineReaderService>(context, listen: false);
      final apiService = Provider.of<ApiService>(context, listen: false);
      final isDownloaded = await offlineService.isChapterDownloaded(widget.slug, chapter);

      if (isDownloaded) {
        final localFiles = await offlineService.getLocalChapterImages(widget.slug, chapter);
        if (mounted) {
          setState(() {
            _isOffline = true;
            _localImages = localFiles;
            _networkImages = [];
            _isLoading = false;
          });
        }
        _updateProgressSilently(chapter);
        return;
      }

      // Online fetch
      final response = await apiService.getChapterImages(widget.slug, chapter);

      if (mounted) {
        setState(() {
          _isOffline = false;
          _localImages = [];
          _networkImages = response.images;
          if (response.lastChapter != null) {
            _lastChapter = response.lastChapter;
          }
          _isLoading = false;
        });
      }

      _updateProgressSilently(chapter);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _updateProgressSilently(int chapter) {
    if (widget.libraryId == null) return;
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      apiService.updateProgress(widget.libraryId!, chapter).then((_) {}, onError: (_) {});
    } catch (_) {}
  }

  bool get _isCeilingReached =>
      _lastChapter != null && _currentChapter >= _lastChapter!;

  void _nextChapter() {
    if (_isCeilingReached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você chegou ao último capítulo lançado desta obra!'),
          backgroundColor: Color(0xFFEAB308),
        ),
      );
      return;
    }
    _loadChapter(_currentChapter + 1);
  }

  void _prevChapter() {
    if (_currentChapter <= 1) return;
    _loadChapter(_currentChapter - 1);
  }

  void _handleHorizontalSwipe(DragEndDetails details) {
    // Velocity > 0 means swiped left to right (Previous)
    // Velocity < 0 means swiped right to left (Next)
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -300) {
      // Swiping to next chapter
      if (_isCeilingReached) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Você chegou ao último capítulo lançado desta obra!'),
            backgroundColor: Color(0xFFEAB308),
          ),
        );
      } else {
        _nextChapter();
      }
    } else if (velocity > 300) {
      // Swiping to previous chapter
      if (_currentChapter > 1) {
        _prevChapter();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Capítulo $_currentChapter${_lastChapter != null ? ' de $_lastChapter' : ''}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          if (_isOffline)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF10B981)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.offline_pin, size: 14, color: Color(0xFF10B981)),
                  SizedBox(width: 4),
                  Text(
                    'Salvo Localmente / Offline',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: _handleHorizontalSwipe,
        child: Column(
          children: [
            if (_isCeilingReached)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: const Color(0xFFEAB308).withValues(alpha: 0.15),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFFEAB308), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Você chegou ao último capítulo lançado desta obra!',
                        style: TextStyle(
                          color: Color(0xFFFDE047),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _buildBody(),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadChapter(_currentChapter),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final itemCount = _isOffline ? _localImages.length : _networkImages.length;
    if (itemCount == 0) {
      return const Center(
        child: Text(
          'Nenhuma imagem encontrada para este capítulo.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
      );
    }

    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (_isOffline) {
          final file = _localImages[index];
          return Image.file(
            file,
            fit: BoxFit.fitWidth,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 200,
              color: const Color(0xFF1E293B),
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image, color: Colors.white54),
            ),
          );
        } else {
          final img = _networkImages[index];
          return Image.network(
            img.proxyUrl,
            fit: BoxFit.fitWidth,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 300,
                color: const Color(0xFF0F172A),
                alignment: Alignment.center,
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                      : null,
                  color: const Color(0xFF6366F1),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              height: 200,
              color: const Color(0xFF1E293B),
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image, color: Colors.white54),
            ),
          );
        }
      },
    );
  }

  Widget _buildBottomControls() {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              key: const Key('reader_prev_button'),
              icon: const Icon(Icons.skip_previous),
              color: Colors.white,
              disabledColor: Colors.white24,
              onPressed: _currentChapter > 1 ? _prevChapter : null,
              tooltip: 'Capítulo Anterior',
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Cap. $_currentChapter',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            IconButton(
              key: const Key('reader_next_button'),
              icon: const Icon(Icons.skip_next),
              color: Colors.white,
              disabledColor: Colors.white24,
              onPressed: _isCeilingReached ? null : _nextChapter,
              tooltip: 'Próximo Capítulo',
            ),
          ],
        ),
      ),
    );
  }
}
