import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/player/player_provider.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../song_detail/presentation/screens/song_detail_screen.dart';
import '../../../songs/domain/entities/song.dart';
import '../../../songs/presentation/providers/songs_provider.dart';
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
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(librarySearchQueryProvider.notifier).state = value;
    });
    setState(() {});
  }

  void _clearSearch() {
    _searchController.clear();
    _debounce?.cancel();
    ref.read(librarySearchQueryProvider.notifier).state = '';
    setState(() {});
  }

  void _refresh() {
    ref.invalidate(recentAlbumsProvider);
    ref.invalidate(recentSongsProvider);
  }

  Future<void> _openSongDetail(String songId, {int initialPage = 0}) async {
    final song = await showDialog<Song>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SongLoadingDialog(songId: songId),
    );
    if (song == null || !mounted) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) =>
            SongDetailScreen(song: song, initialPage: initialPage),
        transitionsBuilder: (_, animation, _, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(librarySearchQueryProvider).trim();
    final isSearching = query.isNotEmpty;
    final theme = Theme.of(context);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          scrolledUnderElevation: 0,
          title: Text(
            'Library',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      onPressed: _clearSearch,
                    ),
                ],
                onChanged: _onSearchChanged,
              ),
            ),
          ),
        ),
        if (isSearching)
          ..._buildSearchResults(theme)
        else
          ..._buildBrowseView(theme),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Search results — flat list with Albums / Songs sections
  // ---------------------------------------------------------------------------

  List<Widget> _buildSearchResults(ThemeData theme) {
    final albumsAsync = ref.watch(searchAlbumsProvider);
    final songsAsync = ref.watch(searchSongsProvider);

    if (albumsAsync.isLoading && songsAsync.isLoading) {
      return [
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    final albums = albumsAsync.valueOrNull ?? [];
    final songs = songsAsync.valueOrNull ?? [];

    if (albumsAsync.hasError && songsAsync.hasError) {
      return [
        SliverFillRemaining(
          child: ErrorView(
            error: albumsAsync.error ?? songsAsync.error ?? 'Unknown error',
            onRetry: () {
              ref.invalidate(searchAlbumsProvider);
              ref.invalidate(searchSongsProvider);
            },
          ),
        ),
      ];
    }

    if (albums.isEmpty &&
        songs.isEmpty &&
        !albumsAsync.isLoading &&
        !songsAsync.isLoading) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Text(
              'No results found',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ];
    }

    return [
      // --- Albums ---
      if (albums.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Albums',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SliverList.builder(
          itemCount: albums.length,
          itemBuilder: (context, index) {
            final album = albums[index];
            return _SearchResultTile(
              title: album.title,
              subtitle: album.artistName,
              thumbnailUrl: album.coverUrl,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlbumDetailScreen(album: album),
                ),
              ),
            );
          },
        ),
      ],

      // --- Songs ---
      if (songs.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Songs',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SliverList.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            final player = ref.watch(globalPlayerProvider);
            final isCurrent = player.currentSong?.id == song.id;
            return _SearchResultTile(
              title: song.title,
              subtitle: song.artistName ?? '',
              thumbnailUrl: song.coverUrl,
              isPlaying: isCurrent && player.isPlaying,
              onPlayTap: song.storagePath == null
                  ? null
                  : () async {
                      final notifier = ref.read(globalPlayerProvider.notifier);
                      if (isCurrent) {
                        notifier.togglePlay();
                        return;
                      }
                      // Fetch full song to get audio_path, then play
                      final full = await ref.read(
                        songByIdProvider(song.id).future,
                      );
                      if (full.storagePath == null) return;
                      try {
                        await notifier.playSong(full);
                        notifier.play();
                      } on AudioPlaybackException catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context)
                          ..clearSnackBars()
                          ..showSnackBar(SnackBar(content: Text(e.message)));
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context)
                          ..clearSnackBars()
                          ..showSnackBar(
                            const SnackBar(
                              content: Text('Failed to play audio.'),
                            ),
                          );
                      }
                    },
              onTap: () => _openSongDetail(song.id),
            );
          },
        ),
      ],

      // bottom padding
      const SliverToBoxAdapter(child: SizedBox(height: 16)),
    ];
  }

  // ---------------------------------------------------------------------------
  // Browse view (no query) — unchanged from original
  // ---------------------------------------------------------------------------

  List<Widget> _buildBrowseView(ThemeData theme) {
    final albumsAsync = ref.watch(recentAlbumsProvider);
    final songsAsync = ref.watch(recentSongsProvider);

    if (albumsAsync.isLoading && songsAsync.isLoading) {
      return [
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    return [
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
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Recently Updated Albums',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
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
                                builder: (_) => AlbumDetailScreen(album: album),
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Recently Added',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0, 1),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeInOut,
                                  ),
                                ),
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
                              final notifier = ref.read(
                                globalPlayerProvider.notifier,
                              );
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
                                    SnackBar(content: Text(e.message)),
                                  );
                              } catch (_) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context)
                                  ..clearSnackBars()
                                  ..showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to play audio.'),
                                    ),
                                  );
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
    ];
  }
}

// -----------------------------------------------------------------------------
// Search result list tile — thumbnail, title, artist, play button
// -----------------------------------------------------------------------------

class _SearchResultTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? thumbnailUrl;
  final VoidCallback onTap;
  final VoidCallback? onPlayTap;
  final bool isPlaying;

  const _SearchResultTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.thumbnailUrl,
    this.onPlayTap,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 48,
          height: 48,
          child: thumbnailUrl != null
              ? CachedNetworkImage(
                  imageUrl: thumbnailUrl!,
                  fit: BoxFit.cover,
                  memCacheWidth: 144,
                  placeholder: (_, _) => _placeholder(colorScheme),
                  errorWidget: (_, _, _) => _placeholder(colorScheme),
                )
              : _placeholder(colorScheme),
        ),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      trailing: onPlayTap != null
          ? IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              onPressed: onPlayTap,
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _placeholder(ColorScheme colorScheme) {
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.music_note,
        color: colorScheme.onSurfaceVariant,
        size: 20,
      ),
    );
  }
}

/// Dialog that fetches full song data and returns it on completion.
class _SongLoadingDialog extends ConsumerWidget {
  final String songId;
  const _SongLoadingDialog({required this.songId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songAsync = ref.watch(songByIdProvider(songId));

    return songAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pop(null);
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(content: Text('Failed to load song: $e')));
        });
        return const SizedBox.shrink();
      },
      data: (song) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pop(song);
        });
        return const SizedBox.shrink();
      },
    );
  }
}
