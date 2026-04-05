import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlayerState {
  final bool isPlaying;
  final Duration position;
  final Duration duration;

  const PlayerState({
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = const Duration(minutes: 4, seconds: 23),
  });

  PlayerState copyWith({bool? isPlaying, Duration? position, Duration? duration}) {
    return PlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  PlayerNotifier() : super(const PlayerState());

  void togglePlay() => state = state.copyWith(isPlaying: !state.isPlaying);

  void seek(double value) {
    final ms = (value * state.duration.inMilliseconds).round();
    state = state.copyWith(position: Duration(milliseconds: ms));
  }
}

final playerProvider =
    StateNotifierProvider.autoDispose<PlayerNotifier, PlayerState>(
  (ref) => PlayerNotifier(),
);

final showChordsProvider = StateProvider.autoDispose<bool>((ref) => false);
