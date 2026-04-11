import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../songs/data/models/song_model.dart';
import '../../../songs/domain/entities/song.dart';

const _kMediaBucket = 'media';

const _songSelect =
    'id, title, lyrics_chord, youtube_url, audio_path, bpm, key, '
    'albums(title, cover_url, artists(name, image_url))';

/// Fetches all songs belonging to the given album, ordered by creation date.
final albumSongsProvider = FutureProvider.autoDispose
    .family<List<Song>, String>((ref, albumId) async {
      final client = Supabase.instance.client;
      final data =
          await client
                  .from('songs')
                  .select(_songSelect)
                  .eq('album_id', albumId)
                  .order('created_at', ascending: true)
              as List;

      return data.map((json) {
        final album = json['albums'] as Map<String, dynamic>?;
        if (album != null) {
          final rawPath = album['cover_url'] as String?;
          if (rawPath != null && !rawPath.startsWith('http')) {
            json = {
              ...json,
              'albums': {
                ...album,
                'cover_url': client.storage
                    .from(_kMediaBucket)
                    .getPublicUrl(rawPath),
              },
            };
          }
        }
        return SongModel.fromJson(json);
      }).toList();
    });
