// lib/features/friend/presentation/providers/dm_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/dm_chat_entity.dart';
import '../../domain/entities/dm_message_entity.dart';
import '../../domain/repositories/dm_repository.dart';
import '../../domain/usecases/create_group_dm_usecase.dart';
import '../../domain/usecases/delete_dm_message_usecase.dart';
import '../../domain/usecases/get_dm_chats_usecase.dart';
import '../../domain/usecases/get_dm_messages_usecase.dart';
import '../../domain/usecases/get_or_create_dm_chat_usecase.dart';
import '../../domain/usecases/send_dm_message_usecase.dart';
import '../../domain/usecases/delete_dm_chat_usecase.dart';
import '../../domain/usecases/update_group_dm_usecase.dart';
import '../../data/datasources/dm_remote_datasource.dart';
import '../../data/repositories/dm_repository_impl.dart';

// ── Dependency Injection ───────────────────────────────────────

final _dmRemoteDatasourceProvider = Provider<DmRemoteDatasource>((ref) {
  return DmRemoteDatasourceImpl(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

final dmRepositoryProvider = Provider<DmRepository>((ref) {
  return DmRepositoryImpl(datasource: ref.watch(_dmRemoteDatasourceProvider));
});

// ── UseCase Providers ──────────────────────────────────────────

final getOrCreateDmChatUseCaseProvider = Provider<GetOrCreateDmChatUseCase>(
  (ref) => GetOrCreateDmChatUseCase(ref.watch(dmRepositoryProvider)),
);

final createGroupDmUseCaseProvider = Provider<CreateGroupDmUseCase>(
  (ref) => CreateGroupDmUseCase(ref.watch(dmRepositoryProvider)),
);

final sendDmMessageUseCaseProvider = Provider<SendDmMessageUseCase>(
  (ref) => SendDmMessageUseCase(ref.watch(dmRepositoryProvider)),
);

final getDmMessagesUseCaseProvider = Provider<GetDmMessagesUseCase>(
  (ref) => GetDmMessagesUseCase(ref.watch(dmRepositoryProvider)),
);

final deleteDmMessageUseCaseProvider = Provider<DeleteDmMessageUseCase>(
  (ref) => DeleteDmMessageUseCase(ref.watch(dmRepositoryProvider)),
);

final getDmChatsUseCaseProvider = Provider<GetDmChatsUseCase>(
  (ref) => GetDmChatsUseCase(ref.watch(dmRepositoryProvider)),
);

final deleteDmChatUseCaseProvider = Provider<DeleteDmChatUseCase>(
  (ref) => DeleteDmChatUseCase(ref.watch(dmRepositoryProvider)),
);

final updateGroupDmUseCaseProvider = Provider<UpdateGroupDmUseCase>(
  (ref) => UpdateGroupDmUseCase(ref.watch(dmRepositoryProvider)),
);

// ── Stream Providers ───────────────────────────────────────────

/// Stream danh sách DM chats của current user, sắp xếp theo lastMessageAt.
final dmChatsStreamProvider = StreamProvider<List<DmChatEntity>>((ref) async* {
  final userId = ref.watch(authNotifierProvider).user?.uid;
  if (userId == null) {
    yield [];
    return;
  }
  final useCase = ref.watch(getDmChatsUseCaseProvider);
  final stream = useCase(GetDmChatsParams(userId: userId));

  await for (final result in stream) {
    yield result.fold(ifLeft: (_) => [], ifRight: (list) => list);
  }
});

/// Stream tin nhắn DM của một chat cụ thể.
/// Dùng family để nhận chatId.
final dmMessagesStreamProvider = StreamProvider.family<List<DmMessageEntity>, String>(
  (ref, chatId) async* {
    if (chatId.isEmpty) {
      yield [];
      return;
    }
    final useCase = ref.watch(getDmMessagesUseCaseProvider);
    final stream = useCase(GetDmMessagesParams(chatId: chatId));

    await for (final result in stream) {
      yield result.fold(ifLeft: (_) => [], ifRight: (list) => list);
    }
  },
);

// ── State Classes ──────────────────────────────────────────────

class DmChatState {
  final bool isLoading;
  final String? error;
  final String? navigateToChatId;

  const DmChatState({
    this.isLoading = false,
    this.error,
    this.navigateToChatId,
  });

  DmChatState copyWith({
    bool? isLoading,
    String? error,
    String? navigateToChatId,
  }) {
    return DmChatState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      navigateToChatId: navigateToChatId ?? this.navigateToChatId,
    );
  }
}

class DmMessageState {
  final bool isSending;
  final String? error;

  const DmMessageState({this.isSending = false, this.error});

  DmMessageState copyWith({bool? isSending, String? error}) {
    return DmMessageState(
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

// ── Notifiers ──────────────────────────────────────────────────

/// Notifier quản lý việc mở/tạo DM chat.
class DmChatNotifier extends StateNotifier<DmChatState> {
  final GetOrCreateDmChatUseCase _getOrCreate;
  final CreateGroupDmUseCase _createGroup;
  final DeleteDmChatUseCase _deleteDmChat;
  final UpdateGroupDmUseCase _updateGroupDm;
  final Ref _ref;

  DmChatNotifier({
    required GetOrCreateDmChatUseCase getOrCreate,
    required CreateGroupDmUseCase createGroup,
    required DeleteDmChatUseCase deleteDmChat,
    required UpdateGroupDmUseCase updateGroupDm,
    required Ref ref,
  }) : _getOrCreate = getOrCreate,
       _createGroup = createGroup,
       _deleteDmChat = deleteDmChat,
       _updateGroupDm = updateGroupDm,
       _ref = ref,
       super(const DmChatState());

  /// Mở hoặc tạo DM 1-1 với user khác.
  Future<String?> openDmWith(String otherUserId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _getOrCreate(
      GetOrCreateDmChatParams(otherUserId: otherUserId),
    );
    return result.fold(
      ifLeft: (f) {
        state = state.copyWith(isLoading: false, error: f.message);
        return null;
      },
      ifRight: (chatId) {
        state = state.copyWith(
          isLoading: false,
          navigateToChatId: chatId,
        );
        return chatId;
      },
    );
  }

  /// Tạo Group DM.
  Future<DmChatEntity?> createGroupDm({
    required List<String> participantIds,
    required String name,
    String? iconUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _createGroup(
      CreateGroupDmParams(
        participantIds: participantIds,
        name: name,
        iconUrl: iconUrl,
      ),
    );
    return result.fold(
      ifLeft: (f) {
        state = state.copyWith(isLoading: false, error: f.message);
        return null;
      },
      ifRight: (chat) {
        state = state.copyWith(
          isLoading: false,
          navigateToChatId: chat.chatId,
        );
        return chat;
      },
    );
  }

  void clearNavigation() {
    state = DmChatState(isLoading: false, error: state.error);
  }

  /// Xóa cuộc hội thoại DM.
  Future<bool> deleteDmChat(String chatId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _deleteDmChat(DeleteDmChatParams(chatId: chatId));
    return result.fold(
      ifLeft: (f) {
        state = state.copyWith(isLoading: false, error: f.message);
        return false;
      },
      ifRight: (_) {
        state = state.copyWith(isLoading: false);
        return true;
      },
    );
  }

  /// Cập nhật thông tin Group DM.
  Future<bool> updateGroupDm({
    required String chatId,
    required String name,
    String? iconUrl,
    List<String>? participantIds,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _updateGroupDm(
      UpdateGroupDmParams(
        chatId: chatId,
        name: name,
        iconUrl: iconUrl,
        participantIds: participantIds,
      ),
    );
    return result.fold(
      ifLeft: (f) {
        state = state.copyWith(isLoading: false, error: f.message);
        return false;
      },
      ifRight: (_) {
        state = state.copyWith(isLoading: false);
        _ref.invalidate(dmChatDetailProvider(chatId));
        return true;
      },
    );
  }
}

/// Notifier quản lý gửi/xóa tin nhắn DM.
class DmMessageNotifier extends StateNotifier<DmMessageState> {
  final SendDmMessageUseCase _sendMessage;
  final DeleteDmMessageUseCase _deleteMessage;

  DmMessageNotifier({
    required SendDmMessageUseCase sendMessage,
    required DeleteDmMessageUseCase deleteMessage,
  }) : _sendMessage = sendMessage,
       _deleteMessage = deleteMessage,
       super(const DmMessageState());

  Future<bool> sendMessage({
    required String chatId,
    required String content,
    String? replyToMessageId,
  }) async {
    state = state.copyWith(isSending: true, error: null);
    final result = await _sendMessage(
      SendDmMessageParams(
        chatId: chatId,
        content: content,
        replyToMessageId: replyToMessageId,
      ),
    );
    return result.fold(
      ifLeft: (f) {
        state = state.copyWith(isSending: false, error: f.message);
        return false;
      },
      ifRight: (_) {
        state = state.copyWith(isSending: false);
        return true;
      },
    );
  }

  Future<bool> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    final result = await _deleteMessage(
      DeleteDmMessageParams(chatId: chatId, messageId: messageId),
    );
    return result.fold(
      ifLeft: (f) {
        state = state.copyWith(error: f.message);
        return false;
      },
      ifRight: (_) => true,
    );
  }
}

// ── Provider Definitions ───────────────────────────────────────

final dmChatNotifierProvider =
    StateNotifierProvider<DmChatNotifier, DmChatState>((ref) {
      return DmChatNotifier(
        getOrCreate: ref.watch(getOrCreateDmChatUseCaseProvider),
        createGroup: ref.watch(createGroupDmUseCaseProvider),
        deleteDmChat: ref.watch(deleteDmChatUseCaseProvider),
        updateGroupDm: ref.watch(updateGroupDmUseCaseProvider),
        ref: ref,
      );
    });

final dmMessageNotifierProvider =
    StateNotifierProvider<DmMessageNotifier, DmMessageState>((ref) {
      return DmMessageNotifier(
        sendMessage: ref.watch(sendDmMessageUseCaseProvider),
        deleteMessage: ref.watch(deleteDmMessageUseCaseProvider),
      );
    });

/// Provider lấy thông tin một DmChat cụ thể.
final dmChatDetailProvider = FutureProvider.family<DmChatEntity?, String>(
  (ref, chatId) async {
    if (chatId.isEmpty) return null;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('userChats')
          .doc(chatId)
          .get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return DmChatEntity(
        chatId: chatId,
        type: data['type'] == 'GROUP_DM' ? DmChatType.groupDm : DmChatType.dm,
        participants: List<String>.from(data['participants'] as List? ?? []),
        name: data['name'] as String? ?? '',
        iconUrl: data['iconUrl'] as String?,
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
        lastMessagePreview: data['lastMessagePreview'] as String? ?? '',
      );
    } catch (e) {
      return null;
    }
  },
);
