import 'package:flutter/material.dart';

/// Album cover styled as a paper record sleeve.
/// Always fetches a fresh image from the server (no disk caching).
class AlbumCoverVinyl extends StatelessWidget {
  final String? coverUrl;
  final String title;
  final String artistName;
  final double sleeveSize;

  const AlbumCoverVinyl({
    super.key,
    required this.coverUrl,
    required this.title,
    required this.artistName,
    this.sleeveSize = 280,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: sleeveSize,
      height: sleeveSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Album cover image or placeholder
            if (coverUrl != null)
              Image.network(
                coverUrl!,
                fit: BoxFit.cover,
                cacheWidth: 900,
                loadingBuilder: (_, child, progress) =>
                    progress == null
                        ? child
                        : _SkeletonBox(
                            color: colorScheme.surfaceContainerHigh,
                          ),
                errorBuilder: (_, _, _) => _placeholder(colorScheme),
              )
            else
              _placeholder(colorScheme),
            // Subtle paper texture overlay
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.06),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.06),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// No cover URL at all — sidebar with title/artist.
  Widget _placeholder(ColorScheme colorScheme) {
    final sidebarWidth = sleeveSize * 0.22;
    return ColoredBox(
      color: colorScheme.surfaceContainerHigh,
      child: Row(
        children: [
          // Solid sidebar with rotated text
          Container(
            width: sidebarWidth,
            color: colorScheme.surfaceContainerHighest,
            child: RotatedBox(
              quarterTurns: 3,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: sleeveSize * 0.06),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: sleeveSize * 0.07,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: sleeveSize * 0.001),
                    Text(
                      artistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.6),
                        fontSize: sleeveSize * 0.045,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/// Animated shimmer skeleton shown while the cover image is loading.
class _SkeletonBox extends StatefulWidget {
  final Color color;

  const _SkeletonBox({required this.color});

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(1.0 + 2.0 * _controller.value, 0),
              colors: [
                widget.color,
                widget.color.withValues(alpha: 0.4),
                widget.color,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
