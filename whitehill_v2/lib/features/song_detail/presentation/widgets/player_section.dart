import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/song_detail_provider.dart';

class PlayerSection extends ConsumerStatefulWidget {
  final String title;
  final String artist;
  final String? thumbnailUrl;
  final VoidCallback onScrollToLyrics;

  const PlayerSection({
    super.key,
    required this.title,
    required this.artist,
    required this.onScrollToLyrics,
    this.thumbnailUrl,
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
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _translateAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _loopController, curve: Curves.easeIn),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _loopController, curve: Curves.easeIn),
    );
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
    final player = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final progress = player.duration.inMilliseconds > 0
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
                    child: widget.thumbnailUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(widget.thumbnailUrl!,
                                fit: BoxFit.cover),
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
                    text: widget.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  // Artist
                  Text(
                    widget.artist,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                  const SizedBox(height: 24),
                  // Seek bar
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 16),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: notifier.seek,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_fmt(player.position),
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(_fmt(player.duration),
                            style: Theme.of(context).textTheme.bodySmall),
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
                        onPressed: notifier.togglePlay,
                        child: Icon(
                          player.isPlaying
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
            milliseconds: (maxExtent * 25).clamp(2000, 8000).toInt()),
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
