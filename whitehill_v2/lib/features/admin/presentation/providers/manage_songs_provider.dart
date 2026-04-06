import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitehill_v2/features/songs/domain/entities/song.dart';
import 'package:whitehill_v2/features/songs/presentation/providers/songs_provider.dart';

enum ManageSongsFilter { none, neverSelected, recentlySelected }

/// Current filter selection.
final manageSongsFilterProvider =
    StateProvider.autoDispose<ManageSongsFilter>((_) => ManageSongsFilter.none);

/// Local search query.
final manageSongsSearchProvider = StateProvider.autoDispose<String>((_) => '');

/// Lightweight song summaries — fetched once on screen entry, never refetched.
/// Not autoDispose so filter/search changes don't trigger a new API call.
final songSummariesProvider = FutureProvider<List<Song>>((ref) {
  return ref.read(songRepositoryProvider).getSongSummaries();
});

/// Songs filtered by search query + active filter.
/// - No query & no filter → empty.
/// - Query only → search whole DB.
/// - Filter only → show that category.
/// - Both → search within filtered category.
final filteredManageSongsProvider =
    Provider.autoDispose<AsyncValue<List<Song>>>((ref) {
  final filter = ref.watch(manageSongsFilterProvider);
  final query = ref.watch(manageSongsSearchProvider).toLowerCase();

  if (filter == ManageSongsFilter.none && query.isEmpty) {
    return const AsyncData([]);
  }

  final songsAsync = ref.watch(songSummariesProvider);

  return songsAsync.whenData((songs) {
    var result = switch (filter) {
      ManageSongsFilter.neverSelected =>
        songs.where((s) => s.lastSelectedAt == null).toList(),
      ManageSongsFilter.recentlySelected => songs
          .where((s) => s.lastSelectedAt != null)
          .toList()
        ..sort((a, b) => b.lastSelectedAt!.compareTo(a.lastSelectedAt!)),
      ManageSongsFilter.none => songs.toList(),
    };

    if (query.isNotEmpty) {
      result = result
          .where((s) =>
              s.title.toLowerCase().contains(query) ||
              (s.artistName?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    return result;
  });
});

/// Tracks local selection state — initialised from DB, mutated locally,
/// persisted on explicit save.
final manageSongsSelectionProvider = AutoDisposeAsyncNotifierProvider<
    ManageSongsSelectionNotifier, Set<String>>(
  ManageSongsSelectionNotifier.new,
);

class ManageSongsSelectionNotifier
    extends AutoDisposeAsyncNotifier<Set<String>> {
  Set<String> _initial = {};

  @override
  Future<Set<String>> build() async {
    final selected = await ref.read(selectedSongsProvider.future);
    _initial = selected.map((s) => s.id).toSet();
    return {..._initial};
  }

  void toggle(String songId) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.contains(songId)
          ? ({...current}..remove(songId))
          : {...current, songId},
    );
  }

  bool get hasChanges {
    final current = state.valueOrNull;
    if (current == null) return false;
    return current.length != _initial.length ||
        !current.containsAll(_initial);
  }

  Future<void> save() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final toAdd = current.difference(_initial);
    final toRemove = _initial.difference(current);

    if (current.isEmpty && toRemove.isEmpty) return;

    final repo = ref.read(songRepositoryProvider);
    await repo.saveSelections(
      toAdd: toAdd,
      toRemove: toRemove,
      allSelected: current,
    );

    ref.invalidate(songsProvider);
    ref.invalidate(selectedSongsProvider);

    _initial = {...current};
  }
}
