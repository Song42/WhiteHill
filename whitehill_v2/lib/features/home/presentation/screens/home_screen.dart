import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitehill_v2/core/player/player_provider.dart';
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
        ref.invalidate(songsProvider);
        // ignore errors — the provider's error state handles them
        await ref.read(songsProvider.future).then((_) {}, onError: (_) {});
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
                      if (songsAsync.isLoading)
                        const CircularProgressIndicator()
                      else
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
                  void openDetail(int initialPage) => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, _, _) => SongDetailScreen(
                            song: song,
                            initialPage: initialPage,
                          ),
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
                      );
                  final player = ref.watch(globalPlayerProvider);
                  final isCurrent = player.currentSong?.id == song.id;
                  return SongCard(
                    id: song.id,
                    title: song.title,
                    artist: song.artistName ?? '',
                    thumbnailUrl: song.coverUrl,
                    onTap: () => openDetail(0),
                    onLyricsTap: () => openDetail(1),
                    isPlaying: isCurrent && player.isPlaying,
                    onPlayTap: song.storagePath != null
                        ? () async {
                            final notifier =
                                ref.read(globalPlayerProvider.notifier);
                            try {
                              if (isCurrent) {
                                notifier.togglePlay();
                              } else {
                                await notifier.playSong(song);
                                notifier.play();
                              }
                            } on AudioPlaybackException catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context)
                                ..clearSnackBars()
                                ..showSnackBar(
                                    SnackBar(content: Text(e.message)));
                            } catch (_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context)
                                ..clearSnackBars()
                                ..showSnackBar(const SnackBar(
                                  content: Text('Failed to play audio.'),
                                ));
                            }
                          }
                        : null,
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
