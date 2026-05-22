import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../friend/domain/entities/friendship_entity.dart';
import '../../../friend/presentation/providers/dm_provider.dart';
import '../../../friend/presentation/providers/friend_provider.dart';
import '../../../home/presentation/providers/home_provider.dart';

/// Discord-style profile popup khi click vào avatar hoặc tên user khác
class UserProfileModal extends ConsumerWidget {
  final UserEntity user;
  final int mutualServers;
  final int mutualFriends;

  const UserProfileModal({
    super.key,
    required this.user,
    this.mutualServers = 0,
    this.mutualFriends = 0,
  });

  /// Hiển thị modal dạng dialog
  static Future<void> show(
    BuildContext context, {
    required UserEntity user,
    int mutualServers = 0,
    int mutualFriends = 0,
  }) {
    return showDialog(
      context: context,
      barrierColor: AppColors.scrim,
      builder: (_) => UserProfileModal(
        user: user,
        mutualServers: mutualServers,
        mutualFriends: mutualFriends,
      ),
    );
  }

  /// Fetch user data từ Firestore rồi hiển thị modal
  static Future<void> showFromUid(
    BuildContext context, {
    required String uid,
  }) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final user = UserEntity(
        uid: uid,
        username: data['username'] as String? ?? 'Người dùng',
        email: data['email'] as String? ?? '',
        avatarUrl: data['avatarUrl'] as String? ?? '',
        bio: data['bio'] as String? ?? '',
        status: _parseStatus(data['status'] as String?),
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt:
            (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastSeenAt:
            (data['lastSeenAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

      if (context.mounted) {
        show(context, user: user);
      }
    } catch (_) {
      // Silent fail — không hiển thị gì nếu không lấy được data
    }
  }

  static UserStatus _parseStatus(String? statusStr) {
    switch (statusStr?.toUpperCase()) {
      case 'ONLINE':
        return UserStatus.online;
      case 'IDLE':
        return UserStatus.idle;
      case 'DND':
        return UserStatus.dnd;
      case 'INVISIBLE':
        return UserStatus.invisible;
      default:
        return UserStatus.offline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authNotifierProvider).user?.uid ?? '';
    final isSelf = currentUserId == user.uid;

    return Center(
      child: Container(
        width: 360,
        constraints: const BoxConstraints(maxHeight: 480),
        decoration: BoxDecoration(
          color: AppColors.bgFloating,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Banner + Avatar section
            _buildBannerWithAvatar(),
            // User info section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username
                  Text(
                    user.username,
                    style: AppTextStyles.headerPrimary.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 2),
                  // Username + status
                  Row(
                    children: [
                      Text(
                        user.username,
                        style: AppTextStyles.textMutedSmall.copyWith(
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildStatusDot(size: 8),
                      const SizedBox(width: 4),
                      Text(
                        _statusLabel,
                        style: AppTextStyles.textMutedSmall.copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  // Mutual info
                  if (mutualFriends > 0 || mutualServers > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '$mutualFriends Bạn chung • $mutualServers Máy chủ chung',
                      style: AppTextStyles.textMutedSmall.copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (!isSelf) ...[
                    const SizedBox(height: 14),
                    _buildActionButtons(context, ref, currentUserId),
                  ],
                  // Bio
                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.bgModifierHover,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VỀ BẢN THÂN',
                            style: AppTextStyles.header4.copyWith(
                              fontSize: 10,
                              color: AppColors.textNormal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.bio,
                            style: AppTextStyles.bodySecondary.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Created at
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tham gia ngày ${_formatDate(user.createdAt)}',
                        style: AppTextStyles.textMutedSmall.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    String currentUserId,
  ) {
    final friendship = _relationshipWith(ref, currentUserId);
    final isFriend = friendship?.status == FriendshipStatus.accepted;
    final isPending = friendship?.status == FriendshipStatus.pending;
    final isIncoming = isPending && friendship?.requesterId != currentUserId;
    final friendActionState = ref.watch(friendActionNotifierProvider);
    final dmState = ref.watch(dmChatNotifierProvider);

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: _friendButton(
              context: context,
              ref: ref,
              friendship: friendship,
              isFriend: isFriend,
              isPending: isPending,
              isIncoming: isIncoming,
              isLoading: friendActionState.isLoading,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 36,
            child: FilledButton.icon(
              onPressed: dmState.isLoading
                  ? null
                  : () => _openDirectMessage(context, ref),
              icon: dmState.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chat_bubble_outline_rounded, size: 17),
              label: const Text('DM'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _friendButton({
    required BuildContext context,
    required WidgetRef ref,
    required FriendshipEntity? friendship,
    required bool isFriend,
    required bool isPending,
    required bool isIncoming,
    required bool isLoading,
  }) {
    if (isFriend) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_rounded, size: 18),
        label: const Text('Friend'),
        style: OutlinedButton.styleFrom(
          disabledForegroundColor: AppColors.statusOnline,
          side: const BorderSide(color: AppColors.statusOnline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      );
    }

    if (isIncoming && friendship != null) {
      return FilledButton.icon(
        onPressed: isLoading
            ? null
            : () => _acceptFriendRequest(context, ref, friendship.friendshipId),
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.person_add_alt_1_rounded, size: 18),
        label: const Text('Accept'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      );
    }

    if (isPending) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.schedule_rounded, size: 18),
        label: const Text('Pending'),
        style: OutlinedButton.styleFrom(
          disabledForegroundColor: AppColors.textMuted,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: isLoading ? null : () => _sendFriendRequest(context, ref),
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.person_add_alt_1_rounded, size: 18),
      label: const Text('Add Friend'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }

  FriendshipEntity? _relationshipWith(WidgetRef ref, String currentUserId) {
    final allRelationships = [
      ...(ref.watch(friendsStreamProvider).value ?? const <FriendshipEntity>[]),
      ...(ref.watch(incomingRequestsStreamProvider).value ??
          const <FriendshipEntity>[]),
      ...(ref.watch(outgoingRequestsStreamProvider).value ??
          const <FriendshipEntity>[]),
    ];

    for (final friendship in allRelationships) {
      final isSamePair =
          (friendship.user1Id == currentUserId &&
              friendship.user2Id == user.uid) ||
          (friendship.user2Id == currentUserId &&
              friendship.user1Id == user.uid);
      if (isSamePair) return friendship;
    }

    return null;
  }

  Future<void> _sendFriendRequest(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(friendActionNotifierProvider.notifier)
        .sendFriendRequest(user.uid);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Friend request sent' : 'Could not send request'),
        backgroundColor: ok ? AppColors.green : AppColors.red,
      ),
    );
  }

  Future<void> _acceptFriendRequest(
    BuildContext context,
    WidgetRef ref,
    String friendshipId,
  ) async {
    final ok = await ref
        .read(friendActionNotifierProvider.notifier)
        .acceptFriendRequest(friendshipId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Friend request accepted' : 'Could not accept request',
        ),
        backgroundColor: ok ? AppColors.green : AppColors.red,
      ),
    );
  }

  Future<void> _openDirectMessage(BuildContext context, WidgetRef ref) async {
    final chatId = await ref
        .read(dmChatNotifierProvider.notifier)
        .openDmWith(user.uid);
    if (chatId == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open direct message'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    ref.read(selectedServerIdProvider.notifier).state = null;
    ref.read(selectedChannelIdProvider.notifier).state = null;
    ref.read(selectedDmChatIdProvider.notifier).state = chatId;
    ref.read(selectedServerNameProvider.notifier).state = 'Direct Messages';

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildBannerWithAvatar() {
    return SizedBox(
      height: 124,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Banner background — gradient pattern (Discord-style)
          Container(
            height: 96,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.brand,
                  AppColors.brandActive,
                  Color(0xFF5865F2),
                ],
              ),
            ),
          ),
          // Avatar — positioned overlapping banner
          Positioned(
            left: 20,
            bottom: 10,
            child: AppAvatar(
              imageUrl: user.avatarUrl,
              displayName: user.username,
              size: 76,
              backgroundColor: AppColors.bgTertiary,
              textStyle: const TextStyle(
                color: AppColors.white,
                fontSize: 30,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Status dot on avatar
          Positioned(
            left: 82,
            bottom: 14,
            child: _buildStatusDot(size: 16, hasBorder: true),
          ),
        ],
      ),
    );
  }

  Widget buildInitialAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.brand,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
        style: TextStyle(
          color: AppColors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusDot({double size = 8, bool hasBorder = false}) {
    final color = _statusColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: hasBorder
            ? Border.all(color: AppColors.bgFloating, width: 3)
            : null,
      ),
    );
  }

  Color get _statusColor {
    switch (user.status) {
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

  String get _statusLabel {
    switch (user.status) {
      case UserStatus.online:
        return 'Trực tuyến';
      case UserStatus.idle:
        return 'Chờ đợi';
      case UserStatus.dnd:
        return 'Không làm phiền';
      case UserStatus.invisible:
        return 'Vô hình';
      case UserStatus.offline:
        return 'Ngoại tuyến';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      '',
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}
