import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/player/audio_download_provider.dart';
import '../../../../core/player/player_provider.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../song_detail/presentation/screens/song_detail_screen.dart';
import '../../../songs/domain/entities/song.dart';
import '../../domain/entities/album.dart';
import '../providers/album_detail_provider.dart';

class AlbumDetailScreen extends ConsumerStatefulWidget {
  final Album album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
  final _titleKey = GlobalKey();
  bool _showTitleInAppBar = false;

  Album get album => widget.album;

  bool _onScrollNotification(ScrollNotification notification) {
    final keyContext = _titleKey.currentContext;
    if (keyContext == null) return false;
    final box = keyContext.findRenderObject() as RenderBox;
    final position = box.localToGlobal(Offset.zero);
    final appBarHeight = kToolbarHeight + MediaQuery.of(context).padding.top;
    final titleBottom = position.dy + box.size.height;
    final shouldShow = titleBottom < appBarHeight;
    if (shouldShow != _showTitleInAppBar) {
      setState(() => _showTitleInAppBar = shouldShow);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(albumSongsProvider(album.id));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // --- App bar with back button only ---
            SliverAppBar(
              pinned: true,
              centerTitle: true,
              backgroundColor: colorScheme.surface,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              title: AnimatedOpacity(
                opacity: _showTitleInAppBar ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  album.title.toUpperCase(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // --- Centered square cover ---
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: album.coverUrl != null
                            ? CachedNetworkImage(
                                imageUrl: album.coverUrl!,
                                fit: BoxFit.cover,
                                memCacheWidth: 900,
                                placeholder: (_, _) => ColoredBox(
                                  color: colorScheme.surfaceContainerHighest,
                                ),
                                errorWidget: (_, _, _) =>
                                    _coverPlaceholder(colorScheme),
                              )
                            : _coverPlaceholder(colorScheme),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // --- Album title + artist name ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.title,
                      key: _titleKey,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (album.artistName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        album.artistName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // --- Content below ---
            ...songsAsync.when(
              loading: () => [
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (e, _) => [
                SliverFillRemaining(
                  child: ErrorView(
                    error: e,
                    onRetry: () => ref.invalidate(albumSongsProvider(album.id)),
                  ),
                ),
              ],
              data: (songs) => [
                // Action buttons
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: _ActionButtons(album: album, songs: songs),
                  ),
                ),
                // Song list
                if (songs.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No songs in this album',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 96),
                    sliver: SliverList.builder(
                      itemCount: songs.length,
                      itemBuilder: (context, index) {
                        final song = songs[index];
                        return _SongTile(
                          song: song,
                          onTap: () => Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, _, _) =>
                                  SongDetailScreen(song: song),
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
                              transitionDuration: const Duration(
                                milliseconds: 400,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverPlaceholder(ColorScheme colorScheme) {
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.album_outlined,
          size: 80,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action buttons: Play All + Save All
// ---------------------------------------------------------------------------

class _ActionButtons extends ConsumerWidget {
  final Album album;
  final List<Song> songs;

  const _ActionButtons({required this.album, required this.songs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final playableSongs = songs.where((s) => s.storagePath != null).toList();
    final hasPlayable = playableSongs.isNotEmpty;

    // Check how many are already saved locally.
    int savedCount = 0;
    for (final s in playableSongs) {
      final dlState = ref.watch(audioDownloadProvider(s.storagePath!));
      if (dlState.status == DownloadStatus.downloaded) savedCount++;
    }
    final allSaved = hasPlayable && savedCount == playableSongs.length;
    final isSaving = playableSongs.any(
      (s) =>
          ref.watch(audioDownloadProvider(s.storagePath!)).status ==
          DownloadStatus.downloading,
    );

    return Row(
      children: [
        FilledButton.icon(
          onPressed: hasPlayable
              ? () async {
                  final notifier = ref.read(globalPlayerProvider.notifier);
                  try {
                    await notifier.playSong(playableSongs.first);
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
                        const SnackBar(content: Text('Failed to play audio.')),
                      );
                  }
                }
              : null,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Play All'),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: (hasPlayable && isOnline && !allSaved && !isSaving)
              ? () => _saveAll(context, ref, playableSongs)
              : null,
          icon: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  allSaved
                      ? Icons.download_done_rounded
                      : Icons.download_rounded,
                ),
          label: Text(
            allSaved
                ? 'All Saved'
                : isSaving
                ? 'Saving...'
                : 'Save All',
          ),
        ),
      ],
    );
  }

  Future<void> _saveAll(
    BuildContext context,
    WidgetRef ref,
    List<Song> playableSongs,
  ) async {
    int successCount = 0;
    for (final s in playableSongs) {
      final dlState = ref.read(audioDownloadProvider(s.storagePath!));
      if (dlState.status == DownloadStatus.downloaded) continue;
      await ref
          .read(audioDownloadProvider(s.storagePath!).notifier)
          .download(s.storagePath!);
      final newState = ref.read(audioDownloadProvider(s.storagePath!));
      if (newState.status == DownloadStatus.downloaded) successCount++;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text('Saved $successCount song(s) for offline')),
      );
  }
}

// ---------------------------------------------------------------------------
// Song tile — no thumbnail, no album name
// ---------------------------------------------------------------------------

class _SongTile extends ConsumerWidget {
  final Song song;
  final VoidCallback onTap;

  const _SongTile({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final player = ref.watch(globalPlayerProvider);
    final isCurrent = player.currentSong?.id == song.id;
    final isPlaying = isCurrent && player.isPlaying;

    return ListTile(
      visualDensity: const VisualDensity(vertical: 2),
      leading: isPlaying
          ? Icon(Icons.equalizer_rounded, color: colorScheme.primary, size: 22)
          : null,
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: isCurrent
            ? theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              )
            : theme.textTheme.titleMedium,
      ),
      // subtitle: Text(
      //   song.key != null || song.bpm != null
      //       ? [
      //           if (song.key != null) 'Key: ${song.key}',
      //           if (song.bpm != null) 'BPM: ${song.bpm}',
      //         ].join('  ')
      //       : ' ',
      //   style: theme.textTheme.bodySmall?.copyWith(
      //     color: colorScheme.onSurfaceVariant,
      //   ),
      // ),
      trailing: song.storagePath == null
          ? null
          : _SongTrailingButton(song: song),
      onTap: onTap,
    );
  }
}

class _SongTrailingButton extends ConsumerWidget {
  final Song song;

  const _SongTrailingButton({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(globalPlayerProvider);
    final notifier = ref.read(globalPlayerProvider.notifier);
    final isCurrent = player.currentSong?.id == song.id;
    final isPlaying = isCurrent && player.isPlaying;
    final isLoading = isCurrent && player.isLoading;

    return IconButton(
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
      onPressed: isLoading
          ? null
          : () async {
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
                  ..showSnackBar(SnackBar(content: Text(e.message)));
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    const SnackBar(content: Text('Failed to play audio.')),
                  );
              }
            },
    );
  }
}
