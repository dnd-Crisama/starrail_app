// lib/features/friend/presentation/screens/add_friend_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/friend_provider.dart';

/// Màn hình tìm kiếm user và gửi lời mời kết bạn.
class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchUsersNotifierProvider);
    final actionState = ref.watch(friendActionNotifierProvider);
    final currentUserId = ref.watch(authNotifierProvider).user?.uid ?? '';
    final friendsAsync = ref.watch(friendsStreamProvider);
    final outgoingAsync = ref.watch(outgoingRequestsStreamProvider);
    final incomingAsync = ref.watch(incomingRequestsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      resizeToAvoidBottomInset: true, // Cho phép resize khi hiện bàn phím
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        title: const Text('Thêm bạn bè', style: AppTextStyles.headerPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textNormal),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Search header
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  color: AppColors.bgPrimary,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TÌM KIẾM BẠN BÈ',
                        style: AppTextStyles.labelPrimary.copyWith(
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _searchController,
                        style: AppTextStyles.textNormal,
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: 'Nhập tên người dùng...',
                          hintStyle: AppTextStyles.textMuted,
                          filled: true,
                          fillColor: AppColors.inputBackground,
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.textMuted,
                          ),
                          suffixIcon: searchState.query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: AppColors.textMuted,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref
                                        .read(searchUsersNotifierProvider.notifier)
                                        .clear();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          ref
                              .read(searchUsersNotifierProvider.notifier)
                              .search(value);
                        },
                      ),
                      if (actionState.error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          actionState.error!,
                          style: AppTextStyles.textMuted.copyWith(
                            color: AppColors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(color: AppColors.divider, height: 1),
              ],
            ),
          ),
          // Results
          _buildSliverResults(
            searchState,
            actionState,
            currentUserId,
            friendsAsync.valueOrNull ?? [],
            outgoingAsync.valueOrNull ?? [],
            incomingAsync.valueOrNull ?? [],
          ),
        ],
      ),
    );
  }

  Widget _buildSliverResults(
    SearchState searchState,
    FriendActionState actionState,
    String currentUserId,
    List friends,
    List outgoingRequests,
    List incomingRequests,
  ) {
    if (searchState.isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        ),
      );
    }

    if (searchState.query.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: EdgeInsets.only(top: 64.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 64, color: AppColors.textMuted),
                SizedBox(height: 16),
                Text(
                  'Tìm kiếm bạn bè theo tên người dùng',
                  style: AppTextStyles.textMuted,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (searchState.results.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: EdgeInsets.only(top: 64.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 64, color: AppColors.textMuted),
                SizedBox(height: 16),
                Text(
                  'Không tìm thấy người dùng nào',
                  style: AppTextStyles.textMuted,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, index) {
          final user = searchState.results[index];
          
          final isFriend = friends.any((f) => f.otherUserId(currentUserId) == user.uid);
          final isOutgoing = outgoingRequests.any((f) => f.otherUserId(currentUserId) == user.uid);
          final isIncoming = incomingRequests.any((f) => f.otherUserId(currentUserId) == user.uid);

          Widget actionWidget;
          if (isFriend) {
            actionWidget = const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Text('Đã là bạn bè', style: AppTextStyles.textMuted),
            );
          } else if (isOutgoing) {
            actionWidget = const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Text('Đã gửi', style: AppTextStyles.textMuted),
            );
          } else if (isIncoming) {
            actionWidget = const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Text('Chờ chấp nhận', style: AppTextStyles.textMuted),
            );
          } else {
            actionWidget = actionState.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.brand,
                    ),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: () => _sendRequest(user.uid),
                    child: const Text('Thêm bạn', style: TextStyle(fontSize: 13)),
                  );
          }

          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Row(
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username.isNotEmpty ? user.username : 'Unknown',
                        style: AppTextStyles.labelPrimary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email.isNotEmpty ? user.email : 'No email',
                        style: AppTextStyles.textMutedSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                actionWidget,
              ],
            ),
          );
        },
        childCount: searchState.results.length,
      ),
    );
  }

  Future<void> _sendRequest(String targetUserId) async {
    // Cache notifier TRƯỚC await để tránh "ref after dispose"
    final notifier = ref.read(friendActionNotifierProvider.notifier);
    final success = await notifier.sendFriendRequest(targetUserId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi lời mời kết bạn!'),
          backgroundColor: AppColors.green,
        ),
      );
    } else {
      // Đọc error state sau khi mounted check an toàn
      final error = ref.read(friendActionNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Gửi lời mời thất bại'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }
}
