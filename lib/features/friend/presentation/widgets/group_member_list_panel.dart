// lib/features/friend/presentation/widgets/group_member_list_panel.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/dm_chat_entity.dart';
import '../providers/friend_provider.dart';

class GroupMemberListPanel extends ConsumerWidget {
  final DmChatEntity chat;

  const GroupMemberListPanel({super.key, required this.chat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 240,
      color: AppColors.bgSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Thành viên—X
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'THÀNH VIÊN—${chat.participants.length}',
              style: AppTextStyles.inputLabel.copyWith(
                fontSize: 11,
                letterSpacing: 0.5,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: chat.participants.length,
              itemBuilder: (context, index) {
                final userId = chat.participants[index];
                final isOwner = index == 0; // The first participant is the group creator
                return _MemberTile(userId: userId, isOwner: isOwner);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  final String userId;
  final bool isOwner;

  const _MemberTile({required this.userId, required this.isOwner});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(userId));

    return userAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          children: [
            CircleAvatar(radius: 16, backgroundColor: AppColors.bgTertiary),
            SizedBox(width: 12),
            Expanded(child: SizedBox(height: 12)),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              // Avatar with status indicator
              _AvatarWithStatus(
                username: user.username,
                avatarUrl: user.avatarUrl,
                status: user.status,
              ),
              const SizedBox(width: 12),
              // Member details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.username,
                            style: AppTextStyles.textNormal.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textNormal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOwner) ...[
                          const SizedBox(width: 4),
                          const Tooltip(
                            message: 'Trưởng nhóm',
                            child: Icon(
                              Icons.workspace_premium,
                              color: Colors.amber,
                              size: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (user.bio.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.bio,
                        style: AppTextStyles.textMuted.copyWith(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AvatarWithStatus extends StatelessWidget {
  final String username;
  final String avatarUrl;
  final UserStatus status;

  const _AvatarWithStatus({
    required this.username,
    required this.avatarUrl,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.bgTertiary,
            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: AppTextStyles.labelPrimary.copyWith(fontSize: 12),
                  )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _statusColor(status),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bgSecondary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(UserStatus status) {
    switch (status) {
      case UserStatus.online:
        return AppColors.statusOnline;
      case UserStatus.idle:
        return AppColors.statusIdle;
      case UserStatus.dnd:
        return AppColors.statusDnd;
      case UserStatus.invisible:
      case UserStatus.offline:
        return AppColors.statusOffline;
    }
  }
}
