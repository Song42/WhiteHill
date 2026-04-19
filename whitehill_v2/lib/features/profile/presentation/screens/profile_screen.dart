import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_refresh.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/providers/profile_provider.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../admin/presentation/screens/add_song_screen.dart';
import '../../../admin/presentation/screens/manage_members_screen.dart';
import '../../../admin/presentation/screens/manage_songs_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: profileAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => refreshAll(ref),
              ),
              data: (profile) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: profile.avatarUrl != null
                        ? NetworkImage(profile.avatarUrl!)
                        : null,
                    child: profile.avatarUrl == null
                        ? const Icon(Icons.person, size: 48)
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    profile.nickname,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(label: Text(profile.role.displayLabel)),
                  if (profile.role == AppRole.admin ||
                      profile.role == AppRole.worshipLeader ||
                      profile.role == AppRole.worshipTeam) ...[
                    const SizedBox(height: 32),
                    _AdminActions(),
                  ],
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () =>
                          ref.read(authStateProvider.notifier).signOut(),
                      icon: const Icon(Icons.logout),
                      label: const Text('LOG OUT'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminActions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final isWorshipLeader =
        ref.watch(profileRoleProvider).valueOrNull == AppRole.worshipLeader;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () {
            if (!isOnline) {
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  const SnackBar(
                    content: Text(
                      'No internet connection. Adding songs requires network access.',
                    ),
                  ),
                );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddSongScreen()),
            );
          },
          icon: Icon(isOnline ? Icons.add : Icons.cloud_off_rounded),
          label: const Text('Add New Song'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageSongsScreen()),
            );
          },
          icon: const Icon(Icons.library_music_outlined),
          label: const Text('Manage Songs'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        if (isAdmin) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageMembersScreen()),
              );
            },
            icon: const Icon(Icons.group_outlined),
            label: const Text('Manage Members'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
        if (isWorshipLeader) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const ManageMembersScreen(title: 'Manage Team'),
                ),
              );
            },
            icon: const Icon(Icons.group_outlined),
            label: const Text('Manage Team'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ],
    );
  }
}
