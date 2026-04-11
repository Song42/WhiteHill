import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/player/audio_download_provider.dart';
import '../../../../core/player/player_provider.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../songs/domain/entities/song.dart';

class PlayerSection extends ConsumerStatefulWidget {
  final Song song;
  final VoidCallback onScrollToLyrics;

  const PlayerSection({
    super.key,
    required this.song,
    required this.onScrollToLyrics,
  });

  @override
  ConsumerState<PlayerSection> createState() => _PlayerSectionState();
}

class _PlayerSectionState extends ConsumerState<PlayerSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loopController;
  late final Animation<double> _translateAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final playerState = ref.read(globalPlayerProvider);
      // Only auto-load when the player is completely empty. If another song is
      // already loaded (even paused), leave it alone — the user must press play
      // to explicitly switch. This prevents wiping a paused song's position.
      if (playerState.hasCurrentSong) return;
      ref.read(globalPlayerProvider.notifier).playSong(widget.song).catchError((
        e,
      ) {
        if (!mounted) return;
        final message = e is AudioPlaybackException
            ? e.message
            : 'Failed to load audio.';
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(message)));
      });
    });
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _translateAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(parent: _loopController, curve: Curves.easeIn));
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _loopController, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _loopController.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(globalPlayerProvider);
    final notifier = ref.read(globalPlayerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    // Only reflect player state when this song is the one loaded in the player.
    final isCurrent = player.currentSong?.id == widget.song.id;
    final isThisLoading = isCurrent && player.isLoading;
    final isThisPlaying = isCurrent && player.isPlaying;
    final isOnline = ref.watch(isOnlineProvider);
    final hasNoAudio = widget.song.storagePath == null;
    final isSavedLocally =
        !hasNoAudio &&
        ref.watch(audioDownloadProvider(widget.song.storagePath!)).status ==
            DownloadStatus.downloaded;
    final canPlay = !hasNoAudio && (isOnline || isSavedLocally);
    final displayPosition = isCurrent ? player.position : Duration.zero;
    // Show pre-fetched local duration when song isn't loaded in the player yet.
    final localDuration = (!hasNoAudio && isSavedLocally && !isCurrent)
        ? ref
              .watch(localAudioDurationProvider(widget.song.storagePath!))
              .valueOrNull
        : null;
    final displayDuration = isCurrent
        ? player.duration
        : (localDuration ?? Duration.zero);
    final progress = isCurrent && player.duration.inMilliseconds > 0
        ? player.position.inMilliseconds / player.duration.inMilliseconds
        : 0.0;

    return Column(
      children: [
        // Album info + playback controls — vertically centered together
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Album cover
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: widget.song.coverUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CachedNetworkImage(
                              imageUrl: widget.song.coverUrl!,
                              fit: BoxFit.cover,
                              memCacheWidth: 840, // 280 logical * 3x
                              fadeInDuration: Duration.zero,
                              fadeOutDuration: Duration.zero,
                              placeholder: (_, _) => Icon(
                                Icons.music_note_rounded,
                                size: 88,
                                color: colorScheme.onPrimaryContainer,
                              ),
                              errorWidget: (_, _, _) => Icon(
                                Icons.music_note_rounded,
                                size: 88,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.music_note_rounded,
                            size: 88,
                            color: colorScheme.onPrimaryContainer,
                          ),
                  ),
                  const SizedBox(height: 28),
                  // Title
                  _AutoScrollText(
                    text: widget.song.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Artist
                  Text(
                    widget.song.artistName ?? '',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Seek bar
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: (isCurrent && !hasNoAudio)
                          ? notifier.seek
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fmt(displayPosition),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          _fmt(displayDuration),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Playback controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded),
                        iconSize: 36,
                        onPressed: () {},
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(16),
                        ),
                        onPressed: (isThisLoading || !canPlay)
                            ? null
                            : () async {
                                try {
                                  if (isCurrent) {
                                    notifier.togglePlay();
                                  } else {
                                    await notifier.playSong(widget.song);
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
                                        content: Text(
                                          'Failed to play audio. Check your connection or save the song for offline playback.',
                                        ),
                                      ),
                                    );
                                }
                              },
                        child: isThisLoading
                            ? const SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : !canPlay
                            ? Icon(
                                !isOnline
                                    ? Icons.cloud_off_rounded
                                    : Icons.music_off_rounded,
                                size: 32,
                              )
                            : Icon(
                                isThisPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 32,
                              ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        iconSize: 36,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Download button
                  if (!hasNoAudio) _DownloadButton(song: widget.song),
                ],
              ),
            ),
          ),
        ),

        // Scroll-to-lyrics button pinned at bottom
        GestureDetector(
          onTap: widget.onScrollToLyrics,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _loopController,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _translateAnimation.value),
                  child: Opacity(opacity: _fadeAnimation.value, child: child),
                ),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 28,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              Text(
                'lyrics',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _AutoScrollText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const _AutoScrollText({required this.text, this.style});

  @override
  State<_AutoScrollText> createState() => _AutoScrollTextState();
}

class _AutoScrollTextState extends State<_AutoScrollText> {
  final _scrollController = ScrollController();
  bool _isScrolling = false;
  bool _showLeftFade = false;
  bool _showRightFade = false;
  DateTime? _pauseUntil;
  bool _isUserInteracting = false;

  bool get _isAutoScrollPaused {
    final pauseUntil = _pauseUntil;
    if (_isUserInteracting) return true;
    if (pauseUntil == null) return false;
    return DateTime.now().isBefore(pauseUntil);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScrollChanged);
  }

  @override
  void didUpdateWidget(covariant _AutoScrollText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text && _scrollController.hasClients) {
      _scrollController.jumpTo(0);
      _pauseUntil = null;
      _isUserInteracting = false;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScrollChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScrollChanged() {
    if (!_scrollController.hasClients || !mounted) return;
    final position = _scrollController.position;
    final maxExtent = position.maxScrollExtent;
    final pixels = position.pixels;
    final nextShowLeftFade = pixels > 0.5;
    final nextShowRightFade = pixels < maxExtent - 0.5;
    if (nextShowLeftFade != _showLeftFade ||
        nextShowRightFade != _showRightFade) {
      setState(() {
        _showLeftFade = nextShowLeftFade;
        _showRightFade = nextShowRightFade;
      });
    }
  }

  void _pauseAutoScroll() {
    _pauseUntil = DateTime.now().add(const Duration(seconds: 2));
  }

  Future<void> _waitWhilePaused() async {
    while (mounted && _isAutoScrollPaused) {
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  void _startScrolling() {
    if (_isScrolling) return;
    _isScrolling = true;
    _scrollLoop();
  }

  Future<void> _scrollLoop() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) break;
      await _waitWhilePaused();
      if (!mounted) break;

      final maxExtent = _scrollController.hasClients
          ? _scrollController.position.maxScrollExtent
          : 0.0;
      if (maxExtent <= 0) break;

      await _scrollController.animateTo(
        maxExtent,
        duration: Duration(
          milliseconds: (maxExtent * 25).clamp(2000, 8000).toInt(),
        ),
        curve: Curves.linear,
      );
      if (!mounted) break;

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) break;
      await _waitWhilePaused();
      if (!mounted) break;

      _scrollController.jumpTo(0);
    }
    if (mounted) _isScrolling = false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = widget.style ?? DefaultTextStyle.of(context).style;
        final tp = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);

        final overflows = tp.width > constraints.maxWidth;

        if (!overflows) {
          return Text(
            widget.text,
            style: widget.style,
            textAlign: TextAlign.center,
            maxLines: 1,
          );
        }

        // No whitespace → no natural break point; force character wrapping.
        if (!widget.text.contains(' ')) {
          return Text(
            widget.text,
            style: widget.style,
            textAlign: TextAlign.center,
            softWrap: true,
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleScrollChanged();
          _startScrolling();
        });

        Widget child = NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification &&
                notification.dragDetails != null) {
              _isUserInteracting = true;
              _pauseAutoScroll();
            } else if (notification is ScrollUpdateNotification &&
                notification.dragDetails != null) {
              _pauseAutoScroll();
            } else if (notification is ScrollEndNotification) {
              _isUserInteracting = false;
              _pauseAutoScroll();
            }
            return false;
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Text(widget.text, style: widget.style, maxLines: 1),
          ),
        );

        if (!_showLeftFade && !_showRightFade) return child;

        final colors = <Color>[
          _showLeftFade ? Colors.transparent : Colors.white,
          Colors.white,
          Colors.white,
          _showRightFade ? Colors.transparent : Colors.white,
        ];

        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            stops: const [0.0, 0.08, 0.92, 1.0],
            colors: colors,
          ).createShader(bounds),
          blendMode: BlendMode.dstIn,
          child: child,
        );
      },
    );
  }
}

class _DownloadButton extends ConsumerWidget {
  final Song song;

  const _DownloadButton({required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dlState = ref.watch(audioDownloadProvider(song.storagePath!));
    final isOnline = ref.watch(isOnlineProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final isSaved = dlState.status == DownloadStatus.downloaded;

    final (
      IconData icon,
      String label,
      bool enabled,
    ) = switch (dlState.status) {
      DownloadStatus.idle => (
        Icons.download_rounded,
        isOnline ? 'Save' : 'Save (Offline)',
        isOnline,
      ),
      DownloadStatus.downloading => (
        Icons.downloading_rounded,
        'Saving...',
        false,
      ),
      DownloadStatus.downloaded => (
        Icons.delete_outline_rounded,
        'Saved',
        true,
      ),
      DownloadStatus.error => (Icons.error_outline_rounded, 'Retry', isOnline),
    };

    return TextButton.icon(
      onPressed: enabled
          ? () async {
              if (isSaved) {
                await ref
                    .read(audioDownloadProvider(song.storagePath!).notifier)
                    .delete(song.storagePath!);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    const SnackBar(content: Text('Offline audio removed')),
                  );
                return;
              }
              await ref
                  .read(audioDownloadProvider(song.storagePath!).notifier)
                  .download(song.storagePath!);
              if (!context.mounted) return;
              final newState = ref.read(
                audioDownloadProvider(song.storagePath!),
              );
              if (newState.status == DownloadStatus.downloaded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Audio saved for offline playback'),
                  ),
                );
              } else if (newState.status == DownloadStatus.error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Download failed: ${newState.error}')),
                );
              }
            }
          : null,
      icon: dlState.status == DownloadStatus.downloading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            )
          : Icon(icon, size: 20),
      label: Text(label),
    );
  }
}
