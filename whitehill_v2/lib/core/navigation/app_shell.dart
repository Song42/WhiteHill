import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitehill_v2/features/admin/presentation/screens/admin_board_screen.dart';
import 'package:whitehill_v2/features/home/presentation/screens/home_screen.dart';
import 'package:whitehill_v2/features/library/presentation/screens/library_screen.dart';
import 'package:whitehill_v2/features/profile/presentation/screens/profile_screen.dart';

import '../player/mini_player_bar.dart';
import '../player/player_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';

final _navIndexProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(_navIndexProvider);
    final hasCurrentSong = ref.watch(
      globalPlayerProvider.select((s) => s.hasCurrentSong),
    );
    final isAdmin = ref.watch(isAdminProvider);

    final screens = [
      const HomeScreen(),
      const LibraryScreen(),
      if (isAdmin) const AdminBoardScreen() else const ProfileScreen(),
      const SizedBox.shrink(), // placeholder for logout tab
    ];

    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const NavigationDestination(
        icon: Icon(Icons.library_music_outlined),
        selectedIcon: Icon(Icons.library_music),
        label: 'Library',
      ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        )
      else
        const NavigationDestination(
          icon: Icon(Icons.person_outlined),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      // const NavigationDestination(
      //   icon: Icon(Icons.logout, color: Colors.red),
      //   label: 'Logout',
      // ),
    ];

    final safeIndex = currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasCurrentSong) const MiniPlayerBar(),
          NavigationBar(
            selectedIndex: safeIndex,
            onDestinationSelected: (index) {
              if (index == screens.length - 1) {
                ref.read(authStateProvider.notifier).signOut();
                return;
              }
              ref.read(_navIndexProvider.notifier).state = index;
            },
            destinations: destinations,
          ),
        ],
      ),
    );
  }
}
