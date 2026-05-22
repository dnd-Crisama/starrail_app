// lib/features/friend/presentation/widgets/dm_chat_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/dm_chat_entity.dart';
import '../providers/friend_provider.dart';
import '../providers/dm_provider.dart';

/// Widget hiển thị một cuộc hội thoại DM trong danh sách.
class DmChatTile extends ConsumerWidget {
  final DmChatEntity chat;
  final bool isSelected;
  final VoidCallback? onTap;

  const DmChatTile({
    super.key,
    required this.chat,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authNotifierProvider).user?.uid ?? '';
    final isOwnerOr1to1 =
        !chat.isGroupDm ||
        (chat.participants.isNotEmpty &&
            chat.participants.first == currentUserId);

    if (chat.isGroupDm) {
      return _buildGroupTile(context, ref, isOwnerOr1to1);
    }

    // DM 1-1: load thông tin người kia
    final otherUserId = chat.otherParticipantId(currentUserId);
    final userAsync = ref.watch(userProfileProvider(otherUserId));

    return userAsync.when(
      loading: () => _buildLoadingTile(),
      error: (_, __) => _buildErrorTile(),
      data: (user) {
        final displayName = user?.username ?? 'Người dùng';
        final avatarUrl = user?.avatarUrl ?? '';
        return _buildTile(
          context: context,
          ref: ref,
          displayName: displayName,
          avatarUrl: avatarUrl,
          isGroup: false,
          showDelete: isOwnerOr1to1,
        );
      },
    );
  }

  Widget _buildGroupTile(BuildContext context, WidgetRef ref, bool showDelete) {
    return _buildTile(
      context: context,
      ref: ref,
      displayName: chat.name.isNotEmpty ? chat.name : 'Group DM',
      avatarUrl: chat.iconUrl ?? '',
      isGroup: true,
      showDelete: showDelete,
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required WidgetRef ref,
    required String displayName,
    required String avatarUrl,
    required bool isGroup,
    required bool showDelete,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.bgModifierSelected : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        onTap: onTap,
        leading: AppAvatar(
          imageUrl: avatarUrl,
          displayName: displayName,
          size: 36,
          backgroundColor: AppColors.bgTertiary,
          fallbackIcon: Icon(
            isGroup ? Icons.group : Icons.person,
            color: AppColors.textMuted,
            size: 18,
          ),
        ),
        title: Text(
          displayName,
          style: AppTextStyles.labelPrimary.copyWith(
            color: isSelected
                ? AppColors.textNormal
                : AppColors.interactiveNormal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: chat.lastMessagePreview.isNotEmpty
            ? Text(
                chat.lastMessagePreview,
                style: AppTextStyles.textMuted.copyWith(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: showDelete
            ? IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                onPressed: () => _showDeleteWarningDialog(context, ref),
                splashRadius: 16,
                tooltip: 'Xóa cuộc trò chuyện',
              )
            : null,
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

  Widget _buildLoadingTile() {
    return ListTile(
      leading: const CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.bgTertiary,
      ),
      title: Container(height: 12, width: 80, color: AppColors.bgTertiary),
    );
  }

  Widget _buildErrorTile() {
    return const ListTile(
      leading: CircleAvatar(child: Icon(Icons.error_outline)),
      title: Text('Lỗi tải dữ liệu'),
    );
  }
}
