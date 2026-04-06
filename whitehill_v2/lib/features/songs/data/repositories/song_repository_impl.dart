import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/song.dart';
import '../../domain/entities/song_exception.dart';
import '../../domain/repositories/song_repository.dart';
import '../models/song_model.dart';

const _songSelect =
    'id, title, lyrics_chord, youtube_url, audio_path, bpm, key, '
    'total_selections, last_selected_at, '
    'albums(title, cover_url, artists(name, image_url))';

const _kImageBucket = 'media';
const _kCacheFile = 'whitehill_cache/songs.json';

class SongRepositoryImpl implements SongRepository {
  final SupabaseClient _client;

  const SongRepositoryImpl(this._client);

  // ---------------------------------------------------------------------------
  // Cache helpers
  // ---------------------------------------------------------------------------

  Future<File> get _cacheFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_kCacheFile');
  }

  Future<void> _writeCache(List<SongModel> songs) async {
    final file = await _cacheFile;
    await file.parent.create(recursive: true);
    final json = songs.map((s) => s.toJson()).toList();
    await file.writeAsString(jsonEncode(json));
  }

  Future<List<Song>?> _readCache() async {
    final file = await _cacheFile;
    if (!await file.exists()) return null;
    final raw = await file.readAsString();
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map((e) => SongModel.fromCacheJson(e)).toList();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  @override
  Future<List<Song>> getSongs() async {
    try {
      final songs = await _fetchSongsFromRemote();
      // Update cache in the background — don't block the return.
      _writeCache(songs);
      return songs;
    } catch (e) {
      // If network fails, try to serve from cache.
      final cached = await _readCache();
      if (cached != null) return cached;
      // No cache either — rethrow the original error wrapped properly.
      if (e is SongException) rethrow;
      throw SongNetworkException('Offline and no cached data available.');
    }
  }

  @override
  Future<List<Song>> getSelectedSongs() => _guard(() async {
        final data = await _client
            .from('selected_songs')
            .select('song_id, songs($_songSelect)');
        return (data as List).map((e) {
          final songJson = e['songs'] as Map<String, dynamic>;
          return SongModel.fromJson(_resolveJson(songJson));
        }).toList();
      });

  @override
  Future<void> saveSelections({
    required Set<String> toAdd,
    required Set<String> toRemove,
    required Set<String> allSelected,
  }) => _guard(() async {
        // Remove deselected rows from selected_songs
        if (toRemove.isNotEmpty) {
          await _client
              .from('selected_songs')
              .delete()
              .inFilter('song_id', toRemove.toList());
        }
        // Insert newly selected rows into selected_songs
        if (toAdd.isNotEmpty) {
          await _client.from('selected_songs').insert(
              toAdd.map((id) => {'song_id': id}).toList());
        }
        // Increment total_selections & last_selected_at for ALL selected songs
        for (final id in allSelected) {
          await _client.rpc('increment_song_selection', params: {'song_id': id});
        }
      });

  @override
  Future<List<Song>> getSongSummaries() => _guard(() async {
        const select =
            'id, title, total_selections, last_selected_at, '
            'albums(cover_url, artists(name))';
        final data = await _client
            .from('songs')
            .select(select)
            .order('title');
        return (data as List)
            .map((e) => SongModel.fromJson(_resolveJson(e)))
            .toList();
      });

  @override
  Future<Song> getSongById(String id) => _guard(() async {
        final data = await _client
            .from('songs')
            .select(_songSelect)
            .eq('id', id)
            .maybeSingle();

        if (data == null) throw const SongNotFoundException('Song not found.');
        return SongModel.fromJson(_resolveJson(data));
      });

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<List<SongModel>> _fetchSongsFromRemote() => _guard(() async {
        final data = await _client
            .from('songs')
            .select(_songSelect)
            .order('title');
        return (data as List)
            .map((e) => SongModel.fromJson(_resolveJson(e)))
            .toList();
      });

  /// Converts a storage path in `cover_url` to a public URL so that
  /// [CachedNetworkImage] can load the thumbnail directly.
  Map<String, dynamic> _resolveJson(Map<String, dynamic> json) {
    final album = json['albums'] as Map<String, dynamic>?;
    if (album == null) return json;
    final rawPath = album['cover_url'] as String?;
    if (rawPath == null || rawPath.startsWith('http')) return json;
    final publicUrl =
        _client.storage.from(_kImageBucket).getPublicUrl(rawPath);
    return {
      ...json,
      'albums': {...album, 'cover_url': publicUrl},
    };
  }

  /// Translates low-level exceptions into [SongException] subtypes.
  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on SongException {
      rethrow;
    } on PostgrestException catch (e) {
      throw SongDatabaseException('Database error: ${e.message}');
    } on SocketException {
      throw const SongNetworkException(
          'No internet connection. Please check your network.');
    } on AuthException catch (e) {
      throw SongDatabaseException('Auth error: ${e.message}');
    } catch (e) {
      throw SongDatabaseException('Unexpected error: $e');
    }
  }
}
