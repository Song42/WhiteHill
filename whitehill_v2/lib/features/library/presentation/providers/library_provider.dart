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

final recentAlbumsProvider =
    FutureProvider.autoDispose<List<Album>>((ref) async {
  final client = Supabase.instance.client;
  final data = await client
      .from('albums')
      .select(_albumSelect)
      .order('updated_at', ascending: false)
      .limit(5) as List;

  return data.map((json) {
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
  }).toList();
});

final recentSongsProvider =
    FutureProvider.autoDispose<List<Song>>((ref) async {
  final client = Supabase.instance.client;
  final data = await client
      .from('songs')
      .select(_songSelect)
      .order('created_at', ascending: false)
      .limit(7) as List;

  return data.map((json) {
    final album = json['albums'] as Map<String, dynamic>?;
    if (album != null) {
      final rawPath = album['cover_url'] as String?;
      if (rawPath != null && !rawPath.startsWith('http')) {
        json = {
          ...json,
          'albums': {
            ...album,
            'cover_url':
                client.storage.from(_kMediaBucket).getPublicUrl(rawPath),
          },
        };
      }
    }
    return SongModel.fromJson(json);
  }).toList();
});

final librarySearchQueryProvider = StateProvider.autoDispose<String>((_) => '');

final filteredAlbumsProvider =
    FutureProvider.autoDispose<List<Album>>((ref) async {
  final albums = await ref.watch(recentAlbumsProvider.future);
  final query = ref.watch(librarySearchQueryProvider).toLowerCase().trim();
  if (query.isEmpty) return albums;
  return albums
      .where((a) =>
          a.title.toLowerCase().contains(query) ||
          a.artistName.toLowerCase().contains(query))
      .toList();
});

final filteredSongsProvider =
    FutureProvider.autoDispose<List<Song>>((ref) async {
  final songs = await ref.watch(recentSongsProvider.future);
  final query = ref.watch(librarySearchQueryProvider).toLowerCase().trim();
  if (query.isEmpty) return songs;
  return songs
      .where((s) =>
          s.title.toLowerCase().contains(query) ||
          (s.artistName?.toLowerCase().contains(query) ?? false))
      .toList();
});
