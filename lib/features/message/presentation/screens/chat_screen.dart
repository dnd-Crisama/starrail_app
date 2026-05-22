import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../auth/data/datasources/cloudinary_storage_datasource.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/message_entity.dart';
import '../providers/message_provider.dart';
import '../widgets/message_context_menu.dart';
import '../widgets/reply_bar.dart';
import '../widgets/reply_preview.dart';
import '../widgets/reaction_display.dart';
import '../widgets/delete_confirm_dialog.dart';
import '../widgets/attachment_display.dart';
import '../widgets/user_profile_modal.dart';

/// Màn hình chat hiển thị danh sách tin nhắn và input gửi tin nhắn
class ChatScreen extends ConsumerStatefulWidget {
  final String serverId;
  final String channelId;

  const ChatScreen({
    super.key,
    required this.serverId,
    required this.channelId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

/// Dữ liệu cache cho user khác (username + avatarUrl)
class _UserData {
  final String username;
  final String avatarUrl;
  _UserData({required this.username, required this.avatarUrl});
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  static final Map<String, _UserData> _sharedUserDataCache = {};
  static final Map<String, MessageEntity> _sharedMessageCache = {};
  static const int _maxSharedUserCacheEntries = 500;
  static const int _maxSharedMessageCacheEntries = 500;
  static const double _estimatedMessageHeight = 48;

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  // Cache cho user data (username + avatarUrl)
  final Map<String, _UserData> _userDataCache = {};
  // Cache cho reply preview — map từ messageId → MessageEntity
  final Map<String, MessageEntity> _repliedMessageCache = {};

  // Upload state
  bool _isUploading = false;
  List<AttachmentEntity> _pendingAttachments = [];

  // Danh sách tin nhắn hiện tại (để scroll đến tin nhắn theo ID)
  List<MessageEntity> _visibleMessages = [];

  // GlobalKey cho mỗi tin nhắn — dùng để scroll chính xác đến vị trí
  final Map<String, GlobalKey> _messageKeys = {};
  final Map<String, double> _messageHeightCache = {};

  // Highlight flash khi navigate đến tin nhắn
  String? _highlightedMessageId;
  Timer? _highlightTimer;

  // Track previous message count để chỉ auto-scroll khi có tin nhắn mới
  int _previousMessageCount = 0;
  String? _lastRenderedMessageId;
  bool _forceScrollToBottomOnNextMessage = false;

  // Flag ngăn auto-scroll khi đang navigate đến tin nhắn
  bool _isNavigating = false;
  int _channelGeneration = 0;

  // Read/Unread: lastReadMessageId cho channel hiện tại
  String? _lastReadMessageId;
  bool _hasLoadedReadStatus = false;

  // Discord-style: "New Messages" divider — lưu messageId ngay TRƯỚC unread,
  // biến mất khi user đã đọc (markAsRead) hoặc chuyển channel.
  String? _newMessagesDividerAfterId;
  bool _newMessagesDividerBeforeFirst = false;
  bool _hasSetNewMessagesDivider = false;

  // Initial scroll: cuộn đến tin nhắn chưa đọc đầu tiên khi mở channel
  bool _hasPerformedInitialScroll = false;

  // Condition B: 3-second timer — chỉ markAsRead sau 3 giây nếu chưa scroll xuống cuối
  Timer? _channelViewTimer;
  bool _hasMarkedReadOnView = false;

  // Jump to Present: hiện nút khi scroll lên trên
  bool _showJumpToPresent = false;

  // "New Messages" banner: hiện khi channel có unread và user đang scroll lên
  bool _showNewMessagesBanner = false;

  // Flash message: auto-hide timer
  Timer? _flashTimer;

  // Keyboard listener FocusNode — phải dispose
  final _keyboardFocusNode = FocusNode(descendantsAreFocusable: true);

  // Pagination: tải thêm tin nhắn cũ khi scroll lên đầu
  List<MessageEntity> _olderMessages = [];
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  // Scroll position preservation khi prepend tin nhắn cũ
  double? _savedScrollOffset;
  double? _savedMaxScrollExtent;

  @override
  void initState() {
    super.initState();
    _focusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
        final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
        if (!isShiftPressed) {
          _sendMessage();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
    // Lắng nghe khi edit message được set → điền nội dung vào input
    ref.listenManual(editingMessageProvider, (previous, next) {
      if (next != null) {
        _messageController.text = next.content;
        _focusNode.requestFocus();
      } else {
        _messageController.clear();
      }
    });

    // Lắng nghe vị trí scroll để hiện/ẩn nút "Jump to Present" + "New Messages" banner
    _scrollController.addListener(_onScroll);

    // Load read status cho channel
    _loadReadStatus();
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Safety net: nếu serverId hoặc channelId thay đổi nhưng Flutter vẫn
    // reuse state (khi không có ValueKey), reset toàn bộ state để tránh
    // tin nhắn từ kênh cũ bị mang sang kênh mới.
    if (oldWidget.serverId != widget.serverId ||
        oldWidget.channelId != widget.channelId) {
      _resetStateForNewChannel();
    }
  }

  /// Reset toàn bộ state khi chuyển sang kênh khác
  void _resetStateForNewChannel() {
    _channelGeneration++;

    // Hủy các timer đang chạy
    _highlightTimer?.cancel();
    _flashTimer?.cancel();
    _channelViewTimer?.cancel();

    // Flush debounce writes cho kênh cũ
    ref.read(unreadStatusNotifierProvider.notifier).flush();

    // Reset pagination state — NGUYÊN NHÂN CHÍNH gây leak tin nhắn
    _olderMessages = [];
    _isLoadingMore = false;
    _hasMoreMessages = true;
    _savedScrollOffset = null;
    _savedMaxScrollExtent = null;

    // Reset message list state
    _visibleMessages = [];
    _previousMessageCount = 0;
    _lastRenderedMessageId = null;
    _forceScrollToBottomOnNextMessage = false;
    _messageKeys.clear();
    _messageHeightCache.clear();

    // Reset highlight state
    _highlightedMessageId = null;

    // Reset navigation flag
    _isNavigating = false;

    // Reset read/unread state
    _lastReadMessageId = null;
    _hasLoadedReadStatus = false;
    _newMessagesDividerAfterId = null;
    _newMessagesDividerBeforeFirst = false;
    _hasSetNewMessagesDivider = false;
    _hasPerformedInitialScroll = false;
    _hasMarkedReadOnView = false;

    // Reset UI state
    _showJumpToPresent = false;
    _showNewMessagesBanner = false;

    // Reset input state
    _pendingAttachments = [];
    _isUploading = false;
    _messageController.clear();

    // Xóa global providers (reply/edit)
    ref.read(replyingToProvider.notifier).state = null;
    ref.read(editingMessageProvider.notifier).state = null;

    // Xóa cache
    _userDataCache.clear();
    _repliedMessageCache.clear();

    // Tải read status cho kênh mới
    _loadReadStatus();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _focusNode.dispose();
    _highlightTimer?.cancel();
    _flashTimer?.cancel();
    _channelViewTimer?.cancel();
    _keyboardFocusNode.dispose();
    // Flush debounce writes khi rời channel
    ref.read(unreadStatusNotifierProvider.notifier).flush();
    super.dispose();
  }

  /// Load read status từ Firestore khi mở channel
  /// Đồng thời load vào UnreadStatusNotifier cho sidebar indicators
  Future<void> _loadReadStatus() async {
    final generation = _channelGeneration;
    final serverId = widget.serverId;
    final channelId = widget.channelId;
    final key = '$serverId/$channelId';
    final cachedLastRead = ref
        .read(unreadStatusNotifierProvider.notifier)
        .getLastReadMessageId(serverId, channelId);

    if (cachedLastRead != null && mounted) {
      setState(() {
        _lastReadMessageId = cachedLastRead;
      });
    }

    final lastRead = await ref
        .read(messageNotifierProvider.notifier)
        .getLastReadMessageId(serverId: serverId, channelId: channelId);

    if (!mounted ||
        generation != _channelGeneration ||
        serverId != widget.serverId ||
        channelId != widget.channelId) {
      return;
    }

    final effectiveLastRead = lastRead ?? cachedLastRead;
    if (effectiveLastRead != null) {
      // Cập nhật vào UnreadStatusNotifier (cho sidebar indicators)
      ref.read(unreadStatusNotifierProvider.notifier).state = {
        ...ref.read(unreadStatusNotifierProvider),
        key: effectiveLastRead,
      };
      setState(() {
        _lastReadMessageId = effectiveLastRead;
        _hasLoadedReadStatus = true;
      });
    } else {
      setState(() => _hasLoadedReadStatus = true);
    }

    // Condition B: Bắt đầu 3-second timer để markAsRead khi ở channel
    _startChannelViewTimer();
  }

  /// Condition B: Đánh dấu đã đọc sau 3 giây xem channel
  /// Chỉ kích hoạt nếu user chưa markAsRead bằng cách khác
  void _startChannelViewTimer() {
    _channelViewTimer?.cancel();
    _channelViewTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_hasMarkedReadOnView && _isNearBottom()) {
        _hasMarkedReadOnView = true;
        _markAsRead();
      }
    });
  }

  /// Đánh dấu đã đọc tin nhắn cuối cùng trong channel
  /// Sử dụng Optimistic UI update + Debounced Firestore writes
  void _markAsRead() {
    if (_visibleMessages.isEmpty) return;
    final lastMessage = _visibleMessages.last;
    if (_lastReadMessageId == lastMessage.messageId) return;

    _lastReadMessageId = lastMessage.messageId;
    _hasMarkedReadOnView = true;

    // Optimistic: Cập nhật UI ngay trên UnreadStatusNotifier
    ref
        .read(unreadStatusNotifierProvider.notifier)
        .markAsRead(
          serverId: widget.serverId,
          channelId: widget.channelId,
          lastReadMessageId: lastMessage.messageId,
        );

    // Cập nhật local channelReadStatusProvider (cho ChatScreen)
    ref
            .read(
              channelReadStatusProvider((
                serverId: widget.serverId,
                channelId: widget.channelId,
              )).notifier,
            )
            .state =
        lastMessage.messageId;

    // Ẩn "New Messages" banner khi đã mark as read
    if (_showNewMessagesBanner) {
      setState(() => _showNewMessagesBanner = false);
    }

    // Discord: Xóa "New Messages" divider khi user đã đọc tin nhắn
    // Divider chỉ xuất hiện 1 lần khi vào channel, biến mất khi markAsRead
    if (_newMessagesDividerAfterId != null) {
      setState(() {
        _newMessagesDividerAfterId = null;
        _newMessagesDividerBeforeFirst = false;
      });
    } else if (_newMessagesDividerBeforeFirst) {
      setState(() {
        _newMessagesDividerBeforeFirst = false;
      });
    }
  }

  /// Condition C: Shift + Esc — đánh dấu đã đọc ngay lập tức
  void _markAsReadImmediately() {
    _markAsRead();
    // Force flush Firestore writes
    ref.read(unreadStatusNotifierProvider.notifier).flush();
  }

  /// Lắng nghe scroll position để hiện/ẩn nút "Jump to Present" + "New Messages" banner
  /// + trigger load more khi gần đầu danh sách
  bool _isNearBottom({double threshold = 100}) {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return position.maxScrollExtent - position.pixels <= threshold;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    // Hiện nút khi scroll lên trên cách bottom hơn 200px
    final shouldShowJump = maxScroll - currentScroll > 200;
    if (shouldShowJump != _showJumpToPresent) {
      setState(() => _showJumpToPresent = shouldShowJump);
    }

    // "New Messages" banner: hiện khi có unread và user scroll lên
    final hasUnread = _hasUnreadMessages();
    final shouldShowBanner = hasUnread && (maxScroll - currentScroll > 100);
    if (shouldShowBanner != _showNewMessagesBanner) {
      setState(() => _showNewMessagesBanner = shouldShowBanner);
    }

    // Condition A: Tự đánh dấu đã đọc khi scroll xuống cuối
    if (_isNearBottom() && !_isNavigating) {
      _markAsRead();
    }

    // Pagination: Load more khi scroll gần đầu danh sách (trong 100px từ top)
    if (currentScroll < 100 && !_isLoadingMore && _hasMoreMessages) {
      _loadMoreMessages();
    }
  }

  /// Kiểm tra có tin nhắn chưa đọc không
  bool _hasUnreadMessages() {
    if (_lastReadMessageId == null || _visibleMessages.isEmpty) return false;
    final lastReadIndex = _visibleMessages.indexWhere(
      (m) => m.messageId == _lastReadMessageId,
    );
    if (lastReadIndex < 0) return true;
    return lastReadIndex < _visibleMessages.length - 1;
  }

  /// Cuộn xuống cuối danh sách tin nhắn
  /// [instant] = true: nhảy ngay không animate (dùng cho initial scroll)
  void _scrollToBottom({bool instant = false, int settleFrames = 2}) {
    final generation = _channelGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients ||
          !mounted ||
          generation != _channelGeneration) {
        return;
      }
      final target = _scrollController.position.maxScrollExtent;
      if (instant) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }

      if (settleFrames > 0) {
        Future<void>.delayed(const Duration(milliseconds: 60), () {
          if (!mounted || generation != _channelGeneration) return;
          _scrollToBottom(instant: true, settleFrames: settleFrames - 1);
        });
      }
    });
  }

  /// Lấy hoặc tạo GlobalKey cho tin nhắn
  GlobalKey _getMessageKey(String messageId) {
    return _messageKeys.putIfAbsent(messageId, () => GlobalKey());
  }

  /// Cuộn đến tin nhắn theo ID (dùng khi click reply preview)
  /// Sử dụng GlobalKey + Scrollable.ensureVisible để scroll chính xác
  void _scrollToMessage(
    String messageId, {
    double alignment = 0.3,
    bool highlight = true,
    int attempt = 0,
  }) {
    final key = _messageKeys[messageId];
    if (key?.currentContext == null) {
      // Key chưa mount — thử tìm trong visible messages và đợi frame tiếp theo
      final targetIndex = _visibleMessages.indexWhere(
        (m) => m.messageId == messageId,
      );
      if (targetIndex < 0) return;
      _jumpNearMessageIndex(targetIndex);
      if (attempt > 8) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToMessage(
          messageId,
          alignment: alignment,
          highlight: highlight,
          attempt: attempt + 1,
        );
      });
      return;
    }

    // Ngăn auto-scroll trong lúc đang navigate
    _isNavigating = true;

    // Bật highlight flash
    if (highlight) {
      setState(() {
        _highlightedMessageId = messageId;
      });
      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _highlightedMessageId = null;
          });
          _isNavigating = false;
        }
      });
    } else {
      _highlightTimer?.cancel();
      _highlightedMessageId = null;
      Timer(const Duration(milliseconds: 350), () {
        if (mounted) _isNavigating = false;
      });
    }

    // Scroll chính xác đến widget sử dụng ensureVisible
    Scrollable.ensureVisible(
      key!.currentContext!,
      alignment: alignment,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Gửi tin nhắn — có thể kèm reply và attachments
  void _jumpNearMessageIndex(int targetIndex) {
    if (!_scrollController.hasClients || _visibleMessages.isEmpty) return;
    final offset = _estimateScrollOffsetForIndex(targetIndex);
    _scrollController.jumpTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
    );
  }

  double _estimateScrollOffsetForIndex(int targetIndex) {
    var offset = 8.0;
    for (var i = 0; i < targetIndex && i < _visibleMessages.length; i++) {
      final message = _visibleMessages[i];
      offset +=
          _messageHeightCache[message.messageId] ??
          _estimateMessageHeight(message, i);
    }

    if (_newMessagesDividerAfterId != null) {
      final dividerAfterIndex = _visibleMessages.indexWhere(
        (m) => m.messageId == _newMessagesDividerAfterId,
      );
      if (dividerAfterIndex >= 0 && dividerAfterIndex < targetIndex) {
        offset += 34;
      }
    }

    if (_isLoadingMore) offset += 52;
    return offset;
  }

  double _estimateMessageHeight(MessageEntity message, int index) {
    var height = _shouldShowAvatar(_visibleMessages, index) ? 58.0 : 30.0;
    if (message.replyToMessageId != null) height += 28;
    if (message.content.isNotEmpty) {
      final extraLines = (message.content.length / 70).floor();
      height += extraLines * 18;
    }
    if (message.attachments.isNotEmpty) {
      height += message.attachments.any((a) => a.isImage) ? 180 : 72;
    }
    if (message.reactions.isNotEmpty) height += 30;
    return height.clamp(_estimatedMessageHeight, 320.0).toDouble();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    final hasAttachments = _pendingAttachments.isNotEmpty;
    if (content.isEmpty && !hasAttachments) return;

    final editingMessage = ref.read(editingMessageProvider);

    if (editingMessage != null) {
      // Đang edit tin nhắn
      if (content != editingMessage.content) {
        ref
            .read(messageNotifierProvider.notifier)
            .editMessage(
              serverId: widget.serverId,
              channelId: widget.channelId,
              messageId: editingMessage.messageId,
              newContent: content,
            );
      }
      ref.read(editingMessageProvider.notifier).state = null;
      _messageController.clear();
      _focusNode.requestFocus();
      return;
    }

    // Gửi tin nhắn mới
    final replyTo = ref.read(replyingToProvider);
    _isNavigating = false;
    _forceScrollToBottomOnNextMessage = true;

    ref
        .read(messageNotifierProvider.notifier)
        .sendMessage(
          serverId: widget.serverId,
          channelId: widget.channelId,
          content: content,
          replyToMessageId: replyTo?.messageId,
          attachments: _pendingAttachments,
        );

    _messageController.clear();
    setState(() => _pendingAttachments = []);
    ref.read(replyingToProvider.notifier).state = null;
    _focusNode.requestFocus();
  }

  /// Xử lý action từ hover toolbar hoặc context menu
  void _handleMessageAction(MessageAction action, MessageEntity message) {
    switch (action) {
      case MessageAction.reply:
        ref.read(replyingToProvider.notifier).state = message;
        ref.read(editingMessageProvider.notifier).state = null;
        _focusNode.requestFocus();
        break;
      case MessageAction.edit:
        ref.read(editingMessageProvider.notifier).state = message;
        ref.read(replyingToProvider.notifier).state = null;
        break;
      case MessageAction.delete:
        _showDeleteDialog(message);
        break;
      case MessageAction.pin:
        // Sẽ implement ở PART sau
        break;
    }
  }

  /// Hiển thị dialog xác nhận xóa tin nhắn
  void _showDeleteDialog(MessageEntity message) {
    showDialog(
      context: context,
      builder: (_) => DeleteConfirmDialog(
        onConfirm: () {
          ref
              .read(messageNotifierProvider.notifier)
              .deleteMessage(
                serverId: widget.serverId,
                channelId: widget.channelId,
                messageId: message.messageId,
              );
        },
      ),
    );
  }

  /// Chọn và upload ảnh đính kèm
  Future<void> _pickAndUploadAttachment() async {
    final ImagePicker picker = ImagePicker();

    // Hiển thị bottom sheet cho user chọn loại file
    final result = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: AppColors.bgFloating,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Đính kèm tệp', style: AppTextStyles.header3),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.brand),
              title: Text(
                'Chọn ảnh từ thư viện',
                style: AppTextStyles.bodySecondary,
              ),
              onTap: () async {
                final xFile = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1920,
                  maxHeight: 1920,
                  imageQuality: 90,
                );
                if (context.mounted) Navigator.of(context).pop(xFile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.brand),
              title: Text('Chụp ảnh mới', style: AppTextStyles.bodySecondary),
              onTap: () async {
                final xFile = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 1920,
                  maxHeight: 1920,
                  imageQuality: 90,
                );
                if (context.mounted) Navigator.of(context).pop(xFile);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (result == null) return;

    setState(() => _isUploading = true);

    try {
      final cloudinary = CloudinaryStorageDatasource();
      final imageUrl = await cloudinary.uploadImage(result);

      final fileName = result.name;
      final mimeType = _getMimeType(fileName);
      final fileSize = await result.length();

      setState(() {
        _pendingAttachments.add(
          AttachmentEntity(
            url: imageUrl,
            fileName: fileName,
            mimeType: mimeType,
            size: fileSize,
            kind: 'IMAGE',
          ),
        );
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ref
            .read(flashMessageProvider.notifier)
            .showError('Không thể tải lên tệp: $e');
      }
    }
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Lấy tin nhắn gốc cho reply preview (cache để giảm Firestore reads)
  Future<MessageEntity?> _getRepliedMessage(MessageEntity message) async {
    if (message.replyToMessageId == null) return null;
    final cacheKey =
        '${widget.serverId}/${widget.channelId}/${message.replyToMessageId}';
    if (_repliedMessageCache.containsKey(cacheKey)) {
      return _repliedMessageCache[cacheKey];
    }
    if (_sharedMessageCache.containsKey(cacheKey)) {
      final cached = _sharedMessageCache[cacheKey]!;
      _repliedMessageCache[cacheKey] = cached;
      return cached;
    }
    for (final visibleMessage in _visibleMessages) {
      if (visibleMessage.messageId == message.replyToMessageId) {
        _cacheMessage(cacheKey, visibleMessage);
        return visibleMessage;
      }
    }
    final replied = await ref
        .read(messageNotifierProvider.notifier)
        .getMessageById(
          serverId: widget.serverId,
          channelId: widget.channelId,
          messageId: message.replyToMessageId!,
        );
    if (replied != null) {
      _cacheMessage(cacheKey, replied);
    }
    return replied;
  }

  void _cacheMessage(String key, MessageEntity message) {
    _repliedMessageCache[key] = message;
    _sharedMessageCache[key] = message;
    if (_sharedMessageCache.length > _maxSharedMessageCacheEntries) {
      _sharedMessageCache.remove(_sharedMessageCache.keys.first);
    }
  }

  /// Fetch user data (username + avatarUrl) từ Firestore, có cache
  Future<_UserData> _getUserData(String senderId) async {
    if (_userDataCache.containsKey(senderId)) {
      return _userDataCache[senderId]!;
    }
    if (_sharedUserDataCache.containsKey(senderId)) {
      final cached = _sharedUserDataCache[senderId]!;
      _userDataCache[senderId] = cached;
      return cached;
    }
    final user = ref.read(authNotifierProvider).user;
    if (user?.uid == senderId) {
      final data = _UserData(
        username: user?.username ?? 'Bạn',
        avatarUrl: user?.avatarUrl ?? '',
      );
      _cacheUserData(senderId, data);
      return data;
    }

    // Fetch từ Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();
      if (doc.exists) {
        final data = _UserData(
          username: doc.data()?['username'] as String? ?? 'Người dùng',
          avatarUrl: doc.data()?['avatarUrl'] as String? ?? '',
        );
        _cacheUserData(senderId, data);
        return data;
      }
    } catch (_) {}
    return _UserData(username: 'Người dùng', avatarUrl: '');
  }

  void _cacheUserData(String userId, _UserData data) {
    _userDataCache[userId] = data;
    _sharedUserDataCache[userId] = data;
    if (_sharedUserDataCache.length > _maxSharedUserCacheEntries) {
      _sharedUserDataCache.remove(_sharedUserDataCache.keys.first);
    }
  }

  /// Lấy tên sender đồng bộ từ cache
  String _getSenderNameSync(String senderId) {
    final user = ref.read(authNotifierProvider).user;
    if (user?.uid == senderId) return user?.username ?? 'Bạn';
    return _userDataCache[senderId]?.username ??
        _sharedUserDataCache[senderId]?.username ??
        'Người dùng';
  }

  /// Preload user data vào cache
  void _preloadUserData(String senderId) {
    if (!_userDataCache.containsKey(senderId) &&
        !_sharedUserDataCache.containsKey(senderId)) {
      _getUserData(senderId);
    }
  }

  void _preloadVisibleUserData(List<MessageEntity> messages) {
    final ids = messages.map((m) => m.senderId).toSet();
    for (final id in ids) {
      _preloadUserData(id);
    }
  }

  /// Kiểm tra tin nhắn có liên quan đến current user không (mention hoặc reply)
  bool _isMessageRelevantToUser(MessageEntity message, String currentUserId) {
    if (message.mentionTargetIds.contains(currentUserId)) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(
      channelMessagesStreamProvider((
        serverId: widget.serverId,
        channelId: widget.channelId,
      )),
    );
    final messageState = ref.watch(messageNotifierProvider);
    final currentUserId = ref.read(authNotifierProvider).user?.uid ?? '';
    final replyingTo = ref.watch(replyingToProvider);
    final editingMessage = ref.watch(editingMessageProvider);
    final flashState = ref.watch(flashMessageProvider);

    // ESC key handler — scroll to bottom khi nhấn ESC
    // Shift+ESC — đánh dấu đã đọc ngay lập tức (Condition C)
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          final isShift = HardwareKeyboard.instance.isShiftPressed;
          if (isShift) {
            // Shift+Esc: Mark as read immediately
            _markAsReadImmediately();
          } else {
            // Esc: Scroll to bottom + mark as read
            _isNavigating = false;
            _scrollToBottom();
            _markAsRead();
          }
        }
      },
      child: Stack(
        children: [
          Column(
            children: [
              // Reply bar (hiển thị khi đang reply)
              if (replyingTo != null)
                ReplyBar(
                  currentUserId: currentUserId,
                  onNavigateToMessage: () {
                    _scrollToMessage(replyingTo.messageId);
                  },
                ),
              // Danh sách tin nhắn
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    // Lọc bỏ tin nhắn đã xóa từ stream
                    final streamMessages = messages
                        .where((m) => !m.isDeleted)
                        .toList();

                    // Gộp stream messages với older messages đã tải qua pagination
                    final visibleMessages = _mergeMessages(
                      _olderMessages,
                      streamMessages,
                    );

                    final wasNearBottom = _isNearBottom(threshold: 180);
                    final previousLastMessageId = _lastRenderedMessageId;
                    final nextLastMessageId = visibleMessages.isNotEmpty
                        ? visibleMessages.last.messageId
                        : null;
                    final hasNewLatest =
                        nextLastMessageId != null &&
                        previousLastMessageId != null &&
                        nextLastMessageId != previousLastMessageId;
                    final latestIsOwnMessage =
                        visibleMessages.isNotEmpty &&
                        visibleMessages.last.senderId == currentUserId;

                    final newCount = visibleMessages.length;
                    _previousMessageCount = newCount;
                    _lastRenderedMessageId = nextLastMessageId;
                    _visibleMessages = visibleMessages;

                    if (visibleMessages.isEmpty) {
                      return _buildEmptyState();
                    }

                    _preloadVisibleUserData(visibleMessages);

                    if (hasNewLatest && !_isNavigating && !_isLoadingMore) {
                      final shouldFollowNewMessage =
                          _forceScrollToBottomOnNextMessage ||
                          latestIsOwnMessage ||
                          wasNearBottom;
                      if (shouldFollowNewMessage) {
                        _forceScrollToBottomOnNextMessage = false;
                        _scrollToBottom();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_isNearBottom(threshold: 140)) _markAsRead();
                        });
                      }
                    }
                    return _buildMessageList(visibleMessages, currentUserId);
                  },
                  loading: () => const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.brand,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.red,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Không thể tải tin nhắn',
                          style: AppTextStyles.textMutedSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Input bar
              _buildInputBar(messageState, editingMessage),
            ],
          ),

          // Flash message overlay — hiển thị thông báo tạm thời
          if (flashState.isVisible && flashState.currentMessage != null)
            _buildFlashMessage(flashState),

          // "New Messages" banner — sticky top banner khi có unread và scroll lên
          if (_showNewMessagesBanner) _buildNewMessagesBanner(),

          // Jump to Present button — hiện khi scroll lên trên
          if (_showJumpToPresent)
            Positioned(
              bottom: 80,
              right: 24,
              child: _buildJumpToPresentButton(),
            ),
        ],
      ),
    );
  }

  /// Flash message overlay — hiển thị thông báo tạm thời trên màn hình
  Widget _buildFlashMessage(FlashMessageState flashState) {
    final message = flashState.currentMessage!;
    final color = _flashMessageColor(message.type);

    // Auto-hide sau 3 giây
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        ref.read(flashMessageProvider.notifier).hide();
      }
    });

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                _flashMessageIcon(message.type),
                size: 18,
                color: AppColors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message.message,
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => ref.read(flashMessageProvider.notifier).hide(),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _flashMessageColor(FlashMessageType type) {
    switch (type) {
      case FlashMessageType.success:
        return AppColors.green;
      case FlashMessageType.error:
        return AppColors.red;
      case FlashMessageType.warning:
        return AppColors.yellow;
      case FlashMessageType.info:
        return AppColors.brand;
    }
  }

  IconData _flashMessageIcon(FlashMessageType type) {
    switch (type) {
      case FlashMessageType.success:
        return Icons.check_circle;
      case FlashMessageType.error:
        return Icons.error;
      case FlashMessageType.warning:
        return Icons.warning;
      case FlashMessageType.info:
        return Icons.info;
    }
  }

  /// "New Messages" banner — sticky banner ở top khi có tin nhắn chưa đọc và user scroll lên
  /// Click để cuộn xuống "New Messages" divider
  Widget _buildNewMessagesBanner() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.red.withValues(alpha: 0.9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              // Cuộn xuống đến "New Messages" divider
              _scrollToNewMessagesDivider();
            },
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_downward,
                  size: 14,
                  color: AppColors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bạn có tin nhắn chưa đọc',
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  'Nhấn để xem',
                  style: AppTextStyles.textMutedSmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Cuộn đến "New Messages" divider trong danh sách tin nhắn
  void _scrollToNewMessagesDivider() {
    _scrollToFirstUnread();
  }

  /// Cuộn đến tin nhắn chưa đọc đầu tiên (ngay sau "New Messages" divider)
  /// Dùng khi mở unread channel hoặc nhấn banner "Bạn có tin nhắn chưa đọc"
  /// Sử dụng two-phase approach: estimate jump → ensureVisible
  void _scrollToFirstUnread() {
    if (_newMessagesDividerAfterId == null && !_newMessagesDividerBeforeFirst) {
      return;
    }
    if (_newMessagesDividerBeforeFirst) {
      if (_visibleMessages.isEmpty) return;
      final targetMessageId = _visibleMessages.first.messageId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToMessage(targetMessageId, alignment: 0.12, highlight: false);
      });
      return;
    }
    // Tìm message ngay sau divider
    final dividerIndex = _visibleMessages.indexWhere(
      (m) => m.messageId == _newMessagesDividerAfterId,
    );
    if (dividerIndex < 0 || dividerIndex + 1 >= _visibleMessages.length) return;

    final targetIndex = dividerIndex + 1;
    final targetMessageId = _visibleMessages[targetIndex].messageId;

    // Phase 1: Ước lượng vị trí scroll và nhảy đến đó
    // Điều này đảm bảo ListView xây dựng target message trong viewport
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToMessage(targetMessageId, alignment: 0.12, highlight: false);
    });
  }

  /// Nút "Jump to Present" — nhấn để cuộn xuống tin nhắn mới nhất
  Widget _buildJumpToPresentButton() {
    // Đếm số tin nhắn chưa đọc
    final unreadCount = _countUnreadMessages();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _isNavigating = false;
          _scrollToBottom();
          _markAsRead();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bgFloating,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: AppColors.brand,
              ),
              if (unreadCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Xem tin nhắn mới',
                  style: AppTextStyles.textMutedSmall.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Đếm số tin nhắn chưa đọc dựa trên lastReadMessageId
  int _countUnreadMessages() {
    if (_lastReadMessageId == null) return 0;
    final lastReadIndex = _visibleMessages.indexWhere(
      (m) => m.messageId == _lastReadMessageId,
    );
    if (lastReadIndex < 0) return _visibleMessages.length;
    return _visibleMessages.length - 1 - lastReadIndex;
  }

  /// Hiển thị khi chưa có tin nhắn nào
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.bgModifierHover,
              borderRadius: BorderRadius.circular(34),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.channelDefault,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Chưa có tin nhắn nào', style: AppTextStyles.welcomeTitle),
          const SizedBox(height: 8),
          const Text(
            'Hãy gửi tin nhắn đầu tiên!',
            style: AppTextStyles.welcomeSubtitle,
          ),
        ],
      ),
    );
  }

  /// Danh sách tin nhắn
  Widget _buildMessageList(List<MessageEntity> messages, String currentUserId) {
    // Discord-style: "New Messages" divider
    // Được set MỘT LẦN khi mở unread channel, biến mất khi markAsRead
    if (_hasLoadedReadStatus &&
        _lastReadMessageId != null &&
        !_hasSetNewMessagesDivider) {
      final lastReadIndex = messages.indexWhere(
        (m) => m.messageId == _lastReadMessageId,
      );
      if (lastReadIndex >= 0 && lastReadIndex < messages.length - 1) {
        // Chèn divider sau tin nhắn đã đọc cuối cùng
        _newMessagesDividerAfterId = messages[lastReadIndex].messageId;
      } else if (lastReadIndex < 0 && messages.isNotEmpty) {
        _newMessagesDividerBeforeFirst = true;
      }
      _hasSetNewMessagesDivider = true;
    }

    // Initial scroll: Sau khi read status đã load và messages sẵn sàng,
    // cuộn đến vị trí phù hợp (first unread hoặc bottom)
    // Dùng instant jump (không animate) để tránh flash/jank
    if (_hasLoadedReadStatus &&
        !_hasPerformedInitialScroll &&
        messages.isNotEmpty) {
      _hasPerformedInitialScroll = true;
      if (_newMessagesDividerAfterId != null ||
          _newMessagesDividerBeforeFirst) {
        // Có tin nhắn chưa đọc → cuộn đến first unread message (two-phase)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToFirstUnread();
        });
      } else {
        // Đã đọc hết hoặc chưa từng vào channel → cuộn xuống cuối (instant)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom(instant: true);
        });
      }
    }

    // Tìm vị trí divider trong danh sách hiện tại
    int? newMessagesDividerIndex;
    if (_newMessagesDividerBeforeFirst) {
      newMessagesDividerIndex = 0;
    } else if (_newMessagesDividerAfterId != null) {
      final dividerAfterIndex = messages.indexWhere(
        (m) => m.messageId == _newMessagesDividerAfterId,
      );
      if (dividerAfterIndex >= 0 && dividerAfterIndex < messages.length - 1) {
        newMessagesDividerIndex = dividerAfterIndex + 1;
      }
    }

    // Tính số item (thêm 1 nếu có divider, thêm 1 nếu đang load more)
    final hasDivider = newMessagesDividerIndex != null;
    final showLoadMore = _isLoadingMore;
    final totalItems =
        messages.length + (hasDivider ? 1 : 0) + (showLoadMore ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      cacheExtent: 1200,
      itemCount: totalItems,
      itemBuilder: (context, index) {
        // Loading spinner ở đầu danh sách (pagination)
        if (showLoadMore && index == 0) {
          return _buildLoadingMoreSpinner();
        }

        // Điều chỉnh index cho loading spinner
        final idx = showLoadMore ? index - 1 : index;

        // Hiển thị "New Messages" divider nếu cần
        if (hasDivider && idx == newMessagesDividerIndex) {
          return _buildNewMessagesDivider();
        }

        // Điều chỉnh index nếu có divider phía trước
        final messageIndex = hasDivider && idx > newMessagesDividerIndex!
            ? idx - 1
            : idx;
        final message = messages[messageIndex];
        final isOwnMessage = message.senderId == currentUserId;
        final showAvatar = _shouldShowAvatar(messages, messageIndex);
        final isMentioned = _isMessageRelevantToUser(message, currentUserId);
        final isHighlighted = _highlightedMessageId == message.messageId;
        final messageKey = _getMessageKey(message.messageId);

        return _MeasuredMessageItem(
          key: messageKey,
          onHeightChanged: (height) {
            _messageHeightCache[message.messageId] = height;
          },
          child: _MessageRow(
            message: message,
            isOwnMessage: isOwnMessage,
            showAvatar: showAvatar,
            currentUserId: currentUserId,
            isMentioned: isMentioned,
            isHighlighted: isHighlighted,
            onAction: (action) => _handleMessageAction(action, message),
            onQuickReaction: (emoji) {
              ref
                  .read(messageNotifierProvider.notifier)
                  .toggleReaction(
                    serverId: widget.serverId,
                    channelId: widget.channelId,
                    messageId: message.messageId,
                    emoji: emoji,
                  );
            },
            onReactionTapped: (emoji) {
              ref
                  .read(messageNotifierProvider.notifier)
                  .toggleReaction(
                    serverId: widget.serverId,
                    channelId: widget.channelId,
                    messageId: message.messageId,
                    emoji: emoji,
                  );
            },
            getSenderName: () =>
                _getUserData(message.senderId).then((u) => u.username),
            getSenderNameSync: () => _getSenderNameSync(message.senderId),
            getSenderAvatar: () =>
                _getUserData(message.senderId).then((u) => u.avatarUrl),
            getRepliedMessage: () => _getRepliedMessage(message),
            getUserDataCache: _userDataCache,
            onUserTap: () {
              UserProfileModal.showFromUid(context, uid: message.senderId);
            },
            onNavigateToMessage: (messageId) {
              _scrollToMessage(messageId);
            },
          ),
        );
      },
    );
  }

  /// "New Messages" divider — dòng phân cách đỏ giữa tin nhắn đã đọc và chưa đọc (Discord-style)
  /// Màu đỏ, có icon và text "Tin nhắn mới"
  Widget _buildNewMessagesDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: AppColors.red)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fiber_new, size: 14, color: AppColors.red),
                const SizedBox(width: 4),
                Text(
                  'Tin nhắn mới',
                  style: AppTextStyles.textMutedSmall.copyWith(
                    color: AppColors.red,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.02,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: Container(height: 1, color: AppColors.red)),
        ],
      ),
    );
  }

  /// Gộp older messages (pagination) với stream messages, dedup và sắp xếp
  List<MessageEntity> _mergeMessages(
    List<MessageEntity> older,
    List<MessageEntity> stream,
  ) {
    final seenIds = <String>{};
    final result = <MessageEntity>[];

    // Thêm older messages trước (đã lọc deleted)
    for (final msg in older) {
      if (!msg.isDeleted && seenIds.add(msg.messageId)) {
        result.add(msg);
      }
    }

    // Thêm stream messages (đã lọc deleted từ nơi gọi)
    for (final msg in stream) {
      if (seenIds.add(msg.messageId)) {
        result.add(msg);
      }
    }

    // Sắp xếp theo thời gian tạo
    result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }

  /// Tải thêm tin nhắn cũ hơn khi scroll lên đầu (pagination)
  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages || _visibleMessages.isEmpty) return;
    final generation = _channelGeneration;
    final serverId = widget.serverId;
    final channelId = widget.channelId;

    // Lưu scroll position để preserve sau khi prepend messages
    if (_scrollController.hasClients) {
      _savedScrollOffset = _scrollController.position.pixels;
      _savedMaxScrollExtent = _scrollController.position.maxScrollExtent;
    }

    setState(() => _isLoadingMore = true);

    // Lấy tin nhắn cũ nhất làm cursor
    final oldestMessage = _visibleMessages.first;

    final olderMessages = await ref
        .read(messageNotifierProvider.notifier)
        .getMessagesBefore(
          serverId: serverId,
          channelId: channelId,
          before: oldestMessage.createdAt,
          limit: 30,
        );

    if (mounted &&
        generation == _channelGeneration &&
        serverId == widget.serverId &&
        channelId == widget.channelId) {
      setState(() {
        _isLoadingMore = false;
        if (olderMessages.isEmpty) {
          _hasMoreMessages = false;
        } else {
          // Prepend older messages, dedup by messageId
          final existingIds = _olderMessages.map((m) => m.messageId).toSet();
          final newOlder = olderMessages
              .where((m) => !existingIds.contains(m.messageId))
              .toList();
          _olderMessages = [...newOlder, ..._olderMessages];
        }
      });

      // Preserve scroll position sau khi rebuild
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients &&
            _savedScrollOffset != null &&
            _savedMaxScrollExtent != null) {
          final newMaxScroll = _scrollController.position.maxScrollExtent;
          final delta = newMaxScroll - _savedMaxScrollExtent!;
          if (delta > 0) {
            _scrollController.jumpTo(_savedScrollOffset! + delta);
          }
          _savedScrollOffset = null;
          _savedMaxScrollExtent = null;
        }
      });
    }
  }

  /// Loading spinner hiển thị ở đầu danh sách khi đang tải tin nhắn cũ hơn
  Widget _buildLoadingMoreSpinner() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: AppColors.brand,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  /// Kiểm tra có nên hiển thị avatar không (ghép tin nhắn liên tiếp cùng người)
  bool _shouldShowAvatar(List<MessageEntity> messages, int index) {
    if (index == 0) return true;
    final prev = messages[index - 1];
    final curr = messages[index];
    if (prev.senderId != curr.senderId) return true;
    final diff = curr.createdAt.difference(prev.createdAt).inMinutes;
    return diff >= 5;
  }

  /// Thanh nhập tin nhắn (Discord-style)
  Widget _buildInputBar(
    MessageState messageState,
    MessageEntity? editingMessage,
  ) {
    final isEditing = editingMessage != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Edit indicator
        if (isEditing)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: AppColors.bgModifierHover,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              border: Border(
                left: BorderSide(color: AppColors.yellow, width: 3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit, size: 14, color: AppColors.yellow),
                const SizedBox(width: 6),
                Text(
                  'Đang chỉnh sửa tin nhắn',
                  style: AppTextStyles.textMutedSmall.copyWith(
                    color: AppColors.yellow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 14,
                    color: AppColors.interactiveNormal,
                  ),
                  onPressed: () {
                    ref.read(editingMessageProvider.notifier).state = null;
                    _messageController.clear();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        // Pending attachments preview
        if (_pendingAttachments.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            decoration: BoxDecoration(
              color: AppColors.bgModifierHover,
              borderRadius: BorderRadius.vertical(
                top: isEditing ? Radius.zero : const Radius.circular(8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Đính kèm (${_pendingAttachments.length})',
                      style: AppTextStyles.textMutedSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 14,
                        color: AppColors.interactiveNormal,
                      ),
                      onPressed: () {
                        setState(() => _pendingAttachments = []);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _pendingAttachments.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final att = entry.value;
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 100,
                              maxHeight: 100,
                            ),
                            child: Image.network(
                              att.url,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, __, ___) => Container(
                                width: 80,
                                height: 60,
                                color: AppColors.bgModifierActive,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _pendingAttachments.removeAt(idx);
                              });
                            },
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.scrim,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 12,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        // Input bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
            top: isEditing || _pendingAttachments.isNotEmpty ? 0 : 8,
            bottom: 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.only(
              topLeft: isEditing || _pendingAttachments.isNotEmpty
                  ? Radius.zero
                  : const Radius.circular(8),
              topRight: isEditing || _pendingAttachments.isNotEmpty
                  ? Radius.zero
                  : const Radius.circular(8),
              bottomLeft: const Radius.circular(8),
              bottomRight: const Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              // Nút thêm file đính kèm
              IconButton(
                icon: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: AppColors.interactiveNormal,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.add_circle_outline,
                        color: AppColors.interactiveNormal,
                        size: 22,
                      ),
                onPressed: _isUploading ? null : _pickAndUploadAttachment,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              // Input field
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  style: AppTextStyles.bodySecondary,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    hintText: isEditing
                        ? 'Chỉnh sửa tin nhắn...'
                        : 'Gửi tin nhắn...',
                    hintStyle: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              // Nút gửi
              if (messageState.isSending)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: AppColors.brand,
                    strokeWidth: 2,
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                    isEditing ? Icons.check : Icons.send,
                    color: isEditing
                        ? AppColors.green
                        : _pendingAttachments.isNotEmpty
                        ? AppColors.brand
                        : AppColors.interactiveNormal,
                    size: 20,
                  ),
                  onPressed: _sendMessage,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
/// Một hàng tin nhắn hoàn chỉnh (Discord-style hover, highlight, action toolbar)
// ──────────────────────────────────────────────────────────────────────
class _MeasuredMessageItem extends StatefulWidget {
  final Widget child;
  final ValueChanged<double> onHeightChanged;

  const _MeasuredMessageItem({
    super.key,
    required this.child,
    required this.onHeightChanged,
  });

  @override
  State<_MeasuredMessageItem> createState() => _MeasuredMessageItemState();
}

class _MeasuredMessageItemState extends State<_MeasuredMessageItem> {
  double? _lastHeight;

  @override
  void initState() {
    super.initState();
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(covariant _MeasuredMessageItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleMeasure();
  }

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderObject = context.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;
      final height = renderObject.size.height;
      if (_lastHeight == height) return;
      _lastHeight = height;
      widget.onHeightChanged(height);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _MessageRow extends ConsumerStatefulWidget {
  final MessageEntity message;
  final bool isOwnMessage;
  final bool showAvatar;
  final String currentUserId;
  final bool isMentioned;
  final bool isHighlighted;
  final ValueChanged<MessageAction> onAction;
  final ValueChanged<String> onQuickReaction;
  final ValueChanged<String> onReactionTapped;
  final Future<String> Function() getSenderName;
  final String Function() getSenderNameSync;
  final Future<String> Function() getSenderAvatar;
  final Future<MessageEntity?> Function() getRepliedMessage;
  final Map<String, _UserData> getUserDataCache;
  final VoidCallback onUserTap;
  final ValueChanged<String> onNavigateToMessage;

  const _MessageRow({
    super.key,
    required this.message,
    required this.isOwnMessage,
    required this.showAvatar,
    required this.currentUserId,
    required this.isMentioned,
    required this.isHighlighted,
    required this.onAction,
    required this.onQuickReaction,
    required this.onReactionTapped,
    required this.getSenderName,
    required this.getSenderNameSync,
    required this.getSenderAvatar,
    required this.getRepliedMessage,
    required this.getUserDataCache,
    required this.onUserTap,
    required this.onNavigateToMessage,
  });

  @override
  ConsumerState<_MessageRow> createState() => _MessageRowState();
}

class _MessageRowState extends ConsumerState<_MessageRow>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  // Animation cho highlight flash khi navigate đến tin nhắn
  late final AnimationController _highlightController;
  late final Animation<double> _highlightAnimation;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _highlightAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _highlightController, curve: Curves.easeOut),
    );
    if (widget.isHighlighted) {
      _highlightController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _MessageRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !oldWidget.isHighlighted) {
      // Bắt đầu highlight flash animation
      _highlightController.reset();
      _highlightController.forward();
    }
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPressStart: (details) =>
            _showContextMenuAt(details.globalPosition),
        onSecondaryTapDown: (details) =>
            _showContextMenuAt(details.globalPosition),
        child: Stack(
          children: [
            // Message row content
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              color: _isHovered
                  ? AppColors.bgModifierHover
                  : widget.isMentioned
                  ? AppColors.brand.withValues(alpha: 0.08)
                  : Colors.transparent,
              padding: EdgeInsets.only(
                left: 16,
                right: 60, // Space for hover toolbar
                top: widget.showAvatar ? 8 : 2,
                bottom: widget.showAvatar ? 0 : 2,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar hoặc khoảng trắng
                  _buildAvatarSection(),
                  const SizedBox(width: 16),
                  // Nội dung tin nhắn
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.showAvatar) _buildMessageHeader(),
                        // Reply preview (nếu tin nhắn này là reply)
                        if (msg.replyToMessageId != null) _buildReplyPreview(),
                        // Mention highlight indicator
                        if (widget.isMentioned) _buildMentionIndicator(),
                        // Nội dung
                        if (msg.content.isNotEmpty)
                          Text(msg.content, style: AppTextStyles.bodySecondary),
                        // Attachment
                        if (msg.attachments.isNotEmpty)
                          AttachmentDisplay(attachments: msg.attachments),
                        // Chỉnh sửa indicator
                        if (msg.isEdited)
                          Text(
                            '(đã chỉnh sửa)',
                            style: AppTextStyles.textMutedSmall.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        // Reactions
                        if (msg.reactions.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: ReactionDisplay(
                              reactions: msg.reactions,
                              currentUserId: widget.currentUserId,
                              onReactionTapped: widget.onReactionTapped,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Highlight flash overlay khi navigate đến tin nhắn này
            if (widget.isHighlighted)
              FadeTransition(
                opacity: _highlightAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.15),
                    border: Border(
                      left: BorderSide(
                        color: AppColors.brand.withValues(alpha: 0.6),
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ),
            // Hover toolbar (Discord-style — hiện khi hover vào message row)
            if (_isHovered)
              Positioned(
                top: widget.showAvatar ? 4 : 0,
                right: 16,
                child: _buildHoverToolbar(),
              ),
          ],
        ),
      ),
    );
  }

  /// Discord-style hover toolbar với các icon action
  void _showContextMenuAt(Offset position) {
    showMessageContextMenu(
      context: context,
      position: position,
      message: widget.message,
      isOwnMessage: widget.isOwnMessage,
      onAction: widget.onAction,
      onQuickReaction: widget.onQuickReaction,
    );
  }

  Widget _buildHoverToolbar() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.bgFloating,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.border, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quick reactions
              ...kQuickReactionEmojis.map(
                (emoji) => _toolbarButton(
                  child: Text(emoji, style: const TextStyle(fontSize: 16)),
                  onTap: () => widget.onQuickReaction(emoji),
                  tooltip: 'React $emoji',
                ),
              ),
              // Divider
              Container(
                width: 1,
                height: 18,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: AppColors.border,
              ),
              // Reply
              _toolbarButton(
                icon: Icons.reply_rounded,
                onTap: () => widget.onAction(MessageAction.reply),
                tooltip: 'Trả lời',
              ),
              // Edit (only for own messages)
              if (widget.isOwnMessage)
                _toolbarButton(
                  icon: Icons.edit_rounded,
                  onTap: () => widget.onAction(MessageAction.edit),
                  tooltip: 'Chỉnh sửa',
                ),
              // More actions
              _toolbarButton(
                icon: Icons.more_horiz,
                onTap: () => _showMoreActions(),
                tooltip: 'Thêm',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolbarButton({
    IconData? icon,
    Widget? child,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        hoverColor: AppColors.bgModifierHover,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, size: 18, color: AppColors.interactiveNormal)
              : child,
        ),
      ),
    );
  }

  /// Hiển thị thêm actions (Delete, Copy) khi click nút "..."
  void _showMoreActions() {
    // Lấy vị trí của widget hiện tại để đặt popup menu gần nút "..."
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + size.width - 180,
        offset.dy + 32,
        offset.dx + size.width,
        offset.dy + size.height,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'copy',
          height: 36,
          child: Row(
            children: [
              const Icon(
                Icons.copy_rounded,
                size: 16,
                color: AppColors.interactiveNormal,
              ),
              const SizedBox(width: 8),
              Text(
                'Sao chép nội dung',
                style: AppTextStyles.bodySecondary.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          height: 36,
          child: Row(
            children: [
              const Icon(
                Icons.delete_outline_rounded,
                size: 16,
                color: AppColors.red,
              ),
              const SizedBox(width: 8),
              Text(
                'Xóa tin nhắn',
                style: AppTextStyles.bodySecondary.copyWith(
                  fontSize: 13,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
        ),
      ],
      color: AppColors.bgFloating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      elevation: 8,
    ).then((value) {
      if (value == 'delete') {
        widget.onAction(MessageAction.delete);
      } else if (value == 'copy') {
        _copyMessageContent();
      }
    });
  }

  /// Sao chép nội dung tin nhắn vào clipboard
  void _copyMessageContent() {
    final content = widget.message.content;
    if (content.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: content));
      ref
          .read(flashMessageProvider.notifier)
          .showSuccess('Đã sao chép nội dung');
    }
  }

  /// Avatar hoặc khoảng trắng cho tin nhắn gộp
  Widget _buildAvatarSection() {
    if (widget.showAvatar) {
      return FutureBuilder<String>(
        future: widget.getSenderAvatar(),
        builder: (context, snapshot) {
          final avatarUrl = snapshot.data ?? '';
          return _AvatarWidget(
            senderId: widget.message.senderId,
            avatarUrl: avatarUrl,
            getSenderName: widget.getSenderName,
            size: 40,
            onTap: widget.onUserTap,
          );
        },
      );
    }
    // Tin nhắn gộp — hiển thị timestamp ẩn, hiện khi hover
    return SizedBox(
      width: 40,
      child: _isHovered
          ? Center(
              child: Text(
                DateFormat.Hm('vi_VN').format(widget.message.createdAt),
                style: AppTextStyles.textMutedSmall.copyWith(fontSize: 10),
                textAlign: TextAlign.center,
              ),
            )
          : null,
    );
  }

  /// Header tin nhắn: tên sender + thời gian
  Widget _buildMessageHeader() {
    final timeFormat = DateFormat.Hm('vi_VN');
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // Tên sender — click để xem profile
          GestureDetector(
            onTap: widget.onUserTap,
            child: FutureBuilder<String>(
              future: widget.getSenderName(),
              builder: (context, snapshot) {
                return Text(
                  snapshot.data ?? 'Người dùng',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.headerPrimary,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeFormat.format(widget.message.createdAt),
            style: AppTextStyles.textMutedSmall.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// Reply preview cho tin nhắn reply
  Widget _buildReplyPreview() {
    return FutureBuilder<MessageEntity?>(
      future: widget.getRepliedMessage(),
      builder: (context, snapshot) {
        final repliedMessage = snapshot.data;
        String? senderName;
        String? avatarUrl;
        if (repliedMessage != null) {
          // Preload user data cho sender của tin nhắn gốc
          final cache = widget.getUserDataCache;
          if (!cache.containsKey(repliedMessage.senderId)) {
            // Trigger preload
            FirebaseFirestore.instance
                .collection('users')
                .doc(repliedMessage.senderId)
                .get()
                .then((doc) {
                  if (doc.exists) {
                    cache[repliedMessage.senderId] = _UserData(
                      username:
                          doc.data()?['username'] as String? ?? 'Người dùng',
                      avatarUrl: doc.data()?['avatarUrl'] as String? ?? '',
                    );
                  }
                });
          }
          if (cache.containsKey(repliedMessage.senderId)) {
            senderName = cache[repliedMessage.senderId]!.username;
            avatarUrl = cache[repliedMessage.senderId]!.avatarUrl;
          } else {
            senderName = 'Người dùng';
          }
        }
        return ReplyPreview(
          repliedMessage: repliedMessage,
          senderName: senderName,
          avatarUrl: avatarUrl,
          onTap: repliedMessage != null
              ? () => widget.onNavigateToMessage(repliedMessage.messageId)
              : null,
        );
      },
    );
  }

  /// Chỉ báo mention — thanh dọc màu brand + text
  Widget _buildMentionIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.brand.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: AppColors.brand.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.alternate_email, size: 12, color: AppColors.brand),
          const SizedBox(width: 4),
          Text(
            'Bạn đã được nhắc đến',
            style: AppTextStyles.textMutedSmall.copyWith(
              color: AppColors.brand,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
/// Avatar widget — hỗ trợ ảnh từ URL hoặc chữ cái đầu
// ──────────────────────────────────────────────────────────────
class _AvatarWidget extends StatelessWidget {
  final String senderId;
  final String avatarUrl;
  final Future<String> Function() getSenderName;
  final double size;
  final VoidCallback? onTap;

  const _AvatarWidget({
    required this.senderId,
    required this.avatarUrl,
    required this.getSenderName,
    this.size = 40,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getSenderName(),
      builder: (context, snapshot) {
        return AppAvatar(
          imageUrl: avatarUrl,
          displayName: snapshot.data ?? senderId,
          size: size,
          onTap: onTap,
        );
      },
    );
  }

  Widget buildAvatarContent() {
    if (avatarUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: ClipOval(
          child: Image.network(
            avatarUrl,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => buildInitialAvatar(),
            loadingBuilder: (_, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return buildLoadingAvatar();
            },
          ),
        ),
      );
    }

    // Không có avatar URL — hiển thị chữ cái đầu
    return buildInitialAvatar();
  }

  Widget buildInitialAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.brand,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: FutureBuilder<String>(
        future: getSenderName(),
        builder: (context, snapshot) {
          final name = snapshot.data ?? '?';
          return Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              color: AppColors.white,
              fontSize: size * 0.45,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
    );
  }

  Widget buildLoadingAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.brand,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: size * 0.4,
        height: size * 0.4,
        child: const CircularProgressIndicator(
          color: AppColors.white,
          strokeWidth: 1.5,
        ),
      ),
    );
  }
}
