import 'dart:math' as math;

import 'package:flutter/material.dart';

class VinylRecord extends StatefulWidget {
  final String? coverUrl;
  final bool isPlaying;
  final double size;

  const VinylRecord({
    super.key,
    required this.coverUrl,
    required this.isPlaying,
    this.size = 280,
  });

  @override
  State<VinylRecord> createState() => _VinylRecordState();
}

class _VinylRecordState extends State<VinylRecord>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 32),
    );
    if (widget.isPlaying) _spinController.repeat();
  }

  @override
  void didUpdateWidget(covariant VinylRecord oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _spinController.repeat();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _spinController.stop();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = widget.size;
    final coverSize = size * 0.58;

    return AnimatedBuilder(
      animation: _spinController,
      builder: (context, child) => Transform.rotate(
        angle: _spinController.value * 2 * math.pi,
        child: child,
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Vinyl disc
            CustomPaint(
              size: Size(size, size),
              painter: _VinylPainter(colorScheme: colorScheme),
            ),
            // Album cover (circular, clipped)
            Container(
              width: coverSize,
              height: coverSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primaryContainer,
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: widget.coverUrl != null
                  ? ClipOval(
                      child: Image.network(
                        widget.coverUrl!,
                        fit: BoxFit.cover,
                        cacheWidth: 840,
                        loadingBuilder: (_, child, progress) =>
                            progress == null
                                ? child
                                : Icon(
                                    Icons.music_note_rounded,
                                    size: coverSize * 0.4,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                        errorBuilder: (_, _, _) => Icon(
                          Icons.music_note_rounded,
                          size: coverSize * 0.4,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.music_note_rounded,
                      size: coverSize * 0.4,
                      color: colorScheme.onPrimaryContainer,
                    ),
            ),
            // Center ring (low opacity)
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A1A1A).withValues(alpha: 0.35),
              ),
            ),
            // Center hole (transparent to show background)
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VinylPainter extends CustomPainter {
  final ColorScheme colorScheme;

  _VinylPainter({required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Base disc with center hole cut out
    final discPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    final holePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: 9));
    final basePath = Path.combine(PathOperation.difference, discPath, holePath);
    final basePaint = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawPath(basePath, basePaint);

    // Grooves — concentric rings with alternating subtle sheen
    final groovePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Inner groove area: from center hole edge to cover edge,
    // and outer groove area: from cover edge to disc edge.
    final coverRadius = radius * 0.64;
    final holeRadius = 32.0;

    // Inner grooves (between hole and cover)
    for (double r = holeRadius + 3; r < coverRadius - 2; r += 2.5) {
      final t = (r - holeRadius) / (coverRadius - holeRadius);
      groovePaint.color = Color.lerp(
        const Color(0xFF2A2A2A),
        const Color(0xFF383838),
        (math.sin(t * math.pi * 6) + 1) / 2,
      )!;
      canvas.drawCircle(center, r, groovePaint);
    }

    // Outer grooves (between cover and disc edge)
    for (double r = coverRadius + 4; r < radius - 2; r += 2.0) {
      final t = (r - coverRadius) / (radius - coverRadius);
      groovePaint.color = Color.lerp(
        const Color(0xFF2A2A2A),
        const Color(0xFF3C3C3C),
        (math.sin(t * math.pi * 8) + 1) / 2,
      )!;
      canvas.drawCircle(center, r, groovePaint);
    }

    // Subtle highlight arc for realism
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.25
      ..shader = SweepGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.06),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.15, 0.3],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.72));
    canvas.drawCircle(center, radius * 0.72, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _VinylPainter oldDelegate) => false;
}
