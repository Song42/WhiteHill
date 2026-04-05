import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whitehill_v2/core/audio/audio_player_handler.dart';
import 'package:whitehill_v2/core/audio/mobile_audio_handler.dart';

// Must match your Supabase Storage bucket name.
const _kAudioBucket = 'media';

class PlayerState {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool isLoading;

  const PlayerState({
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isLoading = false,
  });

  PlayerState copyWith({
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    bool? isLoading,
  }) {
    return PlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  final AudioPlayerHandler _handler;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  StreamSubscription<bool>? _playingSub;

  PlayerNotifier(this._handler) : super(const PlayerState()) {
    _posSub = _handler.positionStream.listen(
      (pos) => state = state.copyWith(position: pos),
    );
    _durSub = _handler.durationStream.listen(
      (dur) => state = state.copyWith(duration: dur ?? Duration.zero),
    );
    _playingSub = _handler.playingStream.listen(
      (playing) => state = state.copyWith(isPlaying: playing),
    );
  }

  Future<void> load(String storagePath) async {
    state = state.copyWith(isLoading: true);
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from(_kAudioBucket)
          .createSignedUrl(storagePath, 3600);
      await _handler.load(signedUrl);
    } finally {
      state = state.copyWith(isLoading: false);
    }
    _handler.play();
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
    _posSub?.cancel();
    _durSub?.cancel();
    _playingSub?.cancel();
    _handler.dispose();
    super.dispose();
  }
}

final playerProvider =
    StateNotifierProvider.autoDispose<PlayerNotifier, PlayerState>(
  (ref) => PlayerNotifier(MobileAudioHandler()),
);

final showChordsProvider = StateProvider.autoDispose<bool>((ref) => false);
