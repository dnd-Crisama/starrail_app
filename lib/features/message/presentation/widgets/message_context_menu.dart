import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/message_entity.dart';

/// Callback khi chọn action trong context menu
enum MessageAction { reply, edit, delete, pin }

/// Danh sách emoji reaction nhanh
const List<String> kQuickReactionEmojis = ['👍', '❤️', '😂', '😮', '😢', '😡'];

/// Menu context khi long-press vào tin nhắn (Discord-style)
class MessageContextMenu extends StatelessWidget {
  final MessageEntity message;
  final bool isOwnMessage;
  final ValueChanged<MessageAction> onAction;
  final VoidCallback onClose;
  final ValueChanged<String>? onQuickReaction;

  const MessageContextMenu({
    super.key,
    required this.message,
    required this.isOwnMessage,
    required this.onAction,
    required this.onClose,
    this.onQuickReaction,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgFloating,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick reaction bar (Discord-style)
            if (onQuickReaction != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: kQuickReactionEmojis.map((emoji) {
                    return InkWell(
                      onTap: () {
                        onQuickReaction!(emoji);
                        onClose();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            // Action items
            _buildItem(
              icon: Icons.reply_rounded,
              label: 'Trả lời',
              onTap: () {
                onClose();
                onAction(MessageAction.reply);
              },
            ),
            if (isOwnMessage && !message.isDeleted)
              _buildItem(
                icon: Icons.edit_rounded,
                label: 'Chỉnh sửa tin nhắn',
                onTap: () {
                  onClose();
                  onAction(MessageAction.edit);
                },
              ),
            _buildItem(
              icon: Icons.copy_rounded,
              label: 'Sao chép nội dung',
              onTap: () {
                onClose();
                // Copy sẽ implement sau
              },
            ),
            _buildItem(
              icon: Icons.delete_outline_rounded,
              label: 'Xóa tin nhắn',
              color: AppColors.red,
              onTap: () {
                onClose();
                onAction(MessageAction.delete);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final effectiveColor = color ?? AppColors.interactiveNormal;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(2),
      hoverColor: AppColors.bgModifierHover,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: effectiveColor),
            const SizedBox(width: 10),
            Text(
              label,
              style: AppTextStyles.bodySecondary.copyWith(
                color: effectiveColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hiển thị context menu dạng overlay tại vị trí long-press
void showMessageContextMenu({
  required BuildContext context,
  required Offset position,
  required MessageEntity message,
  required bool isOwnMessage,
  required ValueChanged<MessageAction> onAction,
  ValueChanged<String>? onQuickReaction,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => _ContextMenuOverlay(
      position: position,
      message: message,
      isOwnMessage: isOwnMessage,
      onAction: onAction,
      onQuickReaction: onQuickReaction,
      onClose: () {
        overlayEntry.remove();
      },
    ),
  );

  overlay.insert(overlayEntry);
}

class _ContextMenuOverlay extends StatefulWidget {
  final Offset position;
  final MessageEntity message;
  final bool isOwnMessage;
  final ValueChanged<MessageAction> onAction;
  final ValueChanged<String>? onQuickReaction;
  final VoidCallback onClose;

  const _ContextMenuOverlay({
    required this.position,
    required this.message,
    required this.isOwnMessage,
    required this.onAction,
    this.onQuickReaction,
    required this.onClose,
  });

  @override
  State<_ContextMenuOverlay> createState() => _ContextMenuOverlayState();
}

class _ContextMenuOverlayState extends State<_ContextMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Định vị menu bên phải vị trí long-press
    final left = (widget.position.dx + 220 > screenSize.width)
        ? screenSize.width - 240
        : widget.position.dx;
    final top = (widget.position.dy + 220 > screenSize.height)
        ? screenSize.height - 240
        : widget.position.dy;

    return Stack(
      children: [
        // Tap anywhere to close
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onClose,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Menu
        Positioned(
          left: left,
          top: top,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: MessageContextMenu(
              message: widget.message,
              isOwnMessage: widget.isOwnMessage,
              onAction: widget.onAction,
              onClose: widget.onClose,
              onQuickReaction: widget.onQuickReaction,
            ),
          ),
        ),
      ],
    );
  }
}
