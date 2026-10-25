import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/manhua.dart';
import '../services/api_service.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<CanonicalManhua> _items = [];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog([String? query]) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiService>();
      final result = await api.getCatalog(query: query);
      if (mounted) {
        setState(() {
          _items = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar catálogo';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addToLibrary(CanonicalManhua manhua) async {
    try {
      final api = context.read<ApiService>();
      await api.addToLibrary(manhua.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${manhua.title} adicionado à biblioteca!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Obra já está na biblioteca ou erro ao adicionar'),
          backgroundColor: Colors.amber,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar por título, autor...',
                  hintStyle: const TextStyle(color: Color(0xFF64748B)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Color(0xFF64748B), size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _loadCatalog();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF131B2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF1E293B)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF1E293B)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF6366F1)),
                  ),
                ),
                onSubmitted: (q) => _loadCatalog(q.trim()),
              ),
            ),

            // Grid Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => _loadCatalog(),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                                child: const Text('Tentar novamente', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        )
                      : _items.isEmpty
                          ? const Center(
                              child: Text(
                                'Nenhuma obra encontrada',
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(16.0),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.65,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: _items.length,
                              itemBuilder: (context, index) {
                                final manhua = _items[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF131B2E),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF1E293B)),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Cover Image
                                      Expanded(
                                        child: manhua.coverUrl != null
                                            ? Image.network(
                                                manhua.coverUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => const Center(
                                                  child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF475569)),
                                                ),
                                              )
                                            : const Center(
                                                child: Icon(Icons.menu_book, color: Color(0xFF475569)),
                                              ),
                                      ),

                                      // Info Box
                                      Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              manhua.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '${manhua.bayesianRating.toStringAsFixed(2)} ★',
                                                  style: const TextStyle(
                                                    color: Color(0xFFF59E0B),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  manhua.lastChapter != null
                                                      ? 'Cap. ${manhua.lastChapter}'
                                                      : '',
                                                  style: const TextStyle(
                                                    color: Color(0xFF64748B),
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),

                                            // + Biblioteca button
                                            ElevatedButton(
                                              onPressed: () => _addToLibrary(manhua),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF6366F1),
                                                foregroundColor: Colors.white,
                                                minimumSize: const Size.fromHeight(32),
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: const Text(
                                                '+ Biblioteca',
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
