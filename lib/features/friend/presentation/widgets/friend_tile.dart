// lib/features/friend/presentation/widgets/friend_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/friendship_entity.dart';
import '../providers/friend_provider.dart';

/// Widget hiển thị một bạn bè trong danh sách.
class FriendTile extends ConsumerWidget {
  final FriendshipEntity friendship;
  final String currentUserId;
  final VoidCallback? onOpenDm;
  final VoidCallback? onRemove;
  final VoidCallback? onBlock;

  const FriendTile({
    super.key,
    required this.friendship,
    required this.currentUserId,
    this.onOpenDm,
    this.onRemove,
    this.onBlock,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUserId = friendship.otherUserId(currentUserId);
    final userAsync = ref.watch(userProfileProvider(otherUserId));

    return userAsync.when(
      loading: () => _buildSkeleton(),
      error: (_, __) => _buildError(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        return _buildTile(context, user);
      },
    );
  }

  Widget _buildTile(BuildContext context, UserEntity user) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.bgTertiary,
            backgroundImage: user.avatarUrl.isNotEmpty
                ? NetworkImage(user.avatarUrl)
                : null,
            child: user.avatarUrl.isEmpty
                ? Text(
                    user.username.isNotEmpty
                        ? user.username[0].toUpperCase()
                        : '?',
                    style: AppTextStyles.labelPrimary,
                  )
                : null,
          ),
          // Status indicator
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _statusColor(user.status),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bgSecondary, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Text(user.username, style: AppTextStyles.labelPrimary),
      subtitle: Text(
        _statusText(user.status),
        style: AppTextStyles.textMuted.copyWith(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onOpenDm != null)
            _iconButton(
              icon: Icons.chat_bubble_outline,
              tooltip: 'Nhắn tin',
              onPressed: onOpenDm!,
            ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
            color: AppColors.bgSecondary,
            onSelected: (value) {
              switch (value) {
                case 'remove':
                  onRemove?.call();
                  break;
                case 'block':
                  onBlock?.call();
                  break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'remove',
                child: Text('Xóa bạn', style: TextStyle(color: Colors.red)),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Text(
                  'Chặn',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.bgTertiary,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 18),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListTile(
      leading: CircleAvatar(radius: 20, backgroundColor: AppColors.bgTertiary),
      title: Container(
        height: 14,
        width: 100,
        color: AppColors.bgTertiary,
      ),
    );
  }

  Widget _buildError() {
    return const ListTile(
      leading: CircleAvatar(child: Icon(Icons.person_off)),
      title: Text('Không tải được'),
    );
  }

  Color _statusColor(UserStatus status) {
    switch (status) {
      case UserStatus.online:
        return AppColors.green;
      case UserStatus.idle:
        return AppColors.yellow;
      case UserStatus.dnd:
        return AppColors.red;
      default:
        return AppColors.textMuted;
    }
  }

  String _statusText(UserStatus status) {
    switch (status) {
      case UserStatus.online:
        return 'Online';
      case UserStatus.idle:
        return 'Idle';
      case UserStatus.dnd:
        return 'Không làm phiền';
      case UserStatus.invisible:
        return 'Offline';
      default:
        return 'Offline';
    }
  }
}

/// Widget hiển thị lời mời kết bạn nhận được.
class IncomingRequestTile extends ConsumerWidget {
  final FriendshipEntity friendship;
  final String currentUserId;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const IncomingRequestTile({
    super.key,
    required this.friendship,
    required this.currentUserId,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUserId = friendship.otherUserId(currentUserId);
    final userAsync = ref.watch(userProfileProvider(otherUserId));

    return userAsync.when(
      loading: () => const ListTile(
        leading: CircleAvatar(child: CircularProgressIndicator(strokeWidth: 2)),
        title: Text('Đang tải...'),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.bgTertiary,
            backgroundImage: user.avatarUrl.isNotEmpty
                ? NetworkImage(user.avatarUrl)
                : null,
            child: user.avatarUrl.isEmpty
                ? Text(
                    user.username.isNotEmpty
                        ? user.username[0].toUpperCase()
                        : '?',
                    style: AppTextStyles.labelPrimary,
                  )
                : null,
          ),
          title: Text(user.username, style: AppTextStyles.labelPrimary),
          subtitle: Text(
            'Muốn kết bạn với bạn',
            style: AppTextStyles.textMuted.copyWith(fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nút chấp nhận
              IconButton(
                tooltip: 'Chấp nhận',
                onPressed: onAccept,
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
              // Nút từ chối
              IconButton(
                tooltip: 'Từ chối',
                onPressed: onDecline,
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
