import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/message_entity.dart';

/// Hiển thị attachment trong tin nhắn
class AttachmentDisplay extends StatelessWidget {
  final List<AttachmentEntity> attachments;

  const AttachmentDisplay({super.key, required this.attachments});

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: attachments.map((attachment) {
        if (attachment.isImage) {
          return _buildImageAttachment(attachment);
        }
        return _buildFileAttachment(attachment);
      }).toList(),
    );
  }

  Widget _buildImageAttachment(AttachmentEntity attachment) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
          child: Image.network(
            attachment.url,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => _buildImageError(attachment),
            loadingBuilder: (_, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 200,
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.bgModifierHover,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                    color: AppColors.brand,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildImageError(AttachmentEntity attachment) {
    return Container(
      width: 200,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.bgModifierHover,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image, color: AppColors.textMuted, size: 32),
          const SizedBox(height: 4),
          Text('Không thể tải ảnh', style: AppTextStyles.textMutedSmall),
        ],
      ),
    );
  }

  Widget _buildFileAttachment(AttachmentEntity attachment) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.bgModifierHover,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _fileIcon(attachment.mimeType),
              color: AppColors.brand,
              size: 24,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.fileName,
                    style: AppTextStyles.textLink.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatFileSize(attachment.size),
                    style: AppTextStyles.textMutedSmall.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _fileIcon(String mimeType) {
    if (mimeType.startsWith('video/')) return Icons.videocam;
    if (mimeType.startsWith('audio/')) return Icons.audiotrack;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('zip') || mimeType.contains('rar'))
      return Icons.archive;
    return Icons.insert_drive_file;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
