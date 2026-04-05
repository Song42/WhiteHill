class Song {
  final String id;
  final String title;
  final String? artistName;
  final String? albumTitle;
  final String? coverUrl;
  final String? lyricsChord;
  final String? youtubeUrl;
  final String? storagePath;
  final int? bpm;
  final String? key;

  const Song({
    required this.id,
    required this.title,
    this.artistName,
    this.albumTitle,
    this.coverUrl,
    this.lyricsChord,
    this.youtubeUrl,
    this.storagePath,
    this.bpm,
    this.key,
  });
}
