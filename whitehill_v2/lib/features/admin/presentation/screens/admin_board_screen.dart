import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitehill_v2/core/providers/connectivity_provider.dart';
import 'package:whitehill_v2/features/admin/presentation/screens/add_song_screen.dart';

class AdminBoardScreen extends ConsumerStatefulWidget {
  const AdminBoardScreen({super.key});

  @override
  ConsumerState<AdminBoardScreen> createState() => _AdminBoardScreenState();
}

class _AdminBoardScreenState extends ConsumerState<AdminBoardScreen> {
  DateTime _lastOfflineTap = DateTime(0);

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Admin Board',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                FilledButton.icon(
                  onPressed: () {
                    if (!isOnline) {
                      final now = DateTime.now();
                      if (now.difference(_lastOfflineTap).inSeconds < 2) return;
                      _lastOfflineTap = now;
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No internet connection. Adding songs requires network access.',
                            ),
                          ),
                        );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddSongScreen(),
                      ),
                    );
                  },
                  icon: Icon(isOnline ? Icons.add : Icons.cloud_off_rounded),
                  label: const Text('Add New Song'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.library_music_outlined),
                  label: const Text('Manage Songs'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
