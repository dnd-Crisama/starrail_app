import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/message_entity.dart';
import '../providers/message_provider.dart';

/// Thanh hiển thị tin nhắn đang reply phía trên input bar (Discord-style)
class ReplyBar extends ConsumerWidget {
  final String currentUserId;
  final VoidCallback? onNavigateToMessage;

  const ReplyBar({
    super.key,
    required this.currentUserId,
    this.onNavigateToMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final replyingTo = ref.watch(replyingToProvider);
    if (replyingTo == null) return const SizedBox.shrink();

    final isReplyingToSelf = replyingTo.senderId == currentUserId;
    final hasAttachments = replyingTo.attachments.isNotEmpty;
    final hasContent = replyingTo.content.isNotEmpty;

    // Xác định nội dung preview
    String previewText;
    IconData? previewIcon;

    if (replyingTo.isDeleted) {
      previewText = 'Tin nhắn gốc đã bị xóa';
      previewIcon = Icons.delete_outline;
    } else if (!hasContent && hasAttachments) {
      // Chỉ có attachment → hiện gợi ý click
      final attachmentType = _attachmentTypeLabel(replyingTo.attachments);
      previewText = 'Nhấn để xem $attachmentType';
      previewIcon = _attachmentIcon(replyingTo.attachments.first.kind);
    } else if (hasContent && hasAttachments) {
      // Có cả text và attachment
      previewText = replyingTo.content;
      previewIcon = Icons.attach_file;
    } else {
      previewText = replyingTo.content;
      previewIcon = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.bgModifierHover,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(left: BorderSide(color: AppColors.brand, width: 3)),
      ),
      child: Row(
        children: [
          // Icon trả lời
          Icon(Icons.reply, size: 16, color: AppColors.brand),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: !replyingTo.isDeleted ? onNavigateToMessage : null,
              child: MouseRegion(
                cursor: !replyingTo.isDeleted
                    ? SystemMouseCursors.click
                    : MouseCursor.defer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isReplyingToSelf ? 'Đang trả lời bạn' : 'Đang trả lời',
                      style: AppTextStyles.textMutedSmall.copyWith(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (previewIcon != null) ...[
                          Icon(
                            previewIcon,
                            size: 12,
                            color:
                                (!hasContent && hasAttachments) &&
                                    !replyingTo.isDeleted
                                ? AppColors.textLink
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            previewText,
                            style: AppTextStyles.textMutedSmall.copyWith(
                              color:
                                  (!hasContent && hasAttachments) &&
                                      !replyingTo.isDeleted
                                  ? AppColors.textLink
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close,
              size: 16,
              color: AppColors.interactiveNormal,
            ),
            onPressed: () {
              ref.read(replyingToProvider.notifier).state = null;
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Xác định label cho loại attachment
  String _attachmentTypeLabel(List<AttachmentEntity> attachments) {
    if (attachments.isEmpty) return 'tệp đính kèm';
    final kinds = attachments.map((a) => a.kind).toSet();
    if (kinds.contains('IMAGE')) return 'hình ảnh';
    if (kinds.contains('VIDEO')) return 'video';
    if (kinds.contains('AUDIO')) return 'âm thanh';
    return 'tệp đính kèm';
  }

  /// Icon tương ứng với loại attachment
  IconData _attachmentIcon(String kind) {
    switch (kind) {
      case 'IMAGE':
        return Icons.image;
      case 'VIDEO':
        return Icons.videocam;
      case 'AUDIO':
        return Icons.audiotrack;
      default:
        return Icons.attach_file;
    }
  }
}
