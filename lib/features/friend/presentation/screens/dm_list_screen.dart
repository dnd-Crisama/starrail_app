// lib/features/friend/presentation/screens/dm_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dm_provider.dart';
import '../widgets/dm_chat_tile.dart';
import '../widgets/create_group_dm_dialog.dart';


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
    showDialog(
      context: context,
      builder: (ctx) => CreateGroupDmDialog(
        currentUserId: currentUserId,
        onCreateSuccess: (chatId) {
          if (context.mounted) {
            context.push('${AppConstants.dmChatPath}/$chatId');
          }
        },
      ),
    );
  }
}

