import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_provider.dart';

enum AppRole {
  admin,
  worshipLeader,
  worshipTeam,
  member,
  guest;

  String get displayLabel {
    switch (this) {
      case AppRole.worshipLeader:
        return 'WORSHIP LEADER';
      case AppRole.worshipTeam:
        return 'WORSHIP TEAM';
      case AppRole.member:
        return 'MEMBER';
      default:
        return name.toUpperCase();
    }
  }

  String get dbValue {
    switch (this) {
      case AppRole.worshipLeader:
        return 'worship_leader';
      case AppRole.worshipTeam:
        return 'worship_team';
      default:
        return name;
    }
  }
}

const _dbRoleMap = {
  'admin': AppRole.admin,
  'worship_leader': AppRole.worshipLeader,
  'worship_team': AppRole.worshipTeam,
  'member': AppRole.member,
  'guest': AppRole.guest,
};

class UserProfile {
  final String id;
  final String email;
  final String nickname;
  final String? avatarUrl;
  final AppRole role;

  const UserProfile({
    required this.id,
    required this.email,
    required this.nickname,
    this.avatarUrl,
    required this.role,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final roleStr = map['role'] as String? ?? 'member';
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      nickname: map['nickname'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
      role: _dbRoleMap[roleStr.toLowerCase()] ?? AppRole.member,
    );
  }
}

/// Fetches the current user's full profile from the `profiles` table.
final profileProvider = FutureProvider<UserProfile>((ref) async {
  final session = ref.watch(authStateProvider).valueOrNull;
  if (session == null) throw StateError('Not authenticated');

  final client = Supabase.instance.client;
  final rows = await client.from('profiles').select().eq('id', session.user.id);

  if (rows.isNotEmpty) return UserProfile.fromMap(rows.first);

  // Profile row doesn't exist yet — create it from auth metadata.
  final user = session.user;
  final meta = user.userMetadata ?? {};
  final newRow = {
    'id': user.id,
    'email': user.email,
    'nickname': meta['full_name'] ?? user.email?.split('@').first ?? '',
    'avatar_url': meta['avatar_url'],
  };
  final inserted = await client
      .from('profiles')
      .insert(newRow)
      .select()
      .single();
  return UserProfile.fromMap(inserted);
});

/// Fetches the current user's role from the `profiles` table.
final profileRoleProvider = FutureProvider<AppRole>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  return profile.role;
});

/// Convenience provider: true if the current user is an admin.
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(profileRoleProvider).valueOrNull == AppRole.admin;
});
