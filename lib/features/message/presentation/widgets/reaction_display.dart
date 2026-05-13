import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/message_entity.dart';

/// Danh sách emoji reaction mặc định hiển thị khi long-press
class ReactionQuickPicker extends StatelessWidget {
  final ValueChanged<String> onEmojiSelected;

  const ReactionQuickPicker({super.key, required this.onEmojiSelected});

  static const List<String> _defaultEmojis = [
    '👍',
    '❤️',
    '😂',
    '😮',
    '😢',
    '😡',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgFloating,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _defaultEmojis.map((emoji) {
          return InkWell(
            onTap: () => onEmojiSelected(emoji),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Hiển thị reaction đã có dưới tin nhắn (Discord-style pills)
class ReactionDisplay extends StatelessWidget {
  final List<ReactionEntity> reactions;
  final String currentUserId;
  final ValueChanged<String> onReactionTapped;

  const ReactionDisplay({
    super.key,
    required this.reactions,
    required this.currentUserId,
    required this.onReactionTapped,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: reactions.map((reaction) {
        final hasReacted = reaction.hasReacted(currentUserId);
        return GestureDetector(
          onTap: () => onReactionTapped(reaction.emoji),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: hasReacted
                  ? AppColors.brand.withValues(alpha: 0.2)
                  : AppColors.bgModifierHover,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasReacted
                    ? AppColors.brand.withValues(alpha: 0.5)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(reaction.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${reaction.count}',
                  style: AppTextStyles.textMutedSmall.copyWith(
                    fontSize: 11,
                    color: hasReacted ? AppColors.brand : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
