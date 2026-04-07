import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitehill_v2/features/home/presentation/screens/home_screen.dart';
import 'package:whitehill_v2/features/library/presentation/screens/library_screen.dart';
import 'package:whitehill_v2/features/profile/presentation/screens/profile_screen.dart';

import '../player/mini_player_bar.dart';
import '../player/player_provider.dart';

final _navIndexProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _screens = [
    HomeScreen(),
    LibraryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(_navIndexProvider);
    final hasCurrentSong = ref.watch(
      globalPlayerProvider.select((s) => s.hasCurrentSong),
    );

    final safeIndex = currentIndex.clamp(0, _screens.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasCurrentSong) const MiniPlayerBar(),
          NavigationBar(
            selectedIndex: safeIndex,
            onDestinationSelected: (index) {
              ref.read(_navIndexProvider.notifier).state = index;
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outlined),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
