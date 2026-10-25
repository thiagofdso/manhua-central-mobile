import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/library_item.dart';
import '../services/api_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isLoading = true;
  String? _error;
  List<UserLibrary> _items = [];

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiService>();
      final list = await api.getLibrary();
      if (mounted) {
        setState(() {
          _items = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar biblioteca';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite(UserLibrary item) async {
    final newFav = !item.isFavorite;
    // Optimistic local update
    setState(() {
      _items = _items.map((i) {
        if (i.id == item.id) {
          return UserLibrary(
            id: i.id,
            userId: i.userId,
            canonicalManhuaId: i.canonicalManhuaId,
            currentChapter: i.currentChapter,
            isFavorite: newFav,
            customOrder: i.customOrder,
            updatedAt: i.updatedAt,
            canonicalManhua: i.canonicalManhua,
          );
        }
        return i;
      }).toList();
    });

    try {
      final api = context.read<ApiService>();
      await api.toggleFavorite(item.id, newFav);
      _loadLibrary();
    } catch (_) {
      _loadLibrary();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF090D16),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF090D16),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadLibrary,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                child: const Text('Tentar novamente', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    // RN-04: Segregar rigorosamente favoritos no topo
    final favorites = _items.where((item) => item.isFavorite).toList();
    final regulars = _items.where((item) => !item.isFavorite).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: RefreshIndicator(
        onRefresh: _loadLibrary,
        color: const Color(0xFF6366F1),
        backgroundColor: const Color(0xFF131B2E),
        child: _items.isEmpty
            ? const Center(
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.collections_bookmark_outlined, size: 64, color: Color(0xFF334155)),
                      SizedBox(height: 12),
                      Text(
                        'Sua biblioteca está vazia',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Adicione obras do catálogo para começar a ler',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                children: [
                  // Favorites Section
                  if (favorites.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0, top: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Favoritos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...favorites.map((item) => _buildLibraryCard(item, isFav: true)),
                    const SizedBox(height: 16),
                  ],

                  // Regular / Reading Section
                  if (regulars.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0, top: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.menu_book_rounded, color: Color(0xFF818CF8), size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Lendo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...regulars.map((item) => _buildLibraryCard(item, isFav: false)),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildLibraryCard(UserLibrary item, {required bool isFav}) {
    final title = item.canonicalManhua?.title ?? 'Manhua #${item.canonicalManhuaId}';
    final lastCh = item.canonicalManhua?.lastChapter;
    final coverUrl = item.canonicalManhua?.coverUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFav
              ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
              : const Color(0xFF1E293B),
        ),
      ),
      child: Row(
        children: [
          // Cover Thumbnail
          Container(
            width: 44,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF090D16),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: coverUrl != null
                ? Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(0xFF475569),
                      size: 20,
                    ),
                  )
                : const Icon(Icons.menu_book, color: Color(0xFF475569)),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    lastCh != null
                        ? 'Cap. ${item.currentChapter} / $lastCh'
                        : 'Cap. ${item.currentChapter}',
                    style: const TextStyle(
                      color: Color(0xFF818CF8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Favorite Toggle
          IconButton(
            icon: Icon(
              item.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: item.isFavorite ? const Color(0xFFF59E0B) : const Color(0xFF64748B),
              size: 24,
            ),
            onPressed: () => _toggleFavorite(item),
            tooltip: item.isFavorite ? 'Remover dos favoritos' : 'Favoritar',
          ),
        ],
      ),
    );
  }
}
