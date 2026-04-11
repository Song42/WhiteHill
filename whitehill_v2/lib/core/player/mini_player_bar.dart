import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/song_detail/presentation/screens/song_detail_screen.dart';
import 'player_provider.dart';

class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(globalPlayerProvider);
    final notifier = ref.read(globalPlayerProvider.notifier);
    final song = player.currentSong;

    if (song == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final progress = player.duration.inMilliseconds > 0
        ? player.position.inMilliseconds / player.duration.inMilliseconds
        : 0.0;

    return Material(
      color: colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => SongDetailScreen(song: song),
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
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thin progress line at the top of the bar
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 2,
              backgroundColor: Colors.transparent,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Thumbnail
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: song.coverUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              imageUrl: song.coverUrl!,
                              fit: BoxFit.cover,
                              memCacheWidth: 120, // 40 logical * 3x
                              placeholder: (_, _) => Icon(
                                Icons.music_note_rounded,
                                size: 20,
                                color: colorScheme.onPrimaryContainer,
                              ),
                              errorWidget: (_, _, _) => Icon(
                                Icons.music_note_rounded,
                                size: 20,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.music_note_rounded,
                            size: 20,
                            color: colorScheme.onPrimaryContainer,
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Title & artist
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          song.title,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (song.artistName != null)
                          Text(
                            song.artistName!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Play / pause
                  IconButton(
                    icon: player.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onSurface,
                            ),
                          )
                        : Icon(
                            player.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                    onPressed: player.isLoading ? null : notifier.togglePlay,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
