import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/profile_provider.dart';

class MemberProfile {
  final String id;
  final String email;
  final String nickname;
  final String? avatarUrl;
  final AppRole role;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;

  const MemberProfile({
    required this.id,
    required this.email,
    required this.nickname,
    this.avatarUrl,
    required this.role,
    this.createdAt,
    this.lastSeenAt,
  });

  factory MemberProfile.fromMap(Map<String, dynamic> map) {
    final roleStr = map['role'] as String? ?? 'member';
    const dbRoleMap = {
      'admin': AppRole.admin,
      'worship_leader': AppRole.worshipLeader,
      'worship_team': AppRole.worshipTeam,
      'member': AppRole.member,
    };
    return MemberProfile(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      nickname: map['nickname'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
      role: dbRoleMap[roleStr.toLowerCase()] ?? AppRole.member,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
      lastSeenAt: map['last_seen_at'] != null
          ? DateTime.tryParse(map['last_seen_at'] as String)
          : null,
    );
  }
}

/// Fetches all profiles the server returns (filtered by Supabase RLS).
final allMembersProvider = FutureProvider<List<MemberProfile>>((ref) async {
  final client = Supabase.instance.client;
  final rows = await client
      .from('profiles')
      .select()
      .order('created_at', ascending: false);
  return rows.map((r) => MemberProfile.fromMap(r)).toList();
});

/// Updates a member's role in the database.
Future<void> updateMemberRole(String memberId, AppRole newRole) async {
  await Supabase.instance.client
      .from('profiles')
      .update({'role': newRole.dbValue})
      .eq('id', memberId);
}
