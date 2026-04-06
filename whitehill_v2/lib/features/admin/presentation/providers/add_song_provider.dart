import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _kMediaBucket = 'media';

class AddSongFormState {
  final int currentStep;
  // Step 1 — text values
  final String title;
  final String artistName;
  final String albumTitle;
  final String bpm;
  final String songKey;
  // Step 1 — resolved IDs (set when user picks from autocomplete)
  final String? selectedArtistId;
  final String? selectedAlbumId;
  final String? existingCoverFilename;
  final String? existingCoverUrl;
  // Step 2
  final String lyricsChord;
  // Step 3
  final String? audioFilePath;
  final String? audioFileName;
  final String? thumbnailFilePath;
  final String? thumbnailFileName;
  // Submission
  final bool isSubmitting;
  final String? submissionError;

  const AddSongFormState({
    this.currentStep = 0,
    this.title = '',
    this.artistName = '',
    this.albumTitle = '',
    this.bpm = '',
    this.songKey = '',
    this.selectedArtistId,
    this.selectedAlbumId,
    this.existingCoverFilename,
    this.existingCoverUrl,
    this.lyricsChord = '',
    this.audioFilePath,
    this.audioFileName,
    this.thumbnailFilePath,
    this.thumbnailFileName,
    this.isSubmitting = false,
    this.submissionError,
  });

  // Sentinel so copyWith can distinguish "set null" from "keep existing"
  static const _keep = Object();

  AddSongFormState copyWith({
    int? currentStep,
    String? title,
    String? artistName,
    String? albumTitle,
    String? bpm,
    String? songKey,
    Object? selectedArtistId = _keep,
    Object? selectedAlbumId = _keep,
    Object? existingCoverFilename = _keep,
    Object? existingCoverUrl = _keep,
    String? lyricsChord,
    String? audioFilePath,
    String? audioFileName,
    String? thumbnailFilePath,
    String? thumbnailFileName,
    bool? isSubmitting,
    Object? submissionError = _keep,
  }) {
    return AddSongFormState(
      currentStep: currentStep ?? this.currentStep,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      albumTitle: albumTitle ?? this.albumTitle,
      bpm: bpm ?? this.bpm,
      songKey: songKey ?? this.songKey,
      selectedArtistId: identical(selectedArtistId, _keep)
          ? this.selectedArtistId
          : selectedArtistId as String?,
      selectedAlbumId: identical(selectedAlbumId, _keep)
          ? this.selectedAlbumId
          : selectedAlbumId as String?,
      existingCoverFilename: identical(existingCoverFilename, _keep)
          ? this.existingCoverFilename
          : existingCoverFilename as String?,
      existingCoverUrl: identical(existingCoverUrl, _keep)
          ? this.existingCoverUrl
          : existingCoverUrl as String?,
      lyricsChord: lyricsChord ?? this.lyricsChord,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      audioFileName: audioFileName ?? this.audioFileName,
      thumbnailFilePath: thumbnailFilePath ?? this.thumbnailFilePath,
      thumbnailFileName: thumbnailFileName ?? this.thumbnailFileName,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submissionError: identical(submissionError, _keep)
          ? this.submissionError
          : submissionError as String?,
    );
  }
}

class AddSongNotifier extends AutoDisposeNotifier<AddSongFormState> {
  @override
  AddSongFormState build() => const AddSongFormState();

  void nextStep() => state = state.copyWith(currentStep: state.currentStep + 1);
  void previousStep() =>
      state = state.copyWith(currentStep: state.currentStep - 1);

  void saveStep1({
    required String title,
    required String artistName,
    required String albumTitle,
    required String bpm,
    required String songKey,
  }) {
    state = state.copyWith(
      title: title,
      artistName: artistName,
      albumTitle: albumTitle,
      bpm: bpm,
      songKey: songKey,
    );
  }

  void saveStep2({required String lyricsChord}) {
    state = state.copyWith(lyricsChord: lyricsChord);
  }

  /// Called when user selects an existing artist from the autocomplete.
  void selectArtist(String artistId) => state = state.copyWith(
        selectedArtistId: artistId,
        selectedAlbumId: null,
        existingCoverFilename: null,
        existingCoverUrl: null,
      );

  /// Called when user clears or manually edits the artist field.
  void clearArtist() => state = state.copyWith(
        selectedArtistId: null,
        selectedAlbumId: null,
        existingCoverFilename: null,
        existingCoverUrl: null,
      );

  /// Called when user selects an existing album from the autocomplete.
  void selectAlbum(String albumId, String? coverUrl) {
    String? filename;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      filename = Uri.parse(coverUrl).pathSegments.last;
    }
    state = state.copyWith(
      selectedAlbumId: albumId,
      existingCoverFilename: filename,
      existingCoverUrl: coverUrl,
    );
  }

  /// Called when user clears or manually edits the album field.
  void clearAlbum() => state = state.copyWith(
        selectedAlbumId: null,
        existingCoverFilename: null,
        existingCoverUrl: null,
      );

  void pickAudio({required String path, required String name}) {
    state = state.copyWith(audioFilePath: path, audioFileName: name);
  }

  void pickThumbnail({required String path, required String name}) {
    state = state.copyWith(thumbnailFilePath: path, thumbnailFileName: name);
  }

  void cancelSubmit() {
    state = state.copyWith(isSubmitting: false, submissionError: null);
  }

  void reset() => state = const AddSongFormState();

  Future<void> submit() async {
    state = state.copyWith(isSubmitting: true, submissionError: null);
    try {
      final client = Supabase.instance.client;

      // 1. Artist — use cached ID if available, otherwise look up / create
      final String artistId;
      if (state.selectedArtistId != null) {
        artistId = state.selectedArtistId!;
      } else {
        var row = await client
            .from('artists')
            .select('id')
            .eq('name', state.artistName)
            .maybeSingle();
        row ??= await client
            .from('artists')
            .insert({'name': state.artistName})
            .select('id')
            .single();
        artistId = row['id'] as String;
      }

      // 2. Album — use cached ID (existing) or generate a new one client-side
      String? albumId;
      if (state.albumTitle.isNotEmpty) {
        if (state.selectedAlbumId != null) {
          // Existing album
          albumId = state.selectedAlbumId!;
          final updateData = <String, dynamic>{
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          };
          if (state.thumbnailFilePath != null) {
            final ext =
                state.thumbnailFileName!.split('.').last.toLowerCase();
            final thumbPath = 'albums/$albumId/cover.$ext';
            final bytes = await File(state.thumbnailFilePath!).readAsBytes();
            await client.storage.from(_kMediaBucket).uploadBinary(
                  thumbPath,
                  bytes,
                  fileOptions: FileOptions(upsert: true),
                );
            updateData['cover_url'] =
                client.storage.from(_kMediaBucket).getPublicUrl(thumbPath);
          }
          await client.from('albums').update(updateData).eq('id', albumId);
        } else {
          // New album — generate ID client-side so we can pre-compute the
          // thumbnail path and include cover_url in the INSERT (no PATCH needed)
          albumId = _generateUuid();
          String? coverUrl;
          if (state.thumbnailFilePath != null) {
            final ext =
                state.thumbnailFileName!.split('.').last.toLowerCase();
            final thumbPath = 'albums/$albumId/cover.$ext';
            final bytes = await File(state.thumbnailFilePath!).readAsBytes();
            await client.storage
                .from(_kMediaBucket)
                .uploadBinary(thumbPath, bytes);
            coverUrl =
                client.storage.from(_kMediaBucket).getPublicUrl(thumbPath);
          }
          final now = DateTime.now().toUtc().toIso8601String();
          final albumData = <String, dynamic>{
            'id': albumId,
            'title': state.albumTitle,
            'artist_id': artistId,
            'updated_at': now,
          };
          if (coverUrl != null) albumData['cover_url'] = coverUrl;
          await client.from('albums').insert(albumData);
        }
      }

      // 3. Song — generate ID client-side so audio_path is known before INSERT
      final songId = _generateUuid();
      String? audioPath;
      if (state.audioFilePath != null) {
        final ext = state.audioFileName!.split('.').last.toLowerCase();
        audioPath = albumId != null
            ? 'songs/$artistId/$albumId/$songId.$ext'
            : 'songs/$artistId/$songId.$ext';
      }

      final songData = <String, dynamic>{
        'id': songId,
        'title': state.title,
        'album_id': albumId,
        'lyrics_chord': state.lyricsChord.isEmpty ? null : state.lyricsChord,
        'bpm': state.bpm.isEmpty ? null : int.tryParse(state.bpm),
        'key': state.songKey.isEmpty ? null : state.songKey,
      };
      if (audioPath != null) songData['audio_path'] = audioPath;
      await client.from('songs').insert(songData);

      // 4. Upload audio after insert (path is already persisted)
      if (state.audioFilePath != null) {
        final bytes = await File(state.audioFilePath!).readAsBytes();
        await client.storage
            .from(_kMediaBucket)
            .uploadBinary(audioPath!, bytes);
      }

      state = state.copyWith(isSubmitting: false);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submissionError: e.toString(),
      );
    }
  }
}

/// UUID v4 generator — avoids adding the `uuid` package as a dependency.
String _generateUuid() {
  final rng = Random.secure();
  final b = List<int>.generate(16, (_) => rng.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String h(int n) => n.toRadixString(16).padLeft(2, '0');
  return '${b.sublist(0, 4).map(h).join()}'
      '-${b.sublist(4, 6).map(h).join()}'
      '-${b.sublist(6, 8).map(h).join()}'
      '-${b.sublist(8, 10).map(h).join()}'
      '-${b.sublist(10, 16).map(h).join()}';
}

final addSongFormProvider =
    NotifierProvider.autoDispose<AddSongNotifier, AddSongFormState>(
  AddSongNotifier.new,
);
