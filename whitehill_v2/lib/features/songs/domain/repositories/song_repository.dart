import '../entities/song.dart';

abstract class SongRepository {
  Future<List<Song>> getSongs();
  Future<List<Song>> getSelectedSongs();
  Future<Song> getSongById(String id);

  /// Lightweight listing for manage-songs: only title, artist, thumbnail,
  /// total_selections, last_selected_at.
  Future<List<Song>> getSongSummaries();

  /// Batch-update selections.
  /// [toAdd] — song IDs being newly selected (insert into selected_songs).
  /// [toRemove] — song IDs being deselected (delete from selected_songs).
  /// [allSelected] — every song ID in the final selection (all get incremented).
  Future<void> saveSelections({
    required Set<String> toAdd,
    required Set<String> toRemove,
    required Set<String> allSelected,
  });
}
