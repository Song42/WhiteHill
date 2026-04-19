import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:whitehill_v2/features/admin/presentation/providers/add_song_provider.dart';

class AddSongStep3 extends ConsumerWidget {
  const AddSongStep3({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addSongFormProvider);
    final notifier = ref.read(addSongFormProvider.notifier);

    final existingThumbnail = state.existingCoverFilename;
    final existingCoverUrl = state.existingCoverUrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Audio & Thumbnail',
            style: Theme.of(context).textTheme.titleLarge,
          ),
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
                      content: Text(
                        'File picker unavailable — try a full restart',
                      ),
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 16),
          _FilePickerTile(
            label: 'Album Thumbnail',
            icon: Icons.image_outlined,
            fileName: state.thumbnailFileName,
            statusMessage:
                existingThumbnail != null && state.thumbnailFileName != null
                ? 'The existing cover for this album will be updated'
                : existingThumbnail != null
                ? 'The existing cover for this album will be applied automatically'
                : null,
            isStatusPositive: existingThumbnail != null,
            onPick: () async {
              try {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                );
                if (result == null || result.files.single.path == null) return;
                if (!context.mounted) return;

                final colorScheme = Theme.of(context).colorScheme;
                final cropped = await ImageCropper().cropImage(
                  sourcePath: result.files.single.path!,
                  aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
                  compressQuality: 85,
                  uiSettings: [
                    AndroidUiSettings(
                      toolbarTitle: 'Crop Album Cover',
                      toolbarColor: colorScheme.surface,
                      toolbarWidgetColor: colorScheme.onSurface,
                      activeControlsWidgetColor: colorScheme.primary,
                      lockAspectRatio: true,
                      hideBottomControls: false,
                    ),
                    IOSUiSettings(
                      title: 'Crop Album Cover',
                      aspectRatioLockEnabled: true,
                      resetAspectRatioEnabled: false,
                    ),
                  ],
                );
                if (cropped == null) return;

                notifier.pickThumbnail(
                  path: cropped.path,
                  name: result.files.single.name,
                );
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'File picker unavailable — try a full restart',
                      ),
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 24),
          if (existingCoverUrl != null) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  existingCoverUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const AspectRatio(
                          aspectRatio: 1,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                  errorBuilder: (_, _, _) => const AspectRatio(
                    aspectRatio: 1,
                    child: Center(child: Icon(Icons.broken_image, size: 48)),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilePickerTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? fileName;
  final String? statusMessage;
  final bool isStatusPositive;
  final VoidCallback onPick;

  const _FilePickerTile({
    required this.label,
    required this.icon,
    required this.fileName,
    required this.onPick,
    this.statusMessage,
    this.isStatusPositive = false,
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
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    isPicked ? fileName! : statusMessage ?? 'Not selected',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isPicked
                          ? colorScheme.primary
                          : statusMessage != null && isStatusPositive
                          ? Colors.green
                          : colorScheme.error,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
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
