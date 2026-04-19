import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitehill_v2/features/admin/presentation/providers/manage_songs_provider.dart';
import 'package:whitehill_v2/features/songs/domain/entities/song.dart';

class ManageSongsScreen extends ConsumerStatefulWidget {
  const ManageSongsScreen({super.key});

  @override
  ConsumerState<ManageSongsScreen> createState() => _ManageSongsScreenState();
}

class _ManageSongsScreenState extends ConsumerState<ManageSongsScreen> {
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Force a fresh fetch every time the screen opens.
    // Delay invalidation to avoid triggering rebuilds during initState.
    Future.microtask(() => ref.invalidate(songSummariesProvider));
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(manageSongsSelectionProvider.notifier).save();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Selections saved.')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildSongTile(Song song, Set<String> selectedIds) {
    final isSelected = selectedIds.contains(song.id);

    return CheckboxListTile(
      value: isSelected,
      onChanged: (_) =>
          ref.read(manageSongsSelectionProvider.notifier).toggle(song.id),
      secondary: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 56,
          height: 56,
          child: song.coverUrl != null
              ? Image.network(
                  song.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.music_note, size: 24),
                )
              : const Icon(Icons.music_note, size: 24),
        ),
      ),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (song.artistName != null)
            Text(
              song.artistName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          Text(
            [
              '${song.totalSelections} times',
              if (song.lastSelectedAt != null)
                _formatDate(song.lastSelectedAt!)
              else
                'Never',
            ].join(' · '),
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      isThreeLine: song.artistName != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(manageSongsFilterProvider);
    final filteredAsync = ref.watch(filteredManageSongsProvider);
    final selectedIds =
        ref.watch(manageSongsSelectionProvider).valueOrNull ?? {};
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Songs'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by title or artist',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) =>
                  ref.read(manageSongsSearchProvider.notifier).state = v,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Never Selected'),
                  selected: filter == ManageSongsFilter.neverSelected,
                  onSelected: (on) =>
                      ref.read(manageSongsFilterProvider.notifier).state = on
                      ? ManageSongsFilter.neverSelected
                      : ManageSongsFilter.none,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Recently Selected'),
                  selected: filter == ManageSongsFilter.recentlySelected,
                  onSelected: (on) =>
                      ref.read(manageSongsFilterProvider.notifier).state = on
                      ? ManageSongsFilter.recentlySelected
                      : ManageSongsFilter.none,
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load songs: $e')),
              data: (songs) {
                if (songs.isEmpty) {
                  return Center(
                    child: Text(
                      filter == ManageSongsFilter.none
                          ? 'Search or select a filter to view songs.'
                          : 'No songs found.',
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) =>
                      _buildSongTile(songs[index], selectedIds),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
