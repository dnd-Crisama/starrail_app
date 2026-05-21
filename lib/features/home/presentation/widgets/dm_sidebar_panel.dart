import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../friend/presentation/providers/dm_provider.dart';
import '../../../friend/presentation/providers/friend_provider.dart';

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
                  'TIN NHAN TRUC TIEP',
                  style: AppTextStyles.textMuted.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Tooltip(
                message: 'Tao nhom DM',
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
            error: (e, _) => Center(
              child: Text('$e', style: AppTextStyles.textMuted),
            ),
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
                          'Chua co cuoc tro chuyen',
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
          label: 'Ban be',
          onTap: () => context.push(AppConstants.friendsPath),
        ),
        _buildNavItem(
          context,
          icon: Icons.person_add_outlined,
          label: 'Them ban',
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
    final groupNameController = TextEditingController();
    final friendsAsync = ref.read(friendsStreamProvider);

    final friends = friendsAsync.maybeWhen(
      data: (list) => list,
      orElse: () => [],
    );

    final selectedIds = <String>{};
    final dmNotifier = ref.read(dmChatNotifierProvider.notifier);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.bgSecondary,
            title: const Text(
              'Tao nhom DM',
              style: AppTextStyles.headerPrimary,
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: groupNameController,
                    style: AppTextStyles.textNormal,
                    decoration: const InputDecoration(
                      hintText: 'Ten nhom (bat buoc)',
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (friends.isEmpty)
                    const Text(
                      'Chua co ban be de them vao nhom',
                      style: AppTextStyles.textMuted,
                    )
                  else ...[
                    Text(
                      'Chon thanh vien:',
                      style: AppTextStyles.textMuted.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: friends.length,
                        itemBuilder: (_, i) {
                          final otherUserId =
                              friends[i].otherUserId(currentUserId);
                          return Consumer(
                            builder: (_, ref, __) {
                              final userAsync = ref.watch(
                                userProfileProvider(otherUserId),
                              );
                              return userAsync.maybeWhen(
                                data: (user) => CheckboxListTile(
                                  value: selectedIds.contains(otherUserId),
                                  activeColor: AppColors.brand,
                                  title: Text(
                                    user?.username ?? otherUserId,
                                    style: AppTextStyles.textNormal,
                                  ),
                                  onChanged: (checked) {
                                    setDialogState(() {
                                      if (checked == true) {
                                        selectedIds.add(otherUserId);
                                      } else {
                                        selectedIds.remove(otherUserId);
                                      }
                                    });
                                  },
                                ),
                                orElse: () => const SizedBox.shrink(),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Huy',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                ),
                onPressed: selectedIds.isEmpty ||
                        groupNameController.text.trim().isEmpty
                    ? null
                    : () async {
                        Navigator.of(ctx).pop();
                        final chat = await dmNotifier.createGroupDm(
                          participantIds: selectedIds.toList(),
                          name: groupNameController.text.trim(),
                        );
                        if (chat != null && context.mounted) {
                          onChatSelectedCallback(chat.chatId);
                        }
                      },
                child: const Text('Tao nhom'),
              ),
            ],
          );
        },
      ),
    );

    groupNameController.dispose();
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
    if (chat.isGroupDm) {
      return _buildTile(
        context,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.bgTertiary,
          backgroundImage: chat.iconUrl != null && chat.iconUrl!.isNotEmpty
              ? NetworkImage(chat.iconUrl!)
              : null,
          child: chat.iconUrl == null || chat.iconUrl!.isEmpty
              ? const Icon(Icons.group, size: 16, color: AppColors.textMuted)
              : null,
        ),
        title: chat.name.isNotEmpty ? chat.name : 'Nhom DM',
        subtitle: chat.lastMessagePreview,
      );
    }

    final otherUserId = chat.otherParticipantId(currentUserId);
    final userAsync = ref.watch(userProfileProvider(otherUserId));

    return userAsync.maybeWhen(
      data: (user) => _buildTile(
        context,
        leading: _AvatarWithStatus(
          username: user?.username ?? otherUserId,
          avatarUrl: user?.avatarUrl ?? '',
          status: user?.status ?? UserStatus.offline,
        ),
        title: user?.username ?? otherUserId,
        subtitle: chat.lastMessagePreview,
      ),
      orElse: () => _buildTile(
        context,
        leading: const CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.bgTertiary,
        ),
        title: otherUserId,
        subtitle: '',
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required Widget leading,
    required String title,
    required String subtitle,
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
              ],
            ),
          ),
        ),
      ),
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
