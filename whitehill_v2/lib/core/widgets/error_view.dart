import 'package:flutter/material.dart';
import 'package:whitehill_v2/features/songs/domain/entities/song_exception.dart';

class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (icon, title, subtitle) = switch (error) {
      SongNetworkException e => (
          Icons.wifi_off_rounded,
          'No connection',
          e.message,
        ),
      SongDatabaseException e => (
          Icons.storage_rounded,
          'Database error',
          e.message,
        ),
      SongNotFoundException e => (
          Icons.search_off_rounded,
          'Not found',
          e.message,
        ),
      _ => (
          Icons.error_outline_rounded,
          'Something went wrong',
          error.toString(),
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
