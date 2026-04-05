import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/song.dart';
import '../../domain/entities/song_exception.dart';
import '../../domain/repositories/song_repository.dart';
import '../models/song_model.dart';

const _songSelect =
    'id, title, lyrics_chord, youtube_url, audio_path, bpm, key, '
    'albums(title, cover_url, artists(name, image_url))';

const _kImageBucket = 'media';

class SongRepositoryImpl implements SongRepository {
  final SupabaseClient _client;

  const SongRepositoryImpl(this._client);

  @override
  Future<List<Song>> getSongs() => _guard(() async {
        final data = await _client
            .from('songs')
            .select(_songSelect)
            .order('title');
        return (data as List).map((e) => SongModel.fromJson(_resolveJson(e))).toList();
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

  /// Converts a storage path in `cover_url` to a public URL so that
  /// [Image.network] can load the thumbnail directly.
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
      // code 42P01 = undefined_table; PGRST116 = no rows (should not reach
      // here after maybeSingle, but kept for safety).
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
