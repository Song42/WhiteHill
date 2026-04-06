import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/player/player_provider.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../song_detail/presentation/screens/song_detail_screen.dart';
import '../../../home/presentation/widgets/song_card.dart';
import '../providers/library_provider.dart';
import '../widgets/album_card.dart';
import 'album_detail_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(recentAlbumsProvider);
    ref.invalidate(recentSongsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final albumsAsync = ref.watch(filteredAlbumsProvider);
    final songsAsync = ref.watch(filteredSongsProvider);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        _refresh();
        await Future.wait([
          ref.read(recentAlbumsProvider.future).then((_) {}, onError: (_) {}),
          ref.read(recentSongsProvider.future).then((_) {}, onError: (_) {}),
        ]);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            scrolledUnderElevation: 0,
            title: const Text(
              'Library',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search albums or songs',
                  leading: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.search),
                  ),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(librarySearchQueryProvider.notifier).state =
                              '';
                          setState(() {});
                        },
                      ),
                  ],
                  onChanged: (value) {
                  },
                ),
              ),
            ),
          ),

          // Single loading indicator when both sections are loading
          if (albumsAsync.isLoading && songsAsync.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[

          // --- Albums section ---
          albumsAsync.when(
            loading: () => const SliverToBoxAdapter(),
            error: (e, _) => SliverToBoxAdapter(
              child: ErrorView(error: e, onRetry: _refresh),
            ),
            data: (albums) {
              if (albums.isEmpty) return const SliverToBoxAdapter();
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Recently Updated Albums',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: albums.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final album = albums[index];
                            return SizedBox(
                              width: 140,
                              child: AlbumCard(
                                title: album.title,
                                artistName: album.artistName,
                                coverUrl: album.coverUrl,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AlbumDetailScreen(album: album),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // --- Recently Added songs section ---
          songsAsync.when(
            loading: () => const SliverToBoxAdapter(),
            error: (e, _) => SliverToBoxAdapter(
              child: ErrorView(error: e, onRetry: _refresh),
            ),
            data: (songs) {
              if (songs.isEmpty) return const SliverToBoxAdapter();
              return SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        'Recently Added',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 16),
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
                                transitionDuration:
                                    const Duration(milliseconds: 400),
                              ),
                            );
                        final player = ref.watch(globalPlayerProvider);
                        final isCurrent =
                            player.currentSong?.id == song.id;
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
                                  final notifier = ref.read(
                                      globalPlayerProvider.notifier);
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
                                      ..showSnackBar(SnackBar(
                                          content: Text(e.message)));
                                  } catch (_) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context)
                                      ..clearSnackBars()
                                      ..showSnackBar(const SnackBar(
                                        content:
                                            Text('Failed to play audio.'),
                                      ));
                                  }
                                }
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          ], // end ...[
        ],
      ),
    );
  }
}
