import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../friend/presentation/providers/dm_provider.dart';
import '../../../friend/presentation/providers/friend_provider.dart';
import '../../../friend/presentation/widgets/create_group_dm_dialog.dart';

/// Sidebar hien thi danh sach DM chats va nut tao Group DM.
class DmSidebarPanel extends ConsumerWidget {
  final String? selectedChatId;
  final ValueChanged<String> onChatSelected;

  const DmSidebarPanel({
    super.key,
    required this.selectedChatId,
    required this.onChatSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authNotifierProvider).user?.uid ?? '';
    final chatsAsync = ref.watch(dmChatsStreamProvider);

    return Column(
      children: [
        _buildFriendsNavButton(context),
        const Divider(color: AppColors.divider, height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'TIN NHẮN RIÊNG',
                  style: AppTextStyles.textMuted.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Tooltip(
                message: 'Tạo nhóm DM',
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () => _showCreateGroupDmDialog(
                    context,
                    ref,
                    currentUserId,
                    onChatSelected,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: AppColors.divider, height: 1),
        Expanded(
          child: chatsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) =>
                Center(child: Text('$e', style: AppTextStyles.textMuted)),
            data: (chats) {
              if (chats.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 36,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Chưa có cuộc trò chuyện',
                          style: AppTextStyles.textMuted,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: chats.length,
                itemBuilder: (_, i) {
                  final chat = chats[i];
                  final isSelected = selectedChatId == chat.chatId;
                  return _DmChatSidebarTile(
                    chat: chat,
                    currentUserId: currentUserId,
                    isSelected: isSelected,
                    onTap: () => onChatSelected(chat.chatId),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFriendsNavButton(BuildContext context) {
    return Column(
      children: [
        _buildNavItem(
          context,
          icon: Icons.people_outline,
          label: 'Bạn bè',
          onTap: () => context.push(AppConstants.friendsPath),
        ),
        _buildNavItem(
          context,
          icon: Icons.person_add_outlined,
          label: 'Thêm bạn',
          isHighlight: true,
          onTap: () => context.push(AppConstants.addFriendPath),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isHighlight
                      ? AppColors.green
                      : AppColors.channelDefault,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTextStyles.channelName.copyWith(
                    color: isHighlight ? AppColors.green : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateGroupDmDialog(
    BuildContext context,
    WidgetRef ref,
    String currentUserId,
    ValueChanged<String> onChatSelectedCallback,
  ) async {
    showDialog(
      context: context,
      builder: (ctx) => CreateGroupDmDialog(
        currentUserId: currentUserId,
        onCreateSuccess: (chatId) {
          onChatSelectedCallback(chatId);
        },
      ),
    );
  }
}

class _DmChatSidebarTile extends ConsumerWidget {
  final dynamic chat;
  final String currentUserId;
  final bool isSelected;
  final VoidCallback onTap;

  const _DmChatSidebarTile({
    required this.chat,
    required this.currentUserId,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwnerOr1to1 =
        !chat.isGroupDm ||
        (chat.participants.isNotEmpty &&
            chat.participants.first == currentUserId);

    if (chat.isGroupDm) {
      return _buildTile(
        context,
        ref,
        leading: AppAvatar(
          imageUrl: chat.iconUrl ?? '',
          displayName: chat.name,
          size: 32,
          backgroundColor: AppColors.bgTertiary,
          fallbackIcon: const Icon(
            Icons.group,
            size: 16,
            color: AppColors.textMuted,
          ),
        ),
        title: chat.name.isNotEmpty ? chat.name : 'Nhóm DM',
        subtitle: chat.lastMessagePreview,
        showDelete: isOwnerOr1to1,
      );
    }

    final otherUserId = chat.otherParticipantId(currentUserId);
    final userAsync = ref.watch(userProfileProvider(otherUserId));

    return userAsync.maybeWhen(
      data: (user) => _buildTile(
        context,
        ref,
        leading: _AvatarWithStatus(
          username: user?.username ?? otherUserId,
          avatarUrl: user?.avatarUrl ?? '',
          status: user?.status ?? UserStatus.offline,
        ),
        title: user?.username ?? otherUserId,
        subtitle: chat.lastMessagePreview,
        showDelete: isOwnerOr1to1,
      ),
      orElse: () => _buildTile(
        context,
        ref,
        leading: const CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.bgTertiary,
        ),
        title: otherUserId,
        subtitle: '',
        showDelete: isOwnerOr1to1,
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    WidgetRef ref, {
    required Widget leading,
    required String title,
    required String subtitle,
    required bool showDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: isSelected ? AppColors.bgModifierSelected : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: isSelected
                            ? AppTextStyles.channelNameSelected
                            : AppTextStyles.channelName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: AppTextStyles.textMuted.copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (showDelete)
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => _showDeleteWarningDialog(context, ref),
                    splashRadius: 14,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Xóa cuộc trò chuyện',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteWarningDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppColors.bgSecondary,
          title: const Text(
            'Xóa cuộc hội thoại',
            style: AppTextStyles.headerPrimary,
          ),
          content: const Text(
            'Bạn có chắc chắn muốn xóa cuộc trò chuyện này? Tất cả tin nhắn trong cuộc trò chuyện này sẽ bị xóa vĩnh viễn và không thể khôi phục.',
            style: AppTextStyles.textNormal,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Hủy bỏ',
                style: TextStyle(color: AppColors.textMuted),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text('Xóa'),
              onPressed: () async {
                Navigator.of(ctx).pop(); // close warning dialog first
                final success = await ref
                    .read(dmChatNotifierProvider.notifier)
                    .deleteDmChat(chat.chatId);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa cuộc hội thoại thành công'),
                      backgroundColor: AppColors.brand,
                    ),
                  );
                }
              },
            ),
          ],
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
      width: 36,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AppAvatar(
            imageUrl: avatarUrl,
            displayName: username,
            size: 32,
            backgroundColor: AppColors.bgTertiary,
            textStyle: AppTextStyles.labelPrimary.copyWith(fontSize: 12),
          ),
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: 11,
              height: 11,
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
