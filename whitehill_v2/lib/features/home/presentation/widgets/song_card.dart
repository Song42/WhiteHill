import 'package:flutter/material.dart';

class SongCard extends StatelessWidget {
  final String id;
  final String title;
  final String artist;
  final String? thumbnailUrl;
  final VoidCallback onTap;

  const SongCard({
    super.key,
    required this.id,
    required this.title,
    required this.artist,
    this.thumbnailUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _Thumbnail(url: thumbnailUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      artist,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String? url;

  const _Thumbnail({this.url});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56,
        height: 56,
        child: url != null
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(colorScheme),
              )
            : _placeholder(colorScheme),
      ),
    );
  }

  Widget _placeholder(ColorScheme colorScheme) {
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant),
    );
  }
}
