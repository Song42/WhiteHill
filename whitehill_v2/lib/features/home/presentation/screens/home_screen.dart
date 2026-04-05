import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitehill_v2/core/widgets/error_view.dart';
import 'package:whitehill_v2/features/home/presentation/widgets/song_card.dart';
import 'package:whitehill_v2/features/song_detail/presentation/screens/song_detail_screen.dart';
import 'package:whitehill_v2/features/songs/presentation/providers/songs_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(songsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        try {
          await ref.refresh(songsProvider.future);
        } catch (_) {
          // error state is shown via the provider, no need to rethrow
        }
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverAppBar(
            pinned: true,
            title: Text(
              'WhiteHill',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          songsAsync.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SliverFillRemaining(
            child: ErrorView(
              error: e,
              onRetry: () => ref.invalidate(songsProvider),
            ),
          ),
          data: (songs) {
            if (songs.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.library_music_outlined,
                        size: 56,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      const Text('No songs yet.'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => ref.invalidate(songsProvider),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              sliver: SliverList.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return SongCard(
                    id: song.id,
                    title: song.title,
                    artist: song.artistName ?? '',
                    thumbnailUrl: song.coverUrl,
                    onTap: () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, _, _) => SongDetailScreen(song: song),
                        transitionsBuilder: (_, animation, _, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 1),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOut,
                            )),
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 400),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        ],
      ),
    );
  }
}
