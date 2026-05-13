import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/message_entity.dart';

/// Hiển thị preview tin nhắn gốc phía trên nội dung tin nhắn reply (Discord-style)
class ReplyPreview extends StatelessWidget {
  final MessageEntity? repliedMessage;
  final String? senderName;
  final String? avatarUrl;
  final VoidCallback? onTap;

  const ReplyPreview({
    super.key,
    required this.repliedMessage,
    this.senderName,
    this.avatarUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (repliedMessage == null) return const SizedBox.shrink();

    final msg = repliedMessage!;
    final hasAttachments = msg.attachments.isNotEmpty;
    final hasContent = msg.content.isNotEmpty;
    final isDeleted = msg.isDeleted;

    // Xác định nội dung hiển thị cho preview
    String previewText;
    IconData? previewIcon;

    if (isDeleted) {
      previewText = 'Tin nhắn gốc đã bị xóa';
      previewIcon = Icons.delete_outline;
    } else if (!hasContent && hasAttachments) {
      // Chỉ có attachment, không có text → hiển thị gợi ý click
      final attachmentType = _attachmentTypeLabel(msg.attachments);
      previewText = 'Nhấn để xem $attachmentType';
      previewIcon = _attachmentIcon(msg.attachments.first.kind);
    } else if (hasContent && hasAttachments) {
      // Có cả text và attachment → hiện text + icon đính kèm
      previewText = msg.content;
      previewIcon = Icons.attach_file;
    } else {
      previewText = msg.content;
      previewIcon = null;
    }

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: !isDeleted ? SystemMouseCursors.click : MouseCursor.defer,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2, right: 4),
          decoration: BoxDecoration(
            color: AppColors.bgModifierHover.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar nhỏ
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      shape: BoxShape.circle,
                      image: avatarUrl != null && avatarUrl!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(avatarUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: (avatarUrl == null || avatarUrl!.isEmpty)
                        ? Text(
                            senderName != null && senderName!.isNotEmpty
                                ? senderName![0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      senderName ?? 'Người dùng',
                      style: AppTextStyles.textMutedSmall.copyWith(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (previewIcon != null) ...[
                      Icon(
                        previewIcon,
                        size: 11,
                        color: (!hasContent && hasAttachments) && !isDeleted
                            ? AppColors.textLink
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        previewText,
                        style: AppTextStyles.textMutedSmall.copyWith(
                          fontSize: 11,
                          color: (!hasContent && hasAttachments) && !isDeleted
                              ? AppColors.textLink
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Xác định label cho loại attachment
  String _attachmentTypeLabel(List<AttachmentEntity> attachments) {
    if (attachments.isEmpty) return 'tệp đính kèm';
    final kinds = attachments.map((a) => a.kind).toSet();
    if (kinds.contains('IMAGE')) {
      return attachments.length > 1 ? 'hình ảnh' : 'hình ảnh';
    }
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
