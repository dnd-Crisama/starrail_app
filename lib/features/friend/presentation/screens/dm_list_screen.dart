// lib/features/friend/presentation/screens/dm_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dm_provider.dart';
import '../providers/friend_provider.dart';
import '../widgets/dm_chat_tile.dart';

/// Danh sách các cuộc hội thoại DM — tích hợp vào HomeScreen sidebar.
/// Có thể dùng standalone hoặc nhúng vào layout.
class DmListScreen extends ConsumerWidget {
  /// chatId đang được chọn (để highlight tile đang active).
  final String? selectedChatId;

  const DmListScreen({super.key, this.selectedChatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authNotifierProvider).user?.uid ?? '';
    final chatsAsync = ref.watch(dmChatsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: Column(
        children: [
          // Header với nút tạo Group DM
          _buildHeader(context, ref, currentUserId),
          const Divider(color: AppColors.divider, height: 1),
          // Danh sách chats
          Expanded(
            child: chatsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.brand),
              ),
              error: (e, _) => Center(
                child: Text('$e', style: AppTextStyles.textMuted),
              ),
              data: (chats) {
                if (chats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Chưa có tin nhắn nào',
                          style: AppTextStyles.textMuted,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () =>
                              context.push(AppConstants.friendsPath),
                          child: const Text(
                            'Tìm bạn bè',
                            style: TextStyle(color: AppColors.brand),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: chats.length,
                  itemBuilder: (_, i) {
                    final chat = chats[i];
                    return DmChatTile(
                      chat: chat,
                      isSelected: selectedChatId == chat.chatId,
                      onTap: () => context.push(
                        '${AppConstants.dmChatPath}/${chat.chatId}',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    String currentUserId,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'TIN NHẮN RIÊNG',
              style: AppTextStyles.textMuted.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Nút tạo Group DM
          Tooltip(
            message: 'Tạo nhóm DM',
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => _showCreateGroupDmDialog(context, ref, currentUserId),
              child: const Icon(
                Icons.add,
                color: AppColors.textMuted,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateGroupDmDialog(
    BuildContext context,
    WidgetRef ref,
    String currentUserId,
  ) async {
    final groupNameController = TextEditingController();
    final friendsAsync = ref.read(friendsStreamProvider);

    final friends = friendsAsync.maybeWhen(
      data: (list) => list,
      orElse: () => [],
    );

    final selectedIds = <String>{};

    // Cache notifier TR\u01af\u1edaC showDialog để tránh "ref after dispose"
    final dmNotifier = ref.read(dmChatNotifierProvider.notifier);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.bgSecondary,
            title: const Text(
              'Tạo nhóm DM',
              style: AppTextStyles.headerPrimary,
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: groupNameController,
                    style: AppTextStyles.textNormal,
                    decoration: const InputDecoration(
                      hintText: 'Tên nhóm (bắt buộc)',
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (friends.isEmpty)
                    const Text(
                      'Chưa có bạn bè để thêm vào nhóm',
                      style: AppTextStyles.textMuted,
                    )
                  else ...[
                    Text(
                      'Chọn thành viên:',
                      style: AppTextStyles.textMuted.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: friends.length,
                        itemBuilder: (_, i) {
                          final otherUserId =
                              friends[i].otherUserId(currentUserId);
                          return Consumer(
                            builder: (_, ref, __) {
                              final userAsync = ref.watch(
                                userProfileProvider(otherUserId),
                              );
                              return userAsync.maybeWhen(
                                data: (user) => CheckboxListTile(
                                  value: selectedIds.contains(otherUserId),
                                  activeColor: AppColors.brand,
                                  title: Text(
                                    user?.username ?? otherUserId,
                                    style: AppTextStyles.textNormal,
                                  ),
                                  onChanged: (checked) {
                                    setDialogState(() {
                                      if (checked == true) {
                                        selectedIds.add(otherUserId);
                                      } else {
                                        selectedIds.remove(otherUserId);
                                      }
                                    });
                                  },
                                ),
                                orElse: () => const SizedBox.shrink(),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Hủy',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                ),
                onPressed: selectedIds.isEmpty ||
                        groupNameController.text.trim().isEmpty
                    ? null
                    : () async {
                        Navigator.of(ctx).pop();
                        // Dùng dmNotifier đã cache, không dùng ref sau await
                        final chat = await dmNotifier.createGroupDm(
                          participantIds: selectedIds.toList(),
                          name: groupNameController.text.trim(),
                        );
                        if (chat != null && context.mounted) {
                          context.push(
                            '${AppConstants.dmChatPath}/${chat.chatId}',
                          );
                        }
                      },
                child: const Text('Tạo nhóm'),
              ),
            ],
          );
        },
      ),
    );

    groupNameController.dispose();
  }
}
