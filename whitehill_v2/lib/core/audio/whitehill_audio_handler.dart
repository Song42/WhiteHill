import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// audio_service handler that bridges just_audio to the system media controls
/// (lock screen, notification, headset buttons).
class WhitehillAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer player = AudioPlayer();

  WhitehillAudioHandler() {
    // Forward just_audio events → audio_service playbackState stream.
    player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Keep mediaItem duration up to date.
    player.durationStream.listen((duration) {
      final item = mediaItem.value;
      if (item != null && duration != null) {
        mediaItem.add(item.copyWith(duration: duration));
      }
    });
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    final idle = player.processingState == ProcessingState.idle;
    return PlaybackState(
      // Empty controls when idle so audio_service removes the notification
      // immediately — otherwise it keeps the notification alive and the user
      // has to swipe twice.
      controls: idle
          ? []
          : [
              MediaControl.skipToPrevious,
              if (player.playing) MediaControl.pause else MediaControl.play,
              MediaControl.skipToNext,
            ],
      systemActions: idle ? const {} : const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      playing: player.playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
    );
  }

  /// Load a new track without auto-playing.
  /// preload:false returns immediately so the caller is never blocked —
  /// just_audio streams the HTTP source progressively and ProcessingState
  /// events track when buffering is ready.
  Future<void> loadAndPlay(String uri, MediaItem item) async {
    mediaItem.add(item);
    await player.setAudioSource(
      AudioSource.uri(Uri.parse(uri)),
      preload: false,
    );
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }

  /// Called when the user swipes away the notification on Android.
  /// Delegates to stop() so the player fully tears down.
  @override
  Future<void> onNotificationDeleted() => stop();
}
