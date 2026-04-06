import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/song_repository_impl.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/song_repository.dart';

final songRepositoryProvider = Provider<SongRepository>((ref) {
  return SongRepositoryImpl(Supabase.instance.client);
});

final songsProvider = FutureProvider<List<Song>>((ref) {
  return ref.watch(songRepositoryProvider).getSongs();
});

final selectedSongsProvider = FutureProvider<List<Song>>((ref) {
  return ref.watch(songRepositoryProvider).getSelectedSongs();
});

final songByIdProvider = FutureProvider.family<Song, String>((ref, id) {
  return ref.watch(songRepositoryProvider).getSongById(id);
});
