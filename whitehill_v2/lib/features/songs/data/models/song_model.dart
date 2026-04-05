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
    );
  }
}
