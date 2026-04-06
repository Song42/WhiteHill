class Album {
  final String id;
  final String title;
  final String? coverUrl;
  final String artistName;
  final DateTime? updatedAt;

  const Album({
    required this.id,
    required this.title,
    this.coverUrl,
    required this.artistName,
    this.updatedAt,
  });
}
