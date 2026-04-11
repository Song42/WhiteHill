import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Exposes the current Supabase [Session] (null when signed out).
///
/// Listens to `onAuthStateChange` so UI rebuilds automatically on login/logout.
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<Session?>>(
      (ref) => AuthStateNotifier(),
    );

class AuthStateNotifier extends StateNotifier<AsyncValue<Session?>> {
  AuthStateNotifier() : super(const AsyncValue.loading()) {
    // Seed with the current session (may be null).
    final currentSession = _client.auth.currentSession;
    state = AsyncValue.data(currentSession);
    if (currentSession != null) {
      _updateLastSeen(currentSession.user.id);
    }

    // Keep in sync with future auth events.
    _subscription = _client.auth.onAuthStateChange.listen((event) {
      state = AsyncValue.data(event.session);
      if (event.session != null &&
          (event.event == AuthChangeEvent.signedIn ||
              event.event == AuthChangeEvent.tokenRefreshed)) {
        _updateLastSeen(event.session!.user.id);
      }
    });
  }

  final _client = Supabase.instance.client;
  late final StreamSubscription<AuthState> _subscription;

  Future<void> _updateLastSeen(String userId) async {
    await _client
        .from('profiles')
        .update({'last_seen_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', userId);
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.example.whitehill2://login-callback/',
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
