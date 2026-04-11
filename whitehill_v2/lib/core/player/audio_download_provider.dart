import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _kAudioBucket = 'media';

enum DownloadStatus { idle, downloading, downloaded, error }

class AudioDownloadState {
  final DownloadStatus status;
  final String? localPath;
  final String? error;

  const AudioDownloadState({
    this.status = DownloadStatus.idle,
    this.localPath,
    this.error,
  });

  AudioDownloadState copyWith({
    DownloadStatus? status,
    String? localPath,
    String? error,
  }) {
    return AudioDownloadState(
      status: status ?? this.status,
      localPath: localPath ?? this.localPath,
      error: error,
    );
  }
}

class AudioDownloadNotifier extends FamilyNotifier<AudioDownloadState, String> {
  @override
  AudioDownloadState build(String arg) {
    // Check if already downloaded on init.
    _checkExisting(arg);
    return const AudioDownloadState();
  }

  Future<void> _checkExisting(String storagePath) async {
    final file = await _localFile(storagePath);
    if (await file.exists()) {
      state = AudioDownloadState(
        status: DownloadStatus.downloaded,
        localPath: file.path,
      );
    }
  }

  Future<void> download(String storagePath) async {
    if (state.status == DownloadStatus.downloading) return;

    state = state.copyWith(status: DownloadStatus.downloading, error: null);

    try {
      final bytes = await Supabase.instance.client.storage
          .from(_kAudioBucket)
          .download(storagePath);

      final file = await _localFile(storagePath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);

      state = AudioDownloadState(
        status: DownloadStatus.downloaded,
        localPath: file.path,
      );
    } catch (e) {
      state = AudioDownloadState(
        status: DownloadStatus.error,
        error: e.toString(),
      );
    }
  }

  Future<void> delete(String storagePath) async {
    final file = await _localFile(storagePath);
    if (await file.exists()) {
      await file.delete();
    }
    state = const AudioDownloadState();
  }

  Future<File> _localFile(String storagePath) => localAudioFile(storagePath);
}

/// Returns the local [File] for a given storage path.
/// Shared between the download provider and the player.
Future<File> localAudioFile(String storagePath) async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}/whitehill_audio/$storagePath');
}

final audioDownloadProvider =
    NotifierProvider.family<AudioDownloadNotifier, AudioDownloadState, String>(
      AudioDownloadNotifier.new,
    );

/// Probes the duration of a locally saved audio file without starting playback.
final localAudioDurationProvider = FutureProvider.family<Duration?, String>((
  ref,
  storagePath,
) async {
  final file = await localAudioFile(storagePath);
  if (!await file.exists()) return null;
  final player = AudioPlayer();
  try {
    return await player.setFilePath(file.path);
  } catch (_) {
    return null;
  } finally {
    await player.dispose();
  }
});
