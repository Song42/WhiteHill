import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../audio/whitehill_audio_handler.dart';
import '../../features/songs/domain/entities/song.dart';

const _kAudioBucket = 'media';

/// Provided via ProviderScope override in main.dart after AudioService.init().
final audioHandlerProvider = Provider<WhitehillAudioHandler>(
  (ref) => throw UnimplementedError('audioHandlerProvider must be overridden'),
);

class GlobalPlayerState {
  final Song? currentSong;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool isLoading;

  const GlobalPlayerState({
    this.currentSong,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isLoading = false,
  });

  bool get hasCurrentSong => currentSong != null;

  GlobalPlayerState copyWith({
    Song? currentSong,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    bool? isLoading,
  }) {
    return GlobalPlayerState(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class GlobalPlayerNotifier extends StateNotifier<GlobalPlayerState> {
  final WhitehillAudioHandler _handler;
  late final StreamSubscription<Duration> _posSub;
  late final StreamSubscription<Duration?> _durSub;
  late final StreamSubscription<bool> _playingSub;
  late final StreamSubscription<ProcessingState> _processingSub;

  GlobalPlayerNotifier(this._handler) : super(const GlobalPlayerState()) {
    _posSub = _handler.player.positionStream.listen(
      (pos) => state = state.copyWith(position: pos),
    );
    _durSub = _handler.player.durationStream.listen(
      (dur) => state = state.copyWith(duration: dur ?? Duration.zero),
    );
    _playingSub = _handler.player.playingStream.listen(
      (playing) => state = state.copyWith(isPlaying: playing),
    );
    // Drive isLoading from the player's own processing state so it can never
    // get stuck — loading is true only while just_audio is in the loading phase.
    // When playback completes, seek back to 0 and pause.
    _processingSub = _handler.player.processingStateStream.listen(
      (ps) {
        if (ps == ProcessingState.completed) {
          _handler.seek(Duration.zero);
          _handler.pause();
          state = state.copyWith(
            isPlaying: false,
            isLoading: false,
            position: Duration.zero,
          );
        } else {
          state = state.copyWith(isLoading: ps == ProcessingState.loading);
        }
      },
    );
  }

  /// Loads [song]. If the same song is already loaded, does nothing (preserves
  /// playback position and paused state). Use [togglePlay] to start playback.
  Future<void> playSong(Song song) async {
    if (state.currentSong?.id == song.id && !state.isLoading) {
      return;
    }

    if (song.storagePath == null) {
      state = state.copyWith(currentSong: song);
      return;
    }

    // Reset timeline immediately so UI doesn't briefly show the previous song's
    // position/duration while the new signed URL is being fetched.
    state = state.copyWith(
      currentSong: song,
      position: Duration.zero,
      duration: Duration.zero,
    );

    final signedUrl = await Supabase.instance.client.storage
        .from(_kAudioBucket)
        .createSignedUrl(song.storagePath!, 3600);

    await _handler.loadAndPlay(
      signedUrl,
      MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artistName,
        artUri: song.coverUrl != null ? Uri.parse(song.coverUrl!) : null,
      ),
    );
  }

  void togglePlay() {
    if (state.isPlaying) {
      _handler.pause();
    } else {
      _handler.play();
    }
  }

  void seek(double value) {
    final ms = (value * state.duration.inMilliseconds).round();
    _handler.seek(Duration(milliseconds: ms));
  }

  @override
  void dispose() {
    _posSub.cancel();
    _durSub.cancel();
    _playingSub.cancel();
    _processingSub.cancel();
    super.dispose();
  }
}

/// Global, non-autoDispose player provider — survives screen navigation.
final globalPlayerProvider =
    StateNotifierProvider<GlobalPlayerNotifier, GlobalPlayerState>(
  (ref) => GlobalPlayerNotifier(ref.watch(audioHandlerProvider)),
);
