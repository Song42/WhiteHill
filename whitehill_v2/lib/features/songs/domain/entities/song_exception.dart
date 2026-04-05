sealed class SongException implements Exception {
  final String message;
  const SongException(this.message);

  @override
  String toString() => message;
}

/// Table missing, RLS blocking, or any other DB-level error.
final class SongDatabaseException extends SongException {
  const SongDatabaseException(super.message);
}

/// Device is offline or the Supabase host is unreachable.
final class SongNetworkException extends SongException {
  const SongNetworkException(super.message);
}

/// A requested song was not found.
final class SongNotFoundException extends SongException {
  const SongNotFoundException(super.message);
}
