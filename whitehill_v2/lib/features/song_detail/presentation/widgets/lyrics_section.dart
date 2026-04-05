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

/// Splits segment texts at spaces so every word boundary coincides with a
/// segment boundary. The chord is kept on the first sub-segment only.
List<_Segment> _splitOnSpaces(List<_Segment> segments) {
  final result = <_Segment>[];
  for (final seg in segments) {
    if (!seg.text.contains(' ')) {
      result.add(seg);
      continue;
    }
    final parts = seg.text.split(' ');
    for (int i = 0; i < parts.length; i++) {
      final isLast = i == parts.length - 1;
      final text = isLast ? parts[i] : '${parts[i]} ';
      if (text.isEmpty) continue;
      result.add(_Segment(i == 0 ? seg.chord : '', text));
    }
  }
  return result.where((s) => s.text.isNotEmpty).toList();
}

/// Groups segments into word groups. A group ends when its last segment's
/// text has a trailing space (= word boundary).
List<List<_Segment>> _groupByWord(List<_Segment> segments) {
  final groups = <List<_Segment>>[];
  var current = <_Segment>[];
  for (final seg in segments) {
    current.add(seg);
    if (seg.text.endsWith(' ')) {
      groups.add(List.from(current));
      current = [];
    }
  }
  if (current.isNotEmpty) groups.add(List.from(current));
  return groups;
}

double _measureGroup(List<_Segment> group, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: group.map((s) => s.text).join(), style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width;
}

/// Returns the word-group index at which to split for a ~50/50 layout.
/// Returns null when the content fits without splitting.
int? _halfSplitIndex(
  List<List<_Segment>> groups,
  TextStyle style,
  double maxWidth,
) {
  if (groups.length <= 1) return null;
  final widths = groups.map((g) => _measureGroup(g, style)).toList();
  final total = widths.fold(0.0, (s, w) => s + w);
  if (total <= maxWidth) return null;

  final half = total / 2;
  double cum = 0;
  for (int i = 0; i < widths.length - 1; i++) {
    final prev = cum;
    cum += widths[i];
    if (cum >= half) {
      final idx = (half - prev).abs() < (cum - half).abs() ? i : i + 1;
      return idx.clamp(1, groups.length - 1);
    }
  }
  return (groups.length / 2).ceil().clamp(1, groups.length - 1);
}

/// Recursively splits [groups] into lines that each fit within [maxWidth],
/// balancing each split at ~50% of the remaining content width.
List<List<List<_Segment>>> _splitToFit(
  List<List<_Segment>> groups,
  TextStyle style,
  double maxWidth,
) {
  final idx = _halfSplitIndex(groups, style, maxWidth);
  if (idx == null) return [groups];
  return [
    ..._splitToFit(groups.sublist(0, idx), style, maxWidth),
    ..._splitToFit(groups.sublist(idx), style, maxWidth),
  ];
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class LyricsSection extends ConsumerWidget {
  final String? lyricsChord;
  final VoidCallback onScrollToPlayer;

  const LyricsSection({
    super.key,
    required this.lyricsChord,
    required this.onScrollToPlayer,
  });

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
          child: lyricsChord == null || lyricsChord!.isEmpty
              ? Center(
                  child: Text(
                    'No lyrics available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: lyricsChord!.split('\n').map((line) {
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
    final wordGroups = _groupByWord(_splitOnSpaces(_parseChordPro(rawLine)));

    final chordStyle = Theme.of(context).textTheme.labelSmall!.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        );
    final lyricStyle = Theme.of(context).textTheme.bodyLarge!;

    Row buildRow(List<List<_Segment>> groups) => Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: groups
              .expand((g) => g)
              .map((seg) => IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showChords)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              seg.chord.isNotEmpty ? seg.chord : ' ',
                              style: chordStyle,
                            ),
                          ),
                        Text(seg.text, style: lyricStyle),
                      ],
                    ),
                  ))
              .toList(),
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final lines = _splitToFit(wordGroups, lyricStyle, constraints.maxWidth);
        if (lines.length == 1) return buildRow(lines.first);

        final gap = showChords ? 18.0 : 6.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < lines.length; i++) ...[
              buildRow(lines[i]),
              if (i < lines.length - 1) SizedBox(height: gap),
            ],
          ],
        );
      },
    );
  }
}
