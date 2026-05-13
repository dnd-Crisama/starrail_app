import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Dialog xác nhận xóa tin nhắn
class DeleteConfirmDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const DeleteConfirmDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgFloating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.red,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            'Xóa tin nhắn',
            style: AppTextStyles.header3.copyWith(
              color: AppColors.headerPrimary,
            ),
          ),
        ],
      ),
      content: const Text(
        'Bạn có chắc muốn xóa tin nhắn này không? Hành động này không thể hoàn tác.',
        style: AppTextStyles.bodySecondary,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textMuted,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: Text(
            'Hủy',
            style: AppTextStyles.bodySecondary.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            onConfirm();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.red,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: const Text('Xóa', style: AppTextStyles.buttonTextSmall),
        ),
      ],
    );
  }
}
