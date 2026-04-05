import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitehill_v2/features/admin/presentation/providers/add_song_provider.dart';
class AddSongStep3 extends ConsumerWidget {
  const AddSongStep3({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addSongFormProvider);
    final notifier = ref.read(addSongFormProvider.notifier);

    // Already resolved when the user selected the album in step 1 — no extra request.
    final existingThumbnail = state.existingCoverFilename;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Audio & Thumbnail',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          _FilePickerTile(
            label: 'Audio File',
            icon: Icons.audio_file_outlined,
            fileName: state.audioFileName,
            onPick: () async {
              try {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.audio,
                );
                if (result != null && result.files.single.path != null) {
                  notifier.pickAudio(
                    path: result.files.single.path!,
                    name: result.files.single.name,
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File picker unavailable — try a full restart'),
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 16),
          _FilePickerTile(
            label: 'Thumbnail Image',
            icon: Icons.image_outlined,
            fileName: state.thumbnailFileName,
            hint: existingThumbnail != null
                ? '$existingThumbnail already exists — tap to replace'
                : null,
            onPick: () async {
              try {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                );
                if (result != null && result.files.single.path != null) {
                  notifier.pickThumbnail(
                    path: result.files.single.path!,
                    name: result.files.single.name,
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File picker unavailable — try a full restart'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _FilePickerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? fileName;
  final String? hint;
  final VoidCallback onPick;

  const _FilePickerTile({
    required this.label,
    required this.icon,
    required this.fileName,
    required this.onPick,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPicked = fileName != null;

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isPicked ? colorScheme.primary : colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isPicked
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isPicked
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    isPicked ? fileName! : (hint ?? 'Tap to select'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isPicked
                              ? colorScheme.primary
                              : hint != null
                                  ? colorScheme.tertiary
                                  : colorScheme.onSurfaceVariant,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
