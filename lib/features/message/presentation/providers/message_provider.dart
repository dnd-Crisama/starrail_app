import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/message_repository.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/delete_message_usecase.dart';
import '../../domain/usecases/edit_message_usecase.dart';
import '../../domain/usecases/get_messages_before_usecase.dart';
import '../../domain/usecases/toggle_reaction_usecase.dart';
import '../../domain/usecases/get_message_by_id_usecase.dart';
import '../../data/datasources/message_remote_datasource.dart';
import '../../data/repositories/message_repository_impl.dart';
import '../../../server/domain/entities/channel_entity.dart';
import '../../../server/presentation/providers/channel_provider.dart'
    show serverChannelsStreamProvider;

// ── Dependency Injection ─────────────────────────────────────

final _messageRemoteDatasourceProvider = Provider<MessageRemoteDatasource>((
  ref,
) {
  return MessageRemoteDatasource(firestore: FirebaseFirestore.instance);
});

final _messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepositoryImpl(
    remoteDatasource: ref.watch(_messageRemoteDatasourceProvider),
  );
});

final _sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.watch(_messageRepositoryProvider));
});

final _deleteMessageUseCaseProvider = Provider<DeleteMessageUseCase>((ref) {
  return DeleteMessageUseCase(ref.watch(_messageRepositoryProvider));
});

final _editMessageUseCaseProvider = Provider<EditMessageUseCase>((ref) {
  return EditMessageUseCase(ref.watch(_messageRepositoryProvider));
});

final _getMessagesBeforeUseCaseProvider = Provider<GetMessagesBeforeUseCase>((
  ref,
) {
  return GetMessagesBeforeUseCase(ref.watch(_messageRepositoryProvider));
});

final _toggleReactionUseCaseProvider = Provider<ToggleReactionUseCase>((ref) {
  return ToggleReactionUseCase(ref.watch(_messageRepositoryProvider));
});

final _getMessageByIdUseCaseProvider = Provider<GetMessageByIdUseCase>((ref) {
  return GetMessageByIdUseCase(ref.watch(_messageRepositoryProvider));
});

// ── Stream messages cho channel ─────────────────────────────

/// Stream tin nhắn real-time cho channel đang chọn
final channelMessagesStreamProvider =
    StreamProvider.family<
      List<MessageEntity>,
      ({String serverId, String channelId})
    >((ref, params) {
      final repo = ref.watch(_messageRepositoryProvider);
      return repo.getMessagesStream(
        serverId: params.serverId,
        channelId: params.channelId,
        limit: 30,
      );
    });

// ── Reply state ─────────────────────────────────────────────

/// Tin nhắn đang được reply (null nếu không reply ai)
final replyingToProvider = StateProvider<MessageEntity?>((ref) => null);

/// Tin nhắn đang được edit (null nếu không edit)
final editingMessageProvider = StateProvider<MessageEntity?>((ref) => null);

// ── Read Status — Discord-style Unread System ──────────────

/// Lưu lastReadMessageId cho mỗi channel (để xác định tin nhắn chưa đọc)
/// Optimistic — cập nhật ngay trên UI, debounce ghi Firestore
final channelReadStatusProvider =
    StateProvider.family<String?, ({String serverId, String channelId})>(
      (ref, params) => null,
    );

/// Trạng thái đã đọc cho TẤT CẢ channel của user (load từ Firestore khi mở app)
/// Map key: "serverId/channelId" → lastReadMessageId
/// NOTE: Đây chỉ là bản sao legacy — dùng unreadStatusNotifierProvider làm nguồn chân lý.
final allChannelReadStatusProvider = StateProvider<Map<String, String>>((ref) {
  // Đồng bộ từ UnreadStatusNotifier để giữ tương thích ngược
  return ref.watch(unreadStatusNotifierProvider);
});

/// Trạng thái có tin nhắn chưa đọc cho mỗi channel
/// Map key: "serverId/channelId" → bool (true = có tin nhắn chưa đọc)
/// Sử dụng unreadStatusNotifierProvider làm nguồn chân lý cho read status
final channelUnreadProvider =
    StateProvider.family<bool, ({String serverId, String channelId})>((
      ref,
      params,
    ) {
      // Lấy lastReadMessageId từ UnreadStatusNotifier (optimistic + debounced)
      final readStatus = ref.watch(unreadStatusNotifierProvider);
      final key = '${params.serverId}/${params.channelId}';
      final lastReadId = readStatus[key];
      if (lastReadId == null)
        return false; // Chưa từng vào channel → không hiện unread

      // Kiểm tra xem stream có message mới hơn không
      final messagesAsync = ref.watch(channelMessagesStreamProvider(params));
      return messagesAsync.when(
        data: (messages) {
          if (messages.isEmpty) return false;
          // Channel unread nếu có tin nhắn sau lastReadId
          final lastReadIndex = messages.indexWhere(
            (m) => m.messageId == lastReadId,
          );
          if (lastReadIndex < 0)
            return true; // lastReadId không còn trong list → có tin mới
          return lastReadIndex < messages.length - 1; // có tin sau lastRead
        },
        loading: () => false,
        error: (_, __) => false,
      );
    });

/// Đếm số tin nhắn chưa đọc cho một channel
/// Sử dụng unreadStatusNotifierProvider làm nguồn chân lý
final channelUnreadCountProvider =
    StateProvider.family<int, ({String serverId, String channelId})>((
      ref,
      params,
    ) {
      final readStatus = ref.watch(unreadStatusNotifierProvider);
      final key = '${params.serverId}/${params.channelId}';
      final lastReadId = readStatus[key];

      final messagesAsync = ref.watch(channelMessagesStreamProvider(params));
      return messagesAsync.when(
        data: (messages) {
          if (messages.isEmpty) return 0;
          if (lastReadId == null) return 0;
          final lastReadIndex = messages.indexWhere(
            (m) => m.messageId == lastReadId,
          );
          if (lastReadIndex < 0) return 0;
          return messages.length - 1 - lastReadIndex;
        },
        loading: () => 0,
        error: (_, __) => 0,
      );
    });

/// Kiểm tra server có bất kỳ channel nào chưa đọc
/// Reactive: tự cập nhật khi read status hoặc message stream thay đổi
final serverHasUnreadProvider = Provider.family<bool, String>((ref, serverId) {
  final readStatus = ref.watch(unreadStatusNotifierProvider);
  final channelsState = ref.watch(serverChannelsStreamProvider(serverId));

  return channelsState.when(
    data: (channels) {
      for (final channel in channels) {
        if (channel.type != ChannelType.text) continue;
        final key = '$serverId/${channel.channelId}';
        final lastReadId = readStatus[key];
        if (lastReadId == null) continue; // Chưa từng vào → không tính unread

        // Kiểm tra stream messages cho channel này
        final messagesAsync = ref.watch(
          channelMessagesStreamProvider((
            serverId: serverId,
            channelId: channel.channelId,
          )),
        );
        final hasUnread = messagesAsync.when(
          data: (messages) {
            if (messages.isEmpty) return false;
            final lastReadIndex = messages.indexWhere(
              (m) => m.messageId == lastReadId,
            );
            return lastReadIndex < 0 || lastReadIndex < messages.length - 1;
          },
          loading: () => false,
          error: (_, __) => false,
        );
        if (hasUnread) return true;
      }
      return false;
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Notifier quản lý read status toàn cục — load từ Firestore, debounce ghi
class UnreadStatusNotifier extends StateNotifier<Map<String, String>> {
  final MessageRepository _repository;
  Timer? _debounceTimer;
  final Map<String, String> _pendingWrites = {}; // Các ghi đang chờ debounce

  UnreadStatusNotifier({required MessageRepository repository})
    : _repository = repository,
      super({});

  /// Load toàn bộ read status cho tất cả channel của một server
  Future<void> loadReadStatusForServer(String serverId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      // Lấy danh sách channels
      final channelsSnapshot = await FirebaseFirestore.instance
          .collection('servers')
          .doc(serverId)
          .collection('channels')
          .get();

      for (final channelDoc in channelsSnapshot.docs) {
        final channelId = channelDoc.id;
        final key = '$serverId/$channelId';

        final doc = await FirebaseFirestore.instance
            .collection('servers')
            .doc(serverId)
            .collection('channels')
            .doc(channelId)
            .collection('readStatus')
            .doc(userId)
            .get();

        if (doc.exists) {
          final lastReadId = doc.data()?['lastReadMessageId'] as String?;
          if (lastReadId != null) {
            state = {...state, key: lastReadId};
          }
        }
      }
    } catch (_) {}
  }

  /// Optimistic update + debounce ghi Firestore
  void markAsRead({
    required String serverId,
    required String channelId,
    required String lastReadMessageId,
  }) {
    final key = '$serverId/$channelId';

    // Optimistic — cập nhật UI ngay
    state = {...state, key: lastReadMessageId};

    // Debounce — gom nhiều lần gọi thành 1 ghi Firestore
    _pendingWrites[key] = lastReadMessageId;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _flushPendingWrites();
    });
  }

  /// Ghi tất cả pending writes lên Firestore
  Future<void> _flushPendingWrites() async {
    if (_pendingWrites.isEmpty) return;
    final writes = Map<String, String>.from(_pendingWrites);
    _pendingWrites.clear();

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    for (final entry in writes.entries) {
      final parts = entry.key.split('/');
      if (parts.length != 2) continue;
      final serverId = parts[0];
      final channelId = parts[1];

      try {
        await _repository.markChannelAsRead(
          serverId: serverId,
          channelId: channelId,
          userId: userId,
          lastReadMessageId: entry.value,
        );
      } catch (_) {}
    }
  }

  /// Force flush — gọi khi thoát channel hoặc dispose
  Future<void> flush() async {
    _debounceTimer?.cancel();
    await _flushPendingWrites();
  }

  /// Lấy lastReadMessageId cho channel
  String? getLastReadMessageId(String serverId, String channelId) {
    final key = '$serverId/$channelId';
    return state[key];
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _flushPendingWrites();
    super.dispose();
  }
}

final unreadStatusNotifierProvider =
    StateNotifierProvider<UnreadStatusNotifier, Map<String, String>>((ref) {
      return UnreadStatusNotifier(
        repository: ref.watch(_messageRepositoryProvider),
      );
    });

// ── Flash Message ───────────────────────────────────────────

/// Flash message hiển thị thông báo tạm thời trên màn hình
class FlashMessage {
  final String message;
  final FlashMessageType type;
  final DateTime timestamp;

  const FlashMessage({
    required this.message,
    required this.type,
    required this.timestamp,
  });
}

enum FlashMessageType { success, error, info, warning }

class FlashMessageState {
  final FlashMessage? currentMessage;
  final bool isVisible;

  const FlashMessageState({this.currentMessage, this.isVisible = false});

  FlashMessageState copyWith({FlashMessage? currentMessage, bool? isVisible}) {
    return FlashMessageState(
      currentMessage: currentMessage ?? this.currentMessage,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

class FlashMessageNotifier extends StateNotifier<FlashMessageState> {
  FlashMessageNotifier() : super(const FlashMessageState());

  /// Hiển thị flash message
  void show(String message, {FlashMessageType type = FlashMessageType.info}) {
    state = FlashMessageState(
      currentMessage: FlashMessage(
        message: message,
        type: type,
        timestamp: DateTime.now(),
      ),
      isVisible: true,
    );
  }

  /// Ẩn flash message
  void hide() {
    state = state.copyWith(isVisible: false);
  }

  /// Hiển thị thông báo thành công
  void showSuccess(String message) =>
      show(message, type: FlashMessageType.success);

  /// Hiển thị thông báo lỗi
  void showError(String message) => show(message, type: FlashMessageType.error);

  /// Hiển thị thông báo cảnh báo
  void showWarning(String message) =>
      show(message, type: FlashMessageType.warning);

  /// Hiển thị thông báo thông tin
  void showInfo(String message) => show(message, type: FlashMessageType.info);
}

final flashMessageProvider =
    StateNotifierProvider<FlashMessageNotifier, FlashMessageState>((ref) {
      return FlashMessageNotifier();
    });

// ── Message Notifier ────────────────────────────────────────

class MessageState {
  final bool isSending;
  final String? errorMessage;

  const MessageState({this.isSending = false, this.errorMessage});

  MessageState copyWith({bool? isSending, String? errorMessage}) {
    return MessageState(
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
    );
  }
}

class MessageNotifier extends StateNotifier<MessageState> {
  final SendMessageUseCase _sendMessageUseCase;
  final DeleteMessageUseCase _deleteMessageUseCase;
  final EditMessageUseCase _editMessageUseCase;
  final ToggleReactionUseCase _toggleReactionUseCase;
  final GetMessageByIdUseCase _getMessageByIdUseCase;
  final MessageRepository _repository;

  MessageNotifier({
    required SendMessageUseCase sendMessageUseCase,
    required DeleteMessageUseCase deleteMessageUseCase,
    required EditMessageUseCase editMessageUseCase,
    required ToggleReactionUseCase toggleReactionUseCase,
    required GetMessageByIdUseCase getMessageByIdUseCase,
    required MessageRepository repository,
  }) : _sendMessageUseCase = sendMessageUseCase,
       _deleteMessageUseCase = deleteMessageUseCase,
       _editMessageUseCase = editMessageUseCase,
       _toggleReactionUseCase = toggleReactionUseCase,
       _getMessageByIdUseCase = getMessageByIdUseCase,
       _repository = repository,
       super(const MessageState());

  /// Gửi tin nhắn mới — hỗ trợ gửi chỉ attachment, chỉ text, hoặc cả hai
  Future<void> sendMessage({
    required String serverId,
    required String channelId,
    required String content,
    List<String> mentionTargetIds = const [],
    String? replyToMessageId,
    List<AttachmentEntity> attachments = const [],
  }) async {
    final senderId = FirebaseAuth.instance.currentUser?.uid;
    if (senderId == null) return;
    // Cho phép gửi khi có attachment (không cần nội dung text) hoặc khi có text
    final hasContent = content.trim().isNotEmpty;
    final hasAttachments = attachments.isNotEmpty;
    if (!hasContent && !hasAttachments) return;

    state = state.copyWith(isSending: true, errorMessage: null);

    // Tự xác định message type dựa trên attachment
    MessageType messageType = MessageType.text;
    if (hasAttachments && !hasContent) {
      // Chỉ có attachment, không có text → xác định type theo loại attachment
      final firstKind = attachments.first.kind;
      if (firstKind == 'IMAGE') {
        messageType = MessageType.image;
      } else {
        messageType = MessageType.file;
      }
    }

    final result = await _sendMessageUseCase(
      SendMessageParams(
        serverId: serverId,
        channelId: channelId,
        senderId: senderId,
        content: content.trim(),
        type: messageType,
        mentionTargetIds: mentionTargetIds,
        replyToMessageId: replyToMessageId,
        attachments: attachments,
      ),
    );

    result.fold(
      ifLeft: (failure) => state = state.copyWith(
        isSending: false,
        errorMessage: failure.message,
      ),
      ifRight: (_) => state = state.copyWith(isSending: false),
    );
  }

  /// Xóa mềm tin nhắn
  Future<void> deleteMessage({
    required String serverId,
    required String channelId,
    required String messageId,
  }) async {
    await _deleteMessageUseCase(
      DeleteMessageParams(
        serverId: serverId,
        channelId: channelId,
        messageId: messageId,
      ),
    );
  }

  /// Sửa nội dung tin nhắn
  Future<void> editMessage({
    required String serverId,
    required String channelId,
    required String messageId,
    required String newContent,
  }) async {
    await _editMessageUseCase(
      EditMessageParams(
        serverId: serverId,
        channelId: channelId,
        messageId: messageId,
        newContent: newContent,
      ),
    );
  }

  /// Toggle reaction trên tin nhắn
  Future<void> toggleReaction({
    required String serverId,
    required String channelId,
    required String messageId,
    required String emoji,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await _toggleReactionUseCase(
      ToggleReactionParams(
        serverId: serverId,
        channelId: channelId,
        messageId: messageId,
        emoji: emoji,
        userId: userId,
      ),
    );
  }

  /// Lấy tin nhắn theo ID (dùng cho reply preview)
  Future<MessageEntity?> getMessageById({
    required String serverId,
    required String channelId,
    required String messageId,
  }) async {
    final result = await _getMessageByIdUseCase(
      GetMessageByIdParams(
        serverId: serverId,
        channelId: channelId,
        messageId: messageId,
      ),
    );

    return result.fold(ifLeft: (_) => null, ifRight: (message) => message);
  }

  /// Đánh dấu channel đã đọc — cập nhật lastReadMessageId lên Firestore
  Future<void> markChannelAsRead({
    required String serverId,
    required String channelId,
    required String lastReadMessageId,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await _repository.markChannelAsRead(
      serverId: serverId,
      channelId: channelId,
      userId: userId,
      lastReadMessageId: lastReadMessageId,
    );
  }

  /// Lấy lastReadMessageId cho user trong channel
  Future<String?> getLastReadMessageId({
    required String serverId,
    required String channelId,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    final result = await _repository.getLastReadMessageId(
      serverId: serverId,
      channelId: channelId,
      userId: userId,
    );

    return result.fold(ifLeft: (_) => null, ifRight: (id) => id);
  }

  /// Tải thêm tin nhắn cũ hơn cho pagination
  /// Trả về danh sách tin nhắn trước thời gian [before]
  Future<List<MessageEntity>> getMessagesBefore({
    required String serverId,
    required String channelId,
    required DateTime before,
    int limit = 30,
  }) async {
    final result = await _repository.getMessagesBefore(
      serverId: serverId,
      channelId: channelId,
      lastMessageCreatedAt: before,
      limit: limit,
    );

    return result.fold(ifLeft: (_) => [], ifRight: (messages) => messages);
  }
}

final messageNotifierProvider =
    StateNotifierProvider<MessageNotifier, MessageState>((ref) {
      return MessageNotifier(
        sendMessageUseCase: ref.watch(_sendMessageUseCaseProvider),
        deleteMessageUseCase: ref.watch(_deleteMessageUseCaseProvider),
        editMessageUseCase: ref.watch(_editMessageUseCaseProvider),
        toggleReactionUseCase: ref.watch(_toggleReactionUseCaseProvider),
        getMessageByIdUseCase: ref.watch(_getMessageByIdUseCaseProvider),
        repository: ref.watch(_messageRepositoryProvider),
      );
    });
