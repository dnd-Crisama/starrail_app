import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/message_provider.dart';

Future<void> showMessageSearchDialog({
  required BuildContext context,
  required String serverId,
  required String channelId,
  required String channelName,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => MessageSearchDialog(
      serverId: serverId,
      channelId: channelId,
      channelName: channelName,
    ),
  );
}

class MessageSearchDialog extends ConsumerStatefulWidget {
  final String serverId;
  final String channelId;
  final String channelName;

  const MessageSearchDialog({
    super.key,
    required this.serverId,
    required this.channelId,
    required this.channelName,
  });

  @override
  ConsumerState<MessageSearchDialog> createState() =>
      _MessageSearchDialogState();
}

class _MessageSearchDialogState extends ConsumerState<MessageSearchDialog> {
  final _controller = TextEditingController();
  final Map<String, String> _userNameCache = {};
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trimmedQuery = _query.trim();

    return AlertDialog(
      backgroundColor: AppColors.bgFloating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      title: Row(
        children: [
          const Icon(Icons.search, color: AppColors.brand, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tìm trong #${widget.channelName}',
              style: AppTextStyles.headerPrimary.copyWith(fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(
                color: AppColors.textNormal,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.inputBackground,
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textMuted,
                  size: 18,
                ),
                hintText: 'Nhập nội dung tin nhắn...',
                hintStyle: AppTextStyles.textMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.brand),
                ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildSearchResults(trimmedQuery)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Đóng',
            style: TextStyle(color: AppColors.interactiveNormal),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(String query) {
    if (query.isEmpty) {
      return const Center(
        child: Text(
          'Nhập từ khóa để tìm tin nhắn.',
          style: AppTextStyles.welcomeSubtitle,
        ),
      );
    }

    return FutureBuilder<List<MessageSearchResult>>(
      future: _searchMessages(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.brand,
              strokeWidth: 2,
            ),
          );
        }

        final results = snapshot.data ?? const <MessageSearchResult>[];
        if (results.isEmpty) {
          return const Center(
            child: Text(
              'Không tìm thấy tin nhắn phù hợp.',
              style: AppTextStyles.welcomeSubtitle,
            ),
          );
        }

        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) =>
              const Divider(color: AppColors.divider, height: 1),
          itemBuilder: (context, index) {
            final result = results[index];
            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              title: Text(
                result.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyPrimary,
              ),
              subtitle: Text(
                '${result.senderName} • ${_formatSearchTime(result.createdAt)}',
                style: AppTextStyles.textMutedSmall,
              ),
              trailing: const Icon(
                Icons.open_in_new,
                color: AppColors.interactiveNormal,
                size: 18,
              ),
              onTap: () {
                Navigator.pop(context);
                ref.read(messageSearchTargetProvider.notifier).state =
                    result.messageId;
              },
            );
          },
        );
      },
    );
  }

  Future<List<MessageSearchResult>> _searchMessages(String query) async {
    final normalizedQuery = query.toLowerCase();
    final snapshot = await FirebaseFirestore.instance
        .collection('servers')
        .doc(widget.serverId)
        .collection('channels')
        .doc(widget.channelId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .get();

    final results = <MessageSearchResult>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final isDeleted = data['isDeleted'] as bool? ?? false;
      final content = data['content'] as String? ?? '';
      if (isDeleted || !content.toLowerCase().contains(normalizedQuery)) {
        continue;
      }

      final senderId = data['senderId'] as String? ?? '';
      final createdAt =
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      results.add(
        MessageSearchResult(
          messageId: doc.id,
          content: content,
          senderName: await _getSenderName(senderId),
          createdAt: createdAt,
        ),
      );
    }

    return results;
  }

  Future<String> _getSenderName(String senderId) async {
    if (senderId.isEmpty) return 'Người dùng';
    final currentUser = ref.read(authNotifierProvider).user;
    if (currentUser?.uid == senderId) return currentUser?.username ?? 'Bạn';

    final cached = _userNameCache[senderId];
    if (cached != null) return cached;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();
      final name = doc.data()?['username'] as String? ?? 'Người dùng';
      _userNameCache[senderId] = name;
      return name;
    } catch (_) {
      return 'Người dùng';
    }
  }

  String _formatSearchTime(DateTime value) {
    final date =
        '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
    final time =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}

class MessageSearchResult {
  final String messageId;
  final String content;
  final String senderName;
  final DateTime createdAt;

  const MessageSearchResult({
    required this.messageId,
    required this.content,
    required this.senderName,
    required this.createdAt,
  });
}
