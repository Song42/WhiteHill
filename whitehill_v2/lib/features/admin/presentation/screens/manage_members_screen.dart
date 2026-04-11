import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/profile_provider.dart';
import '../providers/manage_members_provider.dart';

class ManageMembersScreen extends ConsumerWidget {
  const ManageMembersScreen({super.key, this.title = 'Manage Members'});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(allMembersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load members: $e'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(allMembersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (members) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(allMembersProvider),
          child: members.isEmpty
              ? const Center(child: Text('No members found'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: members.length,
                  separatorBuilder: (_, _) => const SizedBox.shrink(),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return _MemberTile(member: member);
                  },
                ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _formatDateTime(DateTime date) {
  final d = _formatDate(date);
  final h = date.hour.toString().padLeft(2, '0');
  final m = date.minute.toString().padLeft(2, '0');
  return '$d $h:$m';
}

// ── List tile: avatar, nickname, last login, role ──

class _MemberTile extends ConsumerWidget {
  const _MemberTile({required this.member});

  final MemberProfile member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lastLogin = member.lastSeenAt != null
        ? _formatDate(member.lastSeenAt!)
        : '—';

    return ListTile(
      onTap: () => _showProfileModal(context, ref, member),
      leading: CircleAvatar(
        radius: 22,
        backgroundImage: member.avatarUrl != null
            ? NetworkImage(member.avatarUrl!)
            : null,
        child: member.avatarUrl == null
            ? const Icon(Icons.person, size: 22)
            : null,
      ),
      title: Text(
        member.nickname,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'Last login $lastLogin',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      trailing: Chip(
        label: Text(
          member.role.displayLabel,
          style: theme.textTheme.labelSmall,
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

// ── Allowed role changes per viewer role ──

List<AppRole>? _allowedRoles(
  AppRole viewerRole,
  AppRole memberRole, {
  required bool isSelf,
}) {
  if (isSelf) return null;
  if (viewerRole == AppRole.admin) {
    return AppRole.values;
  }
  if (viewerRole == AppRole.worshipLeader) {
    if (memberRole == AppRole.member || memberRole == AppRole.worshipTeam) {
      return const [AppRole.member, AppRole.worshipTeam];
    }
  }
  return null;
}

// ── Modal: full profile information + role editing ──

void _showProfileModal(
  BuildContext context,
  WidgetRef ref,
  MemberProfile member,
) {
  final viewerProfile = ref.read(profileProvider).valueOrNull;
  final viewerRole = viewerProfile?.role ?? AppRole.member;
  final isSelf = viewerProfile?.id == member.id;
  final allowed = _allowedRoles(viewerRole, member.role, isSelf: isSelf);

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _ProfileModalContent(
      member: member,
      allowedRoles: allowed,
      onRoleChanged: (newRole) async {
        await updateMemberRole(member.id, newRole);
        ref.invalidate(allMembersProvider);
      },
    ),
  );
}

class _ProfileModalContent extends StatefulWidget {
  const _ProfileModalContent({
    required this.member,
    required this.allowedRoles,
    required this.onRoleChanged,
  });

  final MemberProfile member;
  final List<AppRole>? allowedRoles;
  final Future<void> Function(AppRole) onRoleChanged;

  @override
  State<_ProfileModalContent> createState() => _ProfileModalContentState();
}

class _ProfileModalContentState extends State<_ProfileModalContent> {
  late AppRole _selectedRole;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.member.role;
  }

  Future<void> _save(AppRole newRole) async {
    setState(() => _saving = true);
    try {
      await widget.onRoleChanged(newRole);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text('Failed to update role: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final member = widget.member;
    final canEdit = widget.allowedRoles != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 40,
            backgroundImage: member.avatarUrl != null
                ? NetworkImage(member.avatarUrl!)
                : null,
            child: member.avatarUrl == null
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            member.nickname,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (canEdit)
            DropdownButton<AppRole>(
              value: _selectedRole,
              underline: const SizedBox.shrink(),
              onChanged: _saving
                  ? null
                  : (role) {
                      if (role != null) setState(() => _selectedRole = role);
                    },
              items: widget.allowedRoles!
                  .map(
                    (r) =>
                        DropdownMenuItem(value: r, child: Text(r.displayLabel)),
                  )
                  .toList(),
            )
          else
            Chip(label: Text(member.role.displayLabel)),
          const SizedBox(height: 16),
          _InfoRow(label: 'Email', value: member.email),
          _InfoRow(
            label: 'Signed up',
            value: member.createdAt != null
                ? _formatDate(member.createdAt!)
                : '—',
          ),
          _InfoRow(
            label: 'Last login',
            value: member.lastSeenAt != null
                ? _formatDateTime(member.lastSeenAt!)
                : '—',
          ),
          if (canEdit && _selectedRole != member.role) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : () => _save(_selectedRole),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
