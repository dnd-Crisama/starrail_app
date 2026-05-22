// lib/features/friend/presentation/screens/dm_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/dm_chat_entity.dart';
import '../../domain/entities/dm_message_entity.dart';
import '../providers/dm_provider.dart';
import '../providers/friend_provider.dart';
import 'package:flutter/services.dart';
import '../widgets/dm_message_bubble.dart';
import '../widgets/group_member_list_panel.dart';
import '../widgets/edit_group_dm_dialog.dart';
import '../widgets/add_group_members_dialog.dart';

/// Màn hình chat DM — hoạt động cho cả DM 1-1 và Group DM.
class DmChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const DmChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<DmChatScreen> createState() => _DmChatScreenState();
}

class _DmChatScreenState extends ConsumerState<DmChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late final FocusNode _focusNode;
  bool _showMemberList = true;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
          final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
          if (!isShiftPressed) {
            _sendMessage(ref.read(authNotifierProvider).user?.uid ?? '');
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authNotifierProvider).user;
    final chatAsync = ref.watch(dmChatDetailProvider(widget.chatId));
    final messagesAsync = ref.watch(dmMessagesStreamProvider(widget.chatId));
    final messageState = ref.watch(dmMessageNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: chatAsync.when(
        loading: () => AppBar(
          backgroundColor: AppColors.bgSecondary,
          title: const Text('Loading...', style: AppTextStyles.headerPrimary),
        ),
        error: (_, __) => AppBar(
          backgroundColor: AppColors.bgSecondary,
          title: const Text('DM', style: AppTextStyles.headerPrimary),
        ),
        data: (chat) => _buildAppBar(chat, currentUser?.uid ?? ''),
      ),
      body: chatAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brand),
        ),
        error: (e, _) => Center(
          child: Text(
            'Lỗi: $e',
            style: AppTextStyles.textMuted,
          ),
        ),
        data: (chat) {
          if (chat == null) {
            return const Center(child: Text('Không tìm thấy cuộc trò chuyện'));
          }

          return Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    // Messages list
                    Expanded(
                      child: messagesAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: AppColors.brand),
                        ),
                        error: (e, _) => Center(
                          child: Text(
                            'Lỗi tải tin nhắn: $e',
                            style: AppTextStyles.textMuted,
                          ),
                        ),
                        data: (messages) => _buildMessageList(
                          messages,
                          currentUser?.uid ?? '',
                        ),
                      ),
                    ),
                    // Error message nếu gửi thất bại
                    if (messageState.error != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        color: AppColors.red.withValues(alpha: 0.1),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.red, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                messageState.error!,
                                style: AppTextStyles.textMuted.copyWith(
                                  color: AppColors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Message input
                    _buildMessageInput(messageState, currentUser?.uid ?? ''),
                  ],
                ),
              ),
              if (chat.isGroupDm && _showMemberList)
                GroupMemberListPanel(chat: chat),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(DmChatEntity? chat, String currentUserId) {
    if (chat == null) {
      return AppBar(
        backgroundColor: AppColors.bgSecondary,
        title: const Text('DM', style: AppTextStyles.headerPrimary),
      );
    }

    if (chat.isGroupDm) {
      return AppBar(
        backgroundColor: AppColors.bgSecondary,
        iconTheme: const IconThemeData(color: AppColors.textNormal),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.bgTertiary,
              backgroundImage: chat.iconUrl != null && chat.iconUrl!.isNotEmpty
                  ? NetworkImage(chat.iconUrl!)
                  : null,
              child: chat.iconUrl == null || chat.iconUrl!.isEmpty
                  ? const Icon(Icons.group, size: 16, color: AppColors.textMuted)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          chat.name,
                          style: AppTextStyles.headerPrimary,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Tooltip(
                        message: 'Chỉnh Sửa Nhóm',
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => EditGroupDmDialog(chat: chat),
                            );
                          },
                          child: const Icon(
                            Icons.edit,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${chat.participants.length} thành viên',
                    style: AppTextStyles.textMuted.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_add_alt_1_outlined,
              color: AppColors.textNormal,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AddGroupMembersDialog(chat: chat),
              );
            },
            tooltip: 'Thêm Bạn bè vào DM Nhóm',
          ),
          IconButton(
            icon: Icon(
              Icons.people_alt,
              color: _showMemberList ? AppColors.textNormal : AppColors.textMuted,
            ),
            onPressed: () {
              setState(() {
                _showMemberList = !_showMemberList;
              });
            },
            tooltip: 'Danh sách thành viên',
          ),
        ],
      );
    }

    // DM 1-1: hiển thị thông tin người kia
    final otherUserId = chat.otherParticipantId(currentUserId);
    return _DmAppBar(
      otherUserId: otherUserId,
    );
  }

  Widget _buildMessageList(List<DmMessageEntity> messages, String currentUserId) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có tin nhắn nào',
              style: AppTextStyles.textMuted,
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy bắt đầu cuộc trò chuyện!',
              style: AppTextStyles.textMuted.copyWith(fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Cuộn xuống cuối khi có tin nhắn mới
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final message = messages[i];
        final isCurrentUser = message.senderId == currentUserId;
        final showDate = i == 0 ||
            !_isSameDay(messages[i - 1].createdAt, message.createdAt);

        // Logic gom nhóm tin nhắn (tránh dư thừa)
        bool showSenderInfo = true;
        if (i > 0 && !showDate) {
          final prevMessage = messages[i - 1];
          if (prevMessage.senderId == message.senderId) {
            final diff = message.createdAt.difference(prevMessage.createdAt).inMinutes;
            if (diff < 5) {
              showSenderInfo = false;
            }
          }
        }

        return Column(
          children: [
            if (showDate) _buildDateDivider(message.createdAt),
            _buildMessageWithSender(
              message: message,
              isCurrentUser: isCurrentUser,
              currentUserId: currentUserId,
              showSenderInfo: showSenderInfo,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageWithSender({
    required DmMessageEntity message,
    required bool isCurrentUser,
    required String currentUserId,
    required bool showSenderInfo,
  }) {
    // Lấy thông tin sender từ provider
    return Consumer(
      builder: (_, ref, __) {
        final senderAsync = ref.watch(userProfileProvider(message.senderId));
        final senderName = senderAsync.maybeWhen(
          data: (u) => u?.username ?? 'Người dùng',
          orElse: () => 'Người dùng',
        );
        final senderAvatar = senderAsync.maybeWhen(
          data: (u) => u?.avatarUrl ?? '',
          orElse: () => '',
        );

        return DmMessageBubble(
          message: message,
          isCurrentUser: isCurrentUser,
          senderName: senderName,
          senderAvatarUrl: senderAvatar,
          showSenderName: showSenderInfo,
          showAvatar: showSenderInfo,
          onDelete: isCurrentUser
              ? () => _deleteMessage(message.messageId)
              : null,
        );
      },
    );
  }

  Widget _buildDateDivider(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: AppTextStyles.textMuted.copyWith(fontSize: 11),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.divider)),
        ],
      ),
    );
  }

  Widget _buildMessageInput(DmMessageState state, String currentUserId) {
    return Container(
      color: AppColors.bgPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                style: AppTextStyles.textNormal,
                maxLines: null,
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(currentUserId),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          state.isSending
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.brand,
                  ),
                )
              : IconButton(
                  onPressed: () => _sendMessage(currentUserId),
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String currentUserId) async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    _focusNode.requestFocus();

    // Cache notifier TRƯỚC await để tránh "ref after dispose"
    if (!mounted) return;
    final notifier = ref.read(dmMessageNotifierProvider.notifier);
    await notifier.sendMessage(
      chatId: widget.chatId,
      content: content,
    );
  }

  Future<void> _deleteMessage(String messageId) async {
    if (!mounted) return;
    final notifier = ref.read(dmMessageNotifierProvider.notifier);
    await notifier.deleteMessage(
      chatId: widget.chatId,
      messageId: messageId,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// AppBar riêng cho DM 1-1, load thông tin người kia.
class _DmAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String otherUserId;

  const _DmAppBar({required this.otherUserId});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider(otherUserId));

    return AppBar(
      backgroundColor: AppColors.bgSecondary,
      iconTheme: const IconThemeData(color: AppColors.textNormal),
      title: userAsync.when(
        loading: () => const Text('Đang tải...', style: AppTextStyles.headerPrimary),
        error: (_, __) => const Text('DM', style: AppTextStyles.headerPrimary),
        data: (user) {
          if (user == null) {
            return const Text('DM', style: AppTextStyles.headerPrimary);
          }
          return Row(
            children: [
              _AvatarWithStatus(
                username: user.username,
                avatarUrl: user.avatarUrl,
                status: user.status,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.username, style: AppTextStyles.headerPrimary),
                  Text(
                    _statusText(user.status),
                    style: AppTextStyles.textMuted.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _statusText(UserStatus status) {
    switch (status) {
      case UserStatus.online:
        return 'Online';
      case UserStatus.idle:
        return 'Idle';
      case UserStatus.dnd:
        return 'Không làm phiền';
      default:
        return 'Offline';
    }
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
                    style: AppTextStyles.labelPrimary,
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
