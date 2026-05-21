// lib/features/friend/presentation/widgets/create_group_dm_dialog.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/profile_provider.dart'; // storageDatasourceProvider
import '../providers/dm_provider.dart';
import '../providers/friend_provider.dart';

class CreateGroupDmDialog extends ConsumerStatefulWidget {
  final String currentUserId;
  final ValueChanged<String> onCreateSuccess;

  const CreateGroupDmDialog({
    super.key,
    required this.currentUserId,
    required this.onCreateSuccess,
  });

  @override
  ConsumerState<CreateGroupDmDialog> createState() => _CreateGroupDmDialogState();
}

class _CreateGroupDmDialogState extends ConsumerState<CreateGroupDmDialog> {
  late final TextEditingController _groupNameController;
  late final TextEditingController _searchController;
  final Set<String> _selectedIds = {};
  XFile? _groupImage;
  bool _isCreating = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController();
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
    _groupNameController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickGroupImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _groupImage = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsStreamProvider);

    // Get selected users names for default group name / hint
    final selectedNames = _selectedIds.map((id) {
      final user = ref.watch(userProfileProvider(id)).value;
      return user?.username ?? '';
    }).where((name) => name.isNotEmpty).join(', ');

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
                  'Tin Nhắn Mới',
                  style: AppTextStyles.headerPrimary,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Bạn có thể thêm ${9 - _selectedIds.length} người bạn nữa.',
                  style: AppTextStyles.textMuted.copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.interactiveNormal),
            onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input with Chips inline
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
            // Friends List Scrollable
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
                // Filter friends list by search query and resolve user profile
                final filteredFriends = <dynamic>[];
                for (final friend in friends) {
                  final otherUserId = friend.otherUserId(widget.currentUserId);
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
                        'Không tìm thấy bạn bè nào khớp.',
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
                          filteredFriends[i].otherUserId(widget.currentUserId);
                      final isSelected = _selectedIds.contains(otherUserId);
                      return _FriendSelectTile(
                        userId: otherUserId,
                        isSelected: isSelected,
                        onChanged: (checked) {
                          if (checked == true && _selectedIds.length >= 9) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bạn chỉ được chọn tối đa 9 thành viên'),
                                backgroundColor: AppColors.red,
                              ),
                            );
                            return;
                          }
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
            // Group Avatar and Optional Name (show only when selected count >= 2)
            if (_selectedIds.length >= 2) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgPrimary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Group Avatar Picker
                    GestureDetector(
                      onTap: _pickGroupImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.bgTertiary,
                              shape: BoxShape.circle,
                              image: _groupImage != null
                                  ? DecorationImage(
                                      image: kIsWeb
                                          ? NetworkImage(_groupImage!.path)
                                          : FileImage(File(_groupImage!.path)) as ImageProvider,
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: _groupImage != null
                                ? null
                                : const Icon(
                                    Icons.group,
                                    color: AppColors.textMuted,
                                    size: 28,
                                  ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.brand,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.bgPrimary, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Group Name Input
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TÊN NHÓM (KHÔNG BẮT BUỘC)',
                            style: AppTextStyles.inputLabel.copyWith(fontSize: 10, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _groupNameController,
                            style: AppTextStyles.textNormal,
                            decoration: InputDecoration(
                              hintText: selectedNames.isNotEmpty ? selectedNames : 'Tên nhóm',
                              hintStyle: const TextStyle(color: AppColors.textMuted),
                              filled: true,
                              fillColor: AppColors.inputBackground,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(Radius.circular(4)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
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
          onPressed: _isCreating || _selectedIds.isEmpty
              ? null
              : () async {
                  setState(() {
                    _isCreating = true;
                  });
                  try {
                    if (_selectedIds.length == 1) {
                      final dmNotifier = ref.read(dmChatNotifierProvider.notifier);
                      final chatId = await dmNotifier.openDmWith(_selectedIds.first);
                      if (chatId != null && context.mounted) {
                        Navigator.of(context).pop();
                        widget.onCreateSuccess(chatId);
                      }
                    } else {
                      String? iconUrl;
                      if (_groupImage != null) {
                        final storage = ref.read(storageDatasourceProvider);
                        iconUrl = await storage.uploadImage(_groupImage!);
                      }

                      String name = _groupNameController.text.trim();
                      if (name.isEmpty) {
                        name = _selectedIds.map((id) {
                          final user = ref.read(userProfileProvider(id)).value;
                          return user?.username ?? '';
                        }).where((n) => n.isNotEmpty).join(', ');
                        if (name.isEmpty) {
                          name = 'Group DM';
                        }
                      }

                      final dmNotifier = ref.read(dmChatNotifierProvider.notifier);
                      final chat = await dmNotifier.createGroupDm(
                        participantIds: _selectedIds.toList(),
                        name: name,
                        iconUrl: iconUrl,
                      );
                      if (chat != null && context.mounted) {
                        Navigator.of(context).pop();
                        widget.onCreateSuccess(chat.chatId);
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi tạo tin nhắn: $e')),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isCreating = false;
                      });
                    }
                  }
                },
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(_selectedIds.length >= 2 ? 'Tạo Tin Nhắn Nhóm' : 'Tạo Tin Nhắn'),
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
