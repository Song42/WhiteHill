import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../songs/data/models/song_model.dart';
import '../../../songs/domain/entities/song.dart';
import '../../domain/entities/album.dart';

const _kMediaBucket = 'media';

const _albumSelect = 'id, title, cover_url, updated_at, artists(name)';

const _songSelect =
    'id, title, lyrics_chord, youtube_url, audio_path, bpm, key, '
    'albums(title, cover_url, artists(name, image_url))';

/// Lightweight select for search results — no lyrics, bpm, key.
const _searchSongSelect = 'id, title, audio_path, albums(cover_url, artists(name))';

final recentAlbumsProvider =
    FutureProvider.autoDispose<List<Album>>((ref) async {
  final client = Supabase.instance.client;
  final data = await client
      .from('albums')
      .select(_albumSelect)
      .order('updated_at', ascending: false)
      .limit(5) as List;

  return data.map((json) => _parseAlbum(json, client)).toList();
});

final recentSongsProvider =
    FutureProvider.autoDispose<List<Song>>((ref) async {
  final client = Supabase.instance.client;
  final data = await client
      .from('songs')
      .select(_songSelect)
      .order('created_at', ascending: false)
      .limit(7) as List;

  return data.map((json) => SongModel.fromJson(_resolveCoverUrl(json, client))).toList();
});

final librarySearchQueryProvider = StateProvider.autoDispose<String>((_) => '');

// ---------------------------------------------------------------------------
// Server-side search (active query)
// ---------------------------------------------------------------------------

final searchAlbumsProvider =
    FutureProvider.autoDispose<List<Album>>((ref) async {
  final query = ref.watch(librarySearchQueryProvider).trim();
  if (query.isEmpty) return [];
  final client = Supabase.instance.client;
  final data = await client
      .from('albums')
      .select(_albumSelect)
      .ilike('title', '%$query%')
      .order('title')
      .limit(10) as List;
  return data.map((json) => _parseAlbum(json, client)).toList();
});

final searchSongsProvider =
    FutureProvider.autoDispose<List<Song>>((ref) async {
  final query = ref.watch(librarySearchQueryProvider).trim();
  if (query.isEmpty) return [];
  final client = Supabase.instance.client;
  final data = await client
      .from('songs')
      .select(_searchSongSelect)
      .ilike('title', '%$query%')
      .order('title')
      .limit(20) as List;
  return data
      .map((json) => SongModel.fromJson(_resolveCoverUrl(json, client)))
      .toList();
});

Album _parseAlbum(Map<String, dynamic> json, SupabaseClient client) {
  final artist = json['artists'] as Map<String, dynamic>?;
  String? coverUrl = json['cover_url'] as String?;
  if (coverUrl != null && !coverUrl.startsWith('http')) {
    coverUrl = client.storage.from(_kMediaBucket).getPublicUrl(coverUrl);
  }
  return Album(
    id: json['id'] as String,
    title: json['title'] as String,
    coverUrl: coverUrl,
    artistName: (artist?['name'] as String?) ?? '',
    updatedAt: json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'] as String)
        : null,
  );
}

Map<String, dynamic> _resolveCoverUrl(
    Map<String, dynamic> json, SupabaseClient client) {
  final album = json['albums'] as Map<String, dynamic>?;
  if (album == null) return json;
  final rawPath = album['cover_url'] as String?;
  if (rawPath == null || rawPath.startsWith('http')) return json;
  return {
    ...json,
    'albums': {
      ...album,
      'cover_url': client.storage.from(_kMediaBucket).getPublicUrl(rawPath),
    },
  };
}
