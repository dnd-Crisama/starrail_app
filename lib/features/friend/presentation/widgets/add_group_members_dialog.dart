// lib/features/friend/presentation/widgets/add_group_members_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/dm_chat_entity.dart';
import '../providers/dm_provider.dart';
import '../providers/friend_provider.dart';

class AddGroupMembersDialog extends ConsumerStatefulWidget {
  final DmChatEntity chat;

  const AddGroupMembersDialog({
    super.key,
    required this.chat,
  });

  @override
  ConsumerState<AddGroupMembersDialog> createState() => _AddGroupMembersDialogState();
}

class _AddGroupMembersDialogState extends ConsumerState<AddGroupMembersDialog> {
  late final TextEditingController _searchController;
  final Set<String> _selectedIds = {};
  bool _isSaving = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsStreamProvider);

    return AlertDialog(
      backgroundColor: AppColors.bgSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.all(20),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thêm Bạn bè vào DM Nhóm',
                  style: AppTextStyles.headerPrimary,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Chọn bạn bè để thêm vào nhóm chat này.',
                  style: AppTextStyles.textMuted.copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.interactiveNormal),
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ..._selectedIds.map((id) {
                    final userAsync = ref.watch(userProfileProvider(id));
                    final username = userAsync.value?.username ?? '...';
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            username,
                            style: AppTextStyles.textNormal.copyWith(fontSize: 13),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIds.remove(id);
                              });
                            },
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _searchController,
                      style: AppTextStyles.textNormal,
                      decoration: InputDecoration(
                        hintText: _selectedIds.isEmpty ? 'Tìm kiếm bạn bè' : '',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Friends List Scrollable (Exclude existing participants)
            friendsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: AppColors.brand),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Lỗi: $err',
                  style: const TextStyle(color: AppColors.red),
                ),
              ),
              data: (friends) {
                final filteredFriends = <dynamic>[];
                for (final friend in friends) {
                  // Get other user's id
                  final otherUserId = friend.otherUserId(ref.watch(authNotifierProvider).user?.uid ?? '');
                  
                  // Exclude if already in the group
                  if (widget.chat.participants.contains(otherUserId)) continue;

                  final userAsync = ref.watch(userProfileProvider(otherUserId));
                  final user = userAsync.value;
                  if (user == null) continue;

                  if (_searchQuery.isEmpty) {
                    filteredFriends.add(friend);
                  } else {
                    final query = _searchQuery.toLowerCase();
                    final name = user.username.toLowerCase();
                    final emailPrefix = user.email.split('@').first.toLowerCase();
                    if (name.contains(query) || emailPrefix.contains(query)) {
                      filteredFriends.add(friend);
                    }
                  }
                }

                if (filteredFriends.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        'Không còn bạn bè nào để thêm.',
                        style: AppTextStyles.textMuted,
                      ),
                    ),
                  );
                }

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredFriends.length,
                    itemBuilder: (_, i) {
                      final otherUserId =
                          filteredFriends[i].otherUserId(ref.watch(authNotifierProvider).user?.uid ?? '');
                      final isSelected = _selectedIds.contains(otherUserId);
                      return _FriendSelectTile(
                        userId: otherUserId,
                        isSelected: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedIds.add(otherUserId);
                            } else {
                              _selectedIds.remove(otherUserId);
                            }
                          });
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Hủy bỏ',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.brand.withOpacity(0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          onPressed: _isSaving || _selectedIds.isEmpty
              ? null
              : () async {
                  setState(() {
                    _isSaving = true;
                  });
                  try {
                    final updatedParticipants = [
                      ...widget.chat.participants,
                      ..._selectedIds,
                    ];

                    final success = await ref
                        .read(dmChatNotifierProvider.notifier)
                        .updateGroupDm(
                          chatId: widget.chat.chatId,
                          name: widget.chat.name,
                          iconUrl: widget.chat.iconUrl,
                          participantIds: updatedParticipants,
                        );

                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã thêm thành viên thành công!'),
                          backgroundColor: AppColors.brand,
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e')),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isSaving = false;
                      });
                    }
                  }
                },
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Thêm thành viên'),
        ),
      ],
    );
  }
}

class _FriendSelectTile extends ConsumerWidget {
  final String userId;
  final bool isSelected;
  final ValueChanged<bool?> onChanged;

  const _FriendSelectTile({
    required this.userId,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(userId));

    return userAsync.when(
      loading: () => const ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.bgTertiary,
        ),
        title: Text('Đang tải...', style: AppTextStyles.textNormal),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final handle = user.email.split('@').first.toLowerCase();

        return CheckboxListTile(
          value: isSelected,
          activeColor: AppColors.brand,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          title: Text(
            user.username,
            style: AppTextStyles.textNormal,
          ),
          subtitle: Text(
            handle,
            style: AppTextStyles.textMuted.copyWith(fontSize: 12),
          ),
          secondary: _AvatarWithStatus(
            username: user.username,
            avatarUrl: user.avatarUrl,
            status: user.status,
          ),
          onChanged: onChanged,
        );
      },
    );
  }
}

class _AvatarWithStatus extends StatelessWidget {
  final String username;
  final String avatarUrl;
  final UserStatus status;

  const _AvatarWithStatus({
    required this.username,
    required this.avatarUrl,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.bgTertiary,
            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty
                ? Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: AppTextStyles.labelPrimary.copyWith(fontSize: 12),
                  )
                : null,
          ),
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: _statusColor(status),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bgSecondary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(UserStatus status) {
    switch (status) {
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
}
