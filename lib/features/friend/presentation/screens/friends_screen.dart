// lib/features/friend/presentation/screens/friends_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/friendship_entity.dart';
import '../providers/dm_provider.dart';
import '../providers/friend_provider.dart';
import '../widgets/friend_tile.dart';

/// Màn hình quản lý bạn bè giống Discord.
/// Có 3 tab: Online, All Friends, Pending.
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authNotifierProvider).user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        automaticallyImplyLeading: false, // Tự control leading
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textNormal),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppConstants.homePath);
            }
          },
        ),
        title: Row(
          children: [
            const Icon(Icons.people, color: AppColors.textMuted, size: 20),
            const SizedBox(width: 8),
            const Text('Bạn bè', style: AppTextStyles.headerPrimary),
          ],
        ),
        actions: [
          // Nút Thêm bạn
          TextButton.icon(
            onPressed: () => context.push(AppConstants.addFriendPath),
            icon: const Icon(Icons.person_add, color: AppColors.green, size: 18),
            label: const Text(
              'Thêm bạn',
              style: TextStyle(color: AppColors.green),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.brand,
          labelColor: AppColors.textNormal,
          unselectedLabelColor: AppColors.textMuted,
          tabs: [
            Tab(
              child: _tabLabel('Online', friendsStreamProvider),
            ),
            const Tab(text: 'Tất cả'),
            Tab(
              child: _incomingTabLabel(),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OnlineFriendsTab(currentUserId: currentUserId),
          _AllFriendsTab(currentUserId: currentUserId),
          _PendingRequestsTab(currentUserId: currentUserId),
        ],
      ),
    );
  }

  Widget _tabLabel(String text, _) {
    return Text(text);
  }

  Widget _incomingTabLabel() {
    final incomingAsync = ref.watch(incomingRequestsStreamProvider);
    final count = incomingAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Đang chờ'),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Tab: Online Friends ────────────────────────────────────────

class _OnlineFriendsTab extends ConsumerWidget {
  final String currentUserId;
  const _OnlineFriendsTab({required this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineFriends = ref.watch(onlineFriendsProvider);
    final isFriendsLoading = ref.watch(friendsStreamProvider).isLoading;

    if (isFriendsLoading && onlineFriends.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      );
    }

    if (onlineFriends.isEmpty) {
      return _buildEmpty('Không có bạn bè online');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'ONLINE — ${onlineFriends.length}',
            style: AppTextStyles.textMuted.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: onlineFriends.length,
            itemBuilder: (_, i) => _buildFriendTile(
              context,
              ref,
              onlineFriends[i],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFriendTile(
    BuildContext context,
    WidgetRef ref,
    FriendshipEntity friendship,
  ) {
    return FriendTile(
      friendship: friendship,
      currentUserId: currentUserId,
      onOpenDm: () async {
        // Lấy notifier TRƯỚC await để tránh "ref after dispose"
        final notifier = ref.read(dmChatNotifierProvider.notifier);
        final chatId = await notifier.openDmWith(
          friendship.otherUserId(currentUserId),
        );
        if (chatId != null && context.mounted) {
          context.push('${AppConstants.dmChatPath}/$chatId');
        }
      },
      onRemove: () => _confirmRemove(context, ref, friendship.friendshipId),
      onBlock: () => _confirmBlock(
        context,
        ref,
        friendship.otherUserId(currentUserId),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    String friendshipId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: const Text('Xóa bạn bè', style: AppTextStyles.headerPrimary),
        content: const Text(
          'Bạn có chắc muốn xóa người này khỏi danh sách bạn bè?',
          style: AppTextStyles.textNormal,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Lấy notifier TRƯỚC await
      final notifier = ref.read(friendActionNotifierProvider.notifier);
      await notifier.removeFriend(friendshipId);
    }
  }

  Future<void> _confirmBlock(
    BuildContext context,
    WidgetRef ref,
    String targetUserId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: const Text('Chặn người dùng', style: AppTextStyles.headerPrimary),
        content: const Text(
          'Người này sẽ không thể gửi lời mời kết bạn cho bạn nữa.',
          style: AppTextStyles.textNormal,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Chặn', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Lấy notifier TRƯỚC await
      final notifier = ref.read(friendActionNotifierProvider.notifier);
      await notifier.blockUser(targetUserId);
    }
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.textMuted),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Text(error, style: AppTextStyles.textMuted.copyWith(color: AppColors.red)),
    );
  }
}

// ── Tab: All Friends ──────────────────────────────────────────

class _AllFriendsTab extends ConsumerWidget {
  final String currentUserId;
  const _AllFriendsTab({required this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsStreamProvider);

    return friendsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      ),
      error: (e, _) => Center(child: Text('$e', style: AppTextStyles.textMuted)),
      data: (friendships) {
        if (friendships.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.waving_hand, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                const Text('Chưa có bạn bè', style: AppTextStyles.textMuted),
                const SizedBox(height: 8),
                Text(
                  'Nhấn "Thêm bạn" ở góc trên phải để tìm kiếm.',
                  style: AppTextStyles.textMuted.copyWith(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'TẤT CẢ BẠN BÈ — ${friendships.length}',
                style: AppTextStyles.textMuted.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: friendships.length,
                itemBuilder: (_, i) => FriendTile(
                  friendship: friendships[i],
                  currentUserId: currentUserId,
                  onOpenDm: () async {
                    // Cache notifier trước await
                    final dmNotifier = ref.read(dmChatNotifierProvider.notifier);
                    final chatId = await dmNotifier.openDmWith(
                      friendships[i].otherUserId(currentUserId),
                    );
                    if (chatId != null && context.mounted) {
                      context.push('${AppConstants.dmChatPath}/$chatId');
                    }
                  },
                  onRemove: () async {
                    final notifier = ref.read(friendActionNotifierProvider.notifier);
                    await notifier.removeFriend(friendships[i].friendshipId);
                  },
                  onBlock: () async {
                    final notifier = ref.read(friendActionNotifierProvider.notifier);
                    await notifier.blockUser(friendships[i].otherUserId(currentUserId));
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Tab: Pending Requests ─────────────────────────────────────

class _PendingRequestsTab extends ConsumerWidget {
  final String currentUserId;
  const _PendingRequestsTab({required this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingAsync = ref.watch(incomingRequestsStreamProvider);
    final outgoingAsync = ref.watch(outgoingRequestsStreamProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lời mời nhận được
          incomingAsync.when(
            loading: () => const LinearProgressIndicator(color: AppColors.brand),
            error: (_, __) => const SizedBox.shrink(),
            data: (incoming) {
              if (incoming.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'LỜI MỜI NHẬN ĐƯỢC — ${incoming.length}',
                      style: AppTextStyles.textMuted.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ...incoming.map(
                    (f) => IncomingRequestTile(
                      friendship: f,
                      currentUserId: currentUserId,
                      onAccept: () async {
                        // Cache notifier trước await
                        final notifier = ref.read(friendActionNotifierProvider.notifier);
                        await notifier.acceptFriendRequest(f.friendshipId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã chấp nhận lời mời!'),
                              backgroundColor: AppColors.green,
                            ),
                          );
                        }
                      },
                      onDecline: () async {
                        final notifier = ref.read(friendActionNotifierProvider.notifier);
                        await notifier.declineFriendRequest(f.friendshipId);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          // Lời mời đã gửi
          outgoingAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (outgoing) {
              if (outgoing.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'ĐÃ GỬI — ${outgoing.length}',
                      style: AppTextStyles.textMuted.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ...outgoing.map(
                    (f) => _OutgoingRequestTile(
                      friendship: f,
                      currentUserId: currentUserId,
                      onCancel: () async {
                        final notifier = ref.read(friendActionNotifierProvider.notifier);
                        await notifier.cancelFriendRequest(f.friendshipId);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          // Empty state
          if (incomingAsync.maybeWhen(data: (l) => l.isEmpty, orElse: () => false) &&
              outgoingAsync.maybeWhen(data: (l) => l.isEmpty, orElse: () => false))
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    const Icon(
                      Icons.inbox,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Không có lời mời nào đang chờ',
                      style: AppTextStyles.textMuted,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OutgoingRequestTile extends ConsumerWidget {
  final FriendshipEntity friendship;
  final String currentUserId;
  final VoidCallback? onCancel;

  const _OutgoingRequestTile({
    required this.friendship,
    required this.currentUserId,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUserId = friendship.otherUserId(currentUserId);
    final userAsync = ref.watch(userProfileProvider(otherUserId));

    return userAsync.when(
      loading: () => const ListTile(
        leading: CircleAvatar(),
        title: Text('Đang tải...'),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        return ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.bgTertiary,
            backgroundImage: user.avatarUrl.isNotEmpty
                ? NetworkImage(user.avatarUrl)
                : null,
            child: user.avatarUrl.isEmpty
                ? Text(
                    user.username[0].toUpperCase(),
                    style: AppTextStyles.labelPrimary,
                  )
                : null,
          ),
          title: Text(user.username, style: AppTextStyles.labelPrimary),
          subtitle: Text(
            'Đã gửi lời mời',
            style: AppTextStyles.textMuted.copyWith(fontSize: 12),
          ),
          trailing: TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.bgTertiary,
              foregroundColor: AppColors.textMuted,
            ),
            child: const Text('Hủy'),
          ),
        );
      },
    );
  }
}
