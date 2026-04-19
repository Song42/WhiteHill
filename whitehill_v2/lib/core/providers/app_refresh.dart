import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/library/presentation/providers/library_provider.dart';
import '../../features/songs/presentation/providers/songs_provider.dart';
import 'profile_provider.dart';

/// Invalidates every page-level data provider so all three tabs refetch.
void refreshAll(WidgetRef ref) {
  ref.invalidate(selectedSongsProvider);
  ref.invalidate(recentAlbumsProvider);
  ref.invalidate(recentSongsProvider);
  ref.invalidate(searchAlbumsProvider);
  ref.invalidate(searchSongsProvider);
  ref.invalidate(profileProvider);
}
