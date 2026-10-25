import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ranking.dart';
import '../services/api_service.dart';

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> {
  String _selectedTab = 'top_rated';
  bool _isLoading = true;
  String? _error;
  List<RankedManhua> _rankings = [];

  final List<Map<String, String>> _tabs = [
    {'id': 'top_rated', 'label': 'Melhor Votados'},
    {'id': 'views_daily', 'label': 'Hoje'},
    {'id': 'views_weekly', 'label': 'Semana'},
    {'id': 'views_all_time', 'label': 'Geral'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRankings();
  }

  Future<void> _loadRankings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = context.read<ApiService>();
      final items = await api.getRankings(_selectedTab);
      if (mounted) {
        setState(() {
          _rankings = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar rankings';
          _isLoading = false;
        });
      }
    }
  }

  void _onTabChanged(String tabId) {
    if (_selectedTab == tabId) return;
    setState(() => _selectedTab = tabId);
    _loadRankings();
  }

  Color _getRankBadgeColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFF59E0B); // Amber / Gold
      case 2:
        return const Color(0xFF94A3B8); // Silver / Slate
      case 3:
        return const Color(0xFFD97706); // Bronze
      default:
        return const Color(0xFF334155);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tabs Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _tabs.map((tab) {
                    final isSelected = _selectedTab == tab['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          tab['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) => _onTabChanged(tab['id']!),
                        selectedColor: const Color(0xFF6366F1),
                        backgroundColor: const Color(0xFF131B2E),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : const Color(0xFF1E293B),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Content
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
                                onPressed: _loadRankings,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                                child: const Text('Tentar novamente', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        )
                      : _rankings.isEmpty
                          ? const Center(
                              child: Text(
                                'Nenhuma obra no ranking ainda',
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: _rankings.length,
                              itemBuilder: (context, index) {
                                final item = _rankings[index];
                                final badgeColor = _getRankBadgeColor(item.rank);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12.0),
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF131B2E),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF1E293B)),
                                  ),
                                  child: Row(
                                    children: [
                                      // Rank Badge
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: badgeColor.withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: badgeColor, width: 1.5),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${item.rank}',
                                            style: TextStyle(
                                              color: badgeColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Cover Thumbnail
                                      Container(
                                        width: 44,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF090D16),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: item.canonical.coverUrl != null
                                            ? Image.network(
                                                item.canonical.coverUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => const Icon(
                                                  Icons.image_not_supported_outlined,
                                                  color: Color(0xFF475569),
                                                  size: 20,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.menu_book,
                                                color: Color(0xFF475569),
                                              ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.canonical.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.canonical.primaryDomain,
                                              style: const TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Score Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          _selectedTab == 'top_rated'
                                              ? '${item.score.toStringAsFixed(2)} ★'
                                              : '${item.score.toInt()} views',
                                          style: const TextStyle(
                                            color: Color(0xFF818CF8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
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
