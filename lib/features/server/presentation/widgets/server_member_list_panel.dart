import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../providers/server_member_provider.dart';

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
    UserEntity profile,
    Color? roleColor,
  ) {
    // Nếu status là offline, làm mờ avatar và tên
    final isOffline = profile.status == UserStatus.offline;
    final opacity = isOffline ? 0.5 : 1.0;

    return InkWell(
      onTap: () {
        // Tương lai: Show User Profile Modal
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
            ],
          ),
        ),
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
              decoration: BoxDecoration(
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
