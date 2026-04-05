import '../entities/song.dart';

abstract class SongRepository {
  Future<List<Song>> getSongs();
  Future<Song> getSongById(String id);
}
