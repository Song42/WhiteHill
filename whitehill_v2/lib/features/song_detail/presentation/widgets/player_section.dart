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
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
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
