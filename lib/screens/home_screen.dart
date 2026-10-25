import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import 'library_screen.dart';
import 'catalog_screen.dart';
import 'rankings_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    LibraryScreen(),
    CatalogScreen(),
    RankingsScreen(),
    ProfileScreen(),
  ];

  final List<String> _titles = const [
    'Minha Biblioteca',
    'Catálogo Canônico',
    'Rankings Comunitários',
    'Meu Perfil',
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090D16),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu_book_rounded, color: Color(0xFF818CF8), size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              _titles[_currentIndex],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: const Color(0xFF0D1424),
        indicatorColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.collections_bookmark_outlined),
            selectedIcon: Icon(Icons.collections_bookmark, color: Color(0xFF818CF8)),
            label: 'Biblioteca',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore, color: Color(0xFF818CF8)),
            label: 'Catálogo',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard, color: Color(0xFF818CF8)),
            label: 'Rankings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF818CF8)),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
