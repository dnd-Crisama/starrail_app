import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../message/presentation/widgets/user_profile_modal.dart';
import '../../domain/entities/permission.dart';
import '../../domain/entities/role_entity.dart';
import '../providers/server_member_provider.dart';
import '../providers/role_provider.dart';
import '../providers/server_provider.dart';

class ServerMemberListPanel extends ConsumerWidget {
  final String serverId;
  final bool isMobile;

  const ServerMemberListPanel({
    super.key,
    required this.serverId,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedMembersAsync = ref.watch(
      groupedServerMembersProvider(serverId),
    );

    return Container(
      width: isMobile
          ? null
          : 240, // 240px là width chuẩn của Discord member list trên desktop
      color: AppColors.bgSecondary,
      child: groupedMembersAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(
              child: Text(
                'Không có thành viên',
                style: AppTextStyles.textMutedSmall,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildGroupHeader(group.title, group.members.length),
                  ...group.members.map((memberWithProfile) {
                    return _buildMemberItem(
                      context,
                      ref,
                      memberWithProfile,
                      memberWithProfile.profile,
                      group.color,
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.brand,
            strokeWidth: 2,
          ),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Lỗi: $err',
            style: AppTextStyles.textMutedSmall,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        '$title — $count',
        style: AppTextStyles.textMutedSmall.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMemberItem(
    BuildContext context,
    WidgetRef ref,
    MemberWithProfile memberWithProfile,
    UserEntity profile,
    Color? roleColor,
  ) {
    // Nếu status là offline, làm mờ avatar và tên
    final isOffline = profile.status == UserStatus.offline;
    final opacity = isOffline ? 0.5 : 1.0;
    final currentUserId = ref.watch(
      authNotifierProvider.select((state) => state.user?.uid),
    );
    final serversAsync = ref.watch(userServersStreamProvider);
    final rolesAsync = ref.watch(serverRolesStreamProvider(serverId));
    final ownerId = serversAsync.maybeWhen(
      data: (servers) => servers
          .where((server) => server.serverId == serverId)
          .firstOrNull
          ?.ownerId,
      orElse: () => null,
    );
    final canKickAsync = currentUserId == null
        ? const AsyncValue.data(false)
        : ref.watch(
            hasPermissionProvider((
              serverId: serverId,
              userId: currentUserId,
              permission: Permission.kickMembers,
            )),
          );
    final canKickTarget = canKickAsync.maybeWhen(
      data: (canKick) =>
          canKick &&
          currentUserId != null &&
          memberWithProfile.member.userId != currentUserId &&
          memberWithProfile.member.userId != ownerId,
      orElse: () => false,
    );

    return InkWell(
      onTap: () {
        final List<RoleEntity> memberRoles = rolesAsync.maybeWhen(
          data: (roles) => roles
              .where(
                (role) =>
                    memberWithProfile.member.roleIds.contains(role.roleId),
              )
              .toList(),
          orElse: () => const [],
        );
        UserProfileModal.show(
          context,
          user: profile,
          serverRoles: memberRoles,
          isServerOwner: memberWithProfile.member.userId == ownerId,
        );
      },
      hoverColor: AppColors.bgModifierHover,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Opacity(
          opacity: opacity,
          child: Row(
            children: [
              _buildAvatarWithStatus(profile),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  profile.username,
                  style: TextStyle(
                    color: roleColor ?? AppColors.textNormal,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canKickTarget)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                  tooltip: 'Tùy chọn thành viên',
                  color: AppColors.bgTertiary,
                  onSelected: (value) async {
                    if (value != 'kick') return;
                    await _confirmKickMember(
                      context,
                      ref,
                      memberWithProfile.member.userId,
                      profile.username,
                    );
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'kick',
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_remove_outlined,
                            color: AppColors.statusDnd,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Đá khỏi server',
                            style: TextStyle(color: AppColors.statusDnd),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmKickMember(
    BuildContext context,
    WidgetRef ref,
    String targetUserId,
    String username,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: const Text(
          'Đá thành viên',
          style: TextStyle(color: AppColors.textNormal),
        ),
        content: Text(
          'Bạn có chắc muốn đá $username khỏi server này?',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Đá',
              style: TextStyle(color: AppColors.statusDnd),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final success = await ref
        .read(serverSettingsNotifierProvider.notifier)
        .kickMember(serverId: serverId, targetUserId: targetUserId);
    if (!context.mounted) return;

    final message = success
        ? 'Đã đá $username khỏi server'
        : ref.read(serverSettingsNotifierProvider).errorMessage ??
              'Không thể đá thành viên';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.statusOnline : AppColors.statusDnd,
      ),
    );
  }

  Widget _buildAvatarWithStatus(UserEntity profile) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AppAvatar(
            imageUrl: profile.avatarUrl,
            displayName: profile.username,
            size: 32,
            textStyle: const TextStyle(
              color: AppColors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Status indicator
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: AppColors.bgSecondary, // Viền trùng màu nền
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _getStatusColor(profile.status),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.online:
        return AppColors.statusOnline;
      case UserStatus.idle:
        return AppColors.statusIdle;
      case UserStatus.dnd:
        return AppColors.statusDnd;
      case UserStatus.offline:
      default:
        return AppColors.statusOffline;
    }
  }
}
