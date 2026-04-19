import 'package:flutter/foundation.dart';

import 'package:whitehill_v2/features/songs/domain/entities/song_exception.dart';

/// Debug builds: full error string (raw server message).
/// Release builds: brief general message safe to show users.
String resolveErrorMessage(Object error) {
  if (kDebugMode) return error.toString();
  return switch (error) {
    SongNetworkException() => 'Connection failed.',
    SongNotFoundException() => 'Item not found.',
    _ => 'Something went wrong.',
  };
}
