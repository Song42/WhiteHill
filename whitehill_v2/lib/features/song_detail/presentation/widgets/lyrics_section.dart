import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/song_detail_provider.dart';

// ---------------------------------------------------------------------------
// ChordPro parser
// ---------------------------------------------------------------------------

class _Segment {
  final String chord;
  final String text;
  const _Segment(this.chord, this.text);
}

List<_Segment> _parseChordPro(String line) {
  final regex = RegExp(r'\[([A-Za-z0-9#/]+)\]');
  final segments = <_Segment>[];
  int lastEnd = 0;
  String currentChord = '';

  for (final match in regex.allMatches(line)) {
    final text = line.substring(lastEnd, match.start);
    segments.add(_Segment(currentChord, text));
    currentChord = match.group(1)!;
    lastEnd = match.end;
  }
  segments.add(_Segment(currentChord, line.substring(lastEnd)));

  return segments.where((s) => s.chord.isNotEmpty || s.text.isNotEmpty).toList();
}

// ---------------------------------------------------------------------------
// Mock lyrics (ChordPro format)
// ---------------------------------------------------------------------------

const _mockLyrics = '''
[G]주 나의 모든 것 [C]주 나의 전부
[Em]내 삶을 다스리는 [C]주 [D]여
[G]내 모든 것 드리리 [C]주께 영광
[Am]할렐루야 [D]주님 [G]께

[G]당신은 나의 [C]힘이요
[Em]당신은 나의 [Am]노래
[G]당신은 나의 [C]모든 것 [D]
[G]오 주님 [C]감사해 [G]

[G]사랑합니다 [C]주님을
[Em]경배합니다 [Am]주님을
[G]내 모든 것 [C]드리며 [D]
[G]주님만을 [C]찬양해 [G]
''';

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class LyricsSection extends ConsumerWidget {
  final VoidCallback onScrollToPlayer;

  const LyricsSection({super.key, required this.onScrollToPlayer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showChords = ref.watch(showChordsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          child: Row(
            children: [
              IconButton(
                onPressed: onScrollToPlayer,
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
                iconSize: 28,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
                tooltip: 'back to player',
              ),
              Text(
                'Lyrics',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              FilterChip(
                label: const Text('Chords'),
                selected: showChords,
                onSelected: (v) =>
                    ref.read(showChordsProvider.notifier).state = v,
                avatar: Icon(
                  Icons.music_note_rounded,
                  size: 16,
                  color: showChords
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Lyrics
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _mockLyrics.split('\n').map((line) {
                if (line.trim().isEmpty) return const SizedBox(height: 16);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _ChordLine(rawLine: line, showChords: showChords),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChordLine extends StatelessWidget {
  final String rawLine;
  final bool showChords;

  const _ChordLine({required this.rawLine, required this.showChords});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final segments = _parseChordPro(rawLine);

    final chordStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        );
    final lyricStyle = Theme.of(context).textTheme.bodyLarge;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: segments.map((seg) {
          return IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showChords)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      seg.chord.isNotEmpty ? seg.chord : ' ',
                      style: chordStyle,
                    ),
                  ),
                Text(seg.text, style: lyricStyle),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
