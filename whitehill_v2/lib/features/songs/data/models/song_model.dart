import '../../domain/entities/song.dart';

class SongModel extends Song {
  const SongModel({
    required super.id,
    required super.title,
    super.artistName,
    super.albumTitle,
    super.coverUrl,
    super.lyricsChord,
    super.youtubeUrl,
    super.storagePath,
    super.bpm,
    super.key,
    super.totalSelections,
    super.lastSelectedAt,
  });

  factory SongModel.fromJson(Map<String, dynamic> json) {
    final album = json['albums'] as Map<String, dynamic>?;
    final artist = album?['artists'] as Map<String, dynamic>?;

    return SongModel(
      id: json['id'] as String,
      title: json['title'] as String,
      artistName: artist?['name'] as String?,
      albumTitle: album?['title'] as String?,
      coverUrl: album?['cover_url'] as String?,
      lyricsChord: json['lyrics_chord'] as String?,
      youtubeUrl: json['youtube_url'] as String?,
      storagePath: json['audio_path'] as String?,
      bpm: json['bpm'] as int?,
      key: json['key'] as String?,
      totalSelections: (json['total_selections'] as int?) ?? 0,
      lastSelectedAt: json['last_selected_at'] != null
          ? DateTime.parse(json['last_selected_at'] as String)
          : null,
    );
  }

  /// Flat JSON for local cache (no nested albums/artists structure).
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist_name': artistName,
        'album_title': albumTitle,
        'cover_url': coverUrl,
        'lyrics_chord': lyricsChord,
        'youtube_url': youtubeUrl,
        'audio_path': storagePath,
        'bpm': bpm,
        'key': key,
        'total_selections': totalSelections,
        'last_selected_at': lastSelectedAt?.toIso8601String(),
      };

  factory SongModel.fromCacheJson(Map<String, dynamic> json) => SongModel(
        id: json['id'] as String,
        title: json['title'] as String,
        artistName: json['artist_name'] as String?,
        albumTitle: json['album_title'] as String?,
        coverUrl: json['cover_url'] as String?,
        lyricsChord: json['lyrics_chord'] as String?,
        youtubeUrl: json['youtube_url'] as String?,
        storagePath: json['audio_path'] as String?,
        bpm: json['bpm'] as int?,
        key: json['key'] as String?,
        totalSelections: (json['total_selections'] as int?) ?? 0,
        lastSelectedAt: json['last_selected_at'] != null
            ? DateTime.parse(json['last_selected_at'] as String)
            : null,
      );
}
