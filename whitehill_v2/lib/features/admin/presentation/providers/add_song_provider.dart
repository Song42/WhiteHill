import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _kMediaBucket = 'media';

class AddSongFormState {
  final int currentStep;
  // Step 1
  final String title;
  final String artistName;
  final String albumTitle;
  final String bpm;
  final String songKey;
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

  void pickAudio({required String path, required String name}) {
    state = state.copyWith(audioFilePath: path, audioFileName: name);
  }

  void pickThumbnail({required String path, required String name}) {
    state = state.copyWith(thumbnailFilePath: path, thumbnailFileName: name);
  }

  void reset() => state = const AddSongFormState();

  Future<void> submit() async {
    state = state.copyWith(isSubmitting: true, submissionError: null);
    try {
      final client = Supabase.instance.client;

      // 1. Find or create artist
      var artistRow = await client
          .from('artists')
          .select('id')
          .eq('name', state.artistName)
          .maybeSingle();
      artistRow ??= await client
          .from('artists')
          .insert({'name': state.artistName})
          .select('id')
          .single();
      final artistId = artistRow['id'] as String;

      // 2. Find or create album (if provided)
      String? albumId;
      if (state.albumTitle.isNotEmpty) {
        var albumRow = await client
            .from('albums')
            .select('id')
            .eq('artist_id', artistId)
            .eq('title', state.albumTitle)
            .maybeSingle();
        albumRow ??= await client
            .from('albums')
            .insert({'title': state.albumTitle, 'artist_id': artistId})
            .select('id')
            .single();
        albumId = albumRow['id'] as String;

        // Upload thumbnail and set album cover_url
        if (state.thumbnailFilePath != null) {
          final ext = state.thumbnailFileName!.split('.').last.toLowerCase();
          final thumbPath = 'albums/$albumId/cover.$ext';
          final bytes =
              await File(state.thumbnailFilePath!).readAsBytes();
          await client.storage
              .from(_kMediaBucket)
              .uploadBinary(thumbPath, bytes,
                  fileOptions: FileOptions(upsert: true));
          final coverUrl = client.storage
              .from(_kMediaBucket)
              .getPublicUrl(thumbPath);
          await client
              .from('albums')
              .update({'cover_url': coverUrl})
              .eq('id', albumId);
        }
      }

      // 3. Insert song record (let Supabase generate the ID)
      final songRow = await client.from('songs').insert({
        'title': state.title,
        'album_id': albumId,
        'lyrics_chord': state.lyricsChord.isEmpty ? null : state.lyricsChord,
        'bpm': state.bpm.isEmpty ? null : int.tryParse(state.bpm),
        'key': state.songKey.isEmpty ? null : state.songKey,
      }).select('id').single();
      final songId = songRow['id'] as String;

      // 4. Upload audio and update audio_path
      if (state.audioFilePath != null) {
        final ext = state.audioFileName!.split('.').last.toLowerCase();
        final audioPath = albumId != null
            ? 'songs/$artistId/$albumId/$songId.$ext'
            : 'songs/$artistId/$songId.$ext';
        final bytes = await File(state.audioFilePath!).readAsBytes();
        await client.storage
            .from(_kMediaBucket)
            .uploadBinary(audioPath, bytes);
        await client
            .from('songs')
            .update({'audio_path': audioPath})
            .eq('id', songId);
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

final addSongFormProvider =
    NotifierProvider.autoDispose<AddSongNotifier, AddSongFormState>(
  AddSongNotifier.new,
);
