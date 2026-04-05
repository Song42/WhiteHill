import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitehill_v2/features/admin/presentation/screens/admin_board_screen.dart';
import 'package:whitehill_v2/features/home/presentation/screens/home_screen.dart';
import 'package:whitehill_v2/features/library/presentation/screens/library_screen.dart';
import 'package:whitehill_v2/features/search/presentation/screens/search_screen.dart';

import '../player/mini_player_bar.dart';
import '../player/player_provider.dart';

final _navIndexProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _screens = [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    AdminBoardScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(_navIndexProvider);
    final hasCurrentSong = ref.watch(
      globalPlayerProvider.select((s) => s.hasCurrentSong),
    );

    return Scaffold(
      body: _screens[currentIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasCurrentSong) const MiniPlayerBar(),
          NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) =>
                ref.read(_navIndexProvider.notifier).state = index,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Icon(Icons.admin_panel_settings_outlined),
                selectedIcon: Icon(Icons.admin_panel_settings),
                label: 'Admin',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
