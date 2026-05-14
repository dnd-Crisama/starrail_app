// lib/features/friend/presentation/widgets/dm_message_bubble.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/dm_message_entity.dart';

/// Widget hiển thị một tin nhắn trong DM chat.
class DmMessageBubble extends StatelessWidget {
  final DmMessageEntity message;
  final bool isCurrentUser;
  final String senderName;
  final String senderAvatarUrl;
  final bool showSenderName;
  final bool showAvatar;

  /// Callback khi nhấn giữ để xóa (chỉ sender)
  final VoidCallback? onDelete;

  const DmMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.senderName,
    this.senderAvatarUrl = '',
    this.showSenderName = true,
    this.showAvatar = true,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) {
      return _buildDeletedMessage();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            showAvatar ? _buildAvatar() : const SizedBox(width: 32),
            const SizedBox(width: 8),
          ],
          Flexible(child: _buildBubble(context)),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            showAvatar ? _buildAvatar() : const SizedBox(width: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.bgTertiary,
      backgroundImage: senderAvatarUrl.isNotEmpty
          ? NetworkImage(senderAvatarUrl)
          : null,
      child: senderAvatarUrl.isEmpty
          ? Text(
              senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textNormal,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  Widget _buildBubble(BuildContext context) {
    return GestureDetector(
      onLongPress: isCurrentUser && onDelete != null
          ? () => _showDeleteDialog(context)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isCurrentUser ? AppColors.brand : AppColors.bgTertiary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
            bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isCurrentUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCurrentUser && showSenderName)
              Text(
                senderName,
                style: AppTextStyles.textMuted.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brand,
                ),
              ),
            if (!isCurrentUser && showSenderName) const SizedBox(height: 2),
            // Reply preview nếu có
            if (message.replyToMessageId != null)
              _buildReplyPreview(),
            Text(
              message.content,
              style: AppTextStyles.textNormal.copyWith(
                color: isCurrentUser
                    ? Colors.white
                    : AppColors.textNormal,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: AppTextStyles.textMuted.copyWith(fontSize: 10),
                ),
                if (message.isEdited) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(đã sửa)',
                    style: AppTextStyles.textMuted.copyWith(fontSize: 10),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(
            color: isCurrentUser ? Colors.white38 : AppColors.brand,
            width: 2,
          ),
        ),
      ),
      child: Text(
        'Trả lời tin nhắn',
        style: AppTextStyles.textMuted.copyWith(fontSize: 11),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDeletedMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bgTertiary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.block,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  'Tin nhắn đã bị xóa',
                  style: AppTextStyles.textMuted.copyWith(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: const Text(
          'Xóa tin nhắn',
          style: AppTextStyles.headerPrimary,
        ),
        content: const Text(
          'Bạn có chắc muốn xóa tin nhắn này không?',
          style: AppTextStyles.textNormal,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete?.call();
            },
            child: const Text(
              'Xóa',
              style: TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }
}
