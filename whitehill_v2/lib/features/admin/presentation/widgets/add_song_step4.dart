import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitehill_v2/features/admin/presentation/providers/add_song_provider.dart';

class AddSongStep4 extends ConsumerWidget {
  const AddSongStep4({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addSongFormProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preview & Confirm', style: textTheme.titleLarge),
          const SizedBox(height: 24),
          _PreviewCard(
            title: 'Song Info',
            children: [
              _PreviewRow(label: 'Title', value: state.title),
              _PreviewRow(label: 'Artist', value: state.artistName),
              if (state.albumTitle.isNotEmpty)
                _PreviewRow(label: 'Album', value: state.albumTitle),
              if (state.bpm.isNotEmpty)
                _PreviewRow(label: 'BPM', value: state.bpm),
              if (state.songKey.isNotEmpty)
                _PreviewRow(label: 'Key', value: state.songKey),
            ],
          ),
          const SizedBox(height: 12),
          _PreviewCard(
            title: 'Lyrics & Chords',
            children: [
              if (state.lyricsChord.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.lyricsChord,
                    style: textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                Text(
                  'No lyrics entered',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _PreviewCard(
            title: 'Files',
            children: [
              _PreviewRow(
                label: 'Audio',
                value: state.audioFileName ?? 'Not selected',
                isWarning: state.audioFileName == null,
              ),
              _PreviewRow(
                label: 'Thumbnail',
                value:
                    state.thumbnailFileName ??
                    (state.existingCoverFilename != null
                        ? 'The existing cover for this album will be applied automatically'
                        : 'Not selected'),
                isWarning:
                    state.thumbnailFileName == null &&
                    state.existingCoverFilename == null,
                isPositive:
                    state.thumbnailFileName == null &&
                    state.existingCoverFilename != null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _PreviewCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: colorScheme.primary),
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isWarning;
  final bool isPositive;

  const _PreviewRow({
    required this.label,
    required this.value,
    this.isWarning = false,
    this.isPositive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isWarning
                    ? colorScheme.error
                    : isPositive
                    ? Colors.green
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
