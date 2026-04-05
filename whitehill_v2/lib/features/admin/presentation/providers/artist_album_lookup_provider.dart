import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ArtistOption {
  final String id;
  final String name;
  const ArtistOption({required this.id, required this.name});
}

class AlbumOption {
  final String id;
  final String title;
  final String? coverUrl;
  const AlbumOption({required this.id, required this.title, this.coverUrl});
}

final allArtistsProvider =
    FutureProvider.autoDispose<List<ArtistOption>>((ref) async {
  final data = await Supabase.instance.client
      .from('artists')
      .select('id, name')
      .order('name') as List;
  return data
      .map((r) =>
          ArtistOption(id: r['id'] as String, name: r['name'] as String))
      .toList();
});

/// Fetches albums for an artist, including cover_url so step 3 can show the
/// existing thumbnail without an extra request.
final albumsByArtistProvider =
    FutureProvider.autoDispose.family<List<AlbumOption>, String>(
        (ref, artistId) async {
  if (artistId.isEmpty) return [];
  final data = await Supabase.instance.client
      .from('albums')
      .select('id, title, cover_url')
      .eq('artist_id', artistId)
      .order('title') as List;
  return data
      .map((r) => AlbumOption(
            id: r['id'] as String,
            title: r['title'] as String,
            coverUrl: r['cover_url'] as String?,
          ))
      .toList();
});

/// Returns true if a song with [title] already exists under the same
/// artist + album scope. Uses cached IDs when available (1 request instead of 3).
Future<bool> checkSongTitleExists({
  required String title,
  required String artistName,
  String albumTitle = '',
  String? artistId,
  String? albumId,
}) async {
  if (title.isEmpty || artistName.isEmpty) return false;

  final client = Supabase.instance.client;

  if (albumId != null) {
    // Fast path: album ID already known — single request
    final result = await client
        .from('songs')
        .select('id')
        .ilike('title', title)
        .eq('album_id', albumId)
        .maybeSingle();
    return result != null;
  }

  // Resolve artist ID if not cached
  final String resolvedArtistId;
  if (artistId != null) {
    resolvedArtistId = artistId;
  } else {
    final artistRow = await client
        .from('artists')
        .select('id')
        .ilike('name', artistName)
        .maybeSingle();
    if (artistRow == null) return false;
    resolvedArtistId = artistRow['id'] as String;
  }

  if (albumTitle.isNotEmpty) {
    final albumRow = await client
        .from('albums')
        .select('id')
        .eq('artist_id', resolvedArtistId)
        .ilike('title', albumTitle)
        .maybeSingle();
    if (albumRow == null) return false;

    final result = await client
        .from('songs')
        .select('id')
        .ilike('title', title)
        .eq('album_id', albumRow['id'] as String)
        .maybeSingle();
    return result != null;
  } else {
    // No album — check across all albums by this artist
    final albums = await client
        .from('albums')
        .select('id')
        .eq('artist_id', resolvedArtistId) as List;
    if (albums.isEmpty) return false;

    final result = await client
        .from('songs')
        .select('id')
        .ilike('title', title)
        .inFilter('album_id', albums.map((a) => a['id'] as String).toList())
        .maybeSingle();
    return result != null;
  }
}
