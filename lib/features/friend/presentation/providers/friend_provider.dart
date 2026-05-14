// lib/features/friend/presentation/providers/friend_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/friendship_entity.dart';
import '../../domain/repositories/friend_repository.dart';
import '../../domain/usecases/accept_friend_request_usecase.dart';
import '../../domain/usecases/block_user_usecase.dart';
import '../../domain/usecases/cancel_friend_request_usecase.dart';
import '../../domain/usecases/decline_friend_request_usecase.dart';
import '../../domain/usecases/get_friends_usecase.dart';
import '../../domain/usecases/get_incoming_requests_usecase.dart';
import '../../domain/usecases/get_outgoing_requests_usecase.dart';
import '../../domain/usecases/remove_friend_usecase.dart';
import '../../domain/usecases/search_users_usecase.dart';
import '../../domain/usecases/send_friend_request_usecase.dart';
import '../../data/datasources/friend_remote_datasource.dart';
import '../../data/repositories/friend_repository_impl.dart';

// ── Dependency Injection ───────────────────────────────────────

final _friendRemoteDatasourceProvider = Provider<FriendRemoteDatasource>((ref) {
  return FriendRemoteDatasourceImpl(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepositoryImpl(
    datasource: ref.watch(_friendRemoteDatasourceProvider),
  );
});

// ── UseCase Providers ──────────────────────────────────────────

final searchUsersUseCaseProvider = Provider<SearchUsersUseCase>(
  (ref) => SearchUsersUseCase(ref.watch(friendRepositoryProvider)),
);

final sendFriendRequestUseCaseProvider = Provider<SendFriendRequestUseCase>(
  (ref) => SendFriendRequestUseCase(ref.watch(friendRepositoryProvider)),
);

final acceptFriendRequestUseCaseProvider =
    Provider<AcceptFriendRequestUseCase>(
      (ref) => AcceptFriendRequestUseCase(ref.watch(friendRepositoryProvider)),
    );

final declineFriendRequestUseCaseProvider =
    Provider<DeclineFriendRequestUseCase>(
      (ref) =>
          DeclineFriendRequestUseCase(ref.watch(friendRepositoryProvider)),
    );

final cancelFriendRequestUseCaseProvider =
    Provider<CancelFriendRequestUseCase>(
      (ref) =>
          CancelFriendRequestUseCase(ref.watch(friendRepositoryProvider)),
    );

final removeFriendUseCaseProvider = Provider<RemoveFriendUseCase>(
  (ref) => RemoveFriendUseCase(ref.watch(friendRepositoryProvider)),
);

final blockUserUseCaseProvider = Provider<BlockUserUseCase>(
  (ref) => BlockUserUseCase(ref.watch(friendRepositoryProvider)),
);

final getFriendsUseCaseProvider = Provider<GetFriendsUseCase>(
  (ref) => GetFriendsUseCase(ref.watch(friendRepositoryProvider)),
);

final getIncomingRequestsUseCaseProvider =
    Provider<GetIncomingRequestsUseCase>(
      (ref) => GetIncomingRequestsUseCase(ref.watch(friendRepositoryProvider)),
    );

final getOutgoingRequestsUseCaseProvider =
    Provider<GetOutgoingRequestsUseCase>(
      (ref) =>
          GetOutgoingRequestsUseCase(ref.watch(friendRepositoryProvider)),
    );

// ── Stream Providers ───────────────────────────────────────────

/// Stream danh sách bạn bè (accepted) của current user.
final friendsStreamProvider =
    StreamProvider<List<FriendshipEntity>>((ref) async* {
  final userId = ref.watch(authNotifierProvider).user?.uid;
  if (userId == null) {
    yield [];
    return;
  }
  final useCase = ref.watch(getFriendsUseCaseProvider);
  final stream = useCase(GetFriendsParams(userId: userId));

  await for (final result in stream) {
    yield result.fold(ifLeft: (_) => [], ifRight: (list) => list);
  }
});

/// Stream lời mời kết bạn nhận được.
final incomingRequestsStreamProvider =
    StreamProvider<List<FriendshipEntity>>((ref) async* {
  final userId = ref.watch(authNotifierProvider).user?.uid;
  if (userId == null) {
    yield [];
    return;
  }
  final useCase = ref.watch(getIncomingRequestsUseCaseProvider);
  final stream = useCase(GetIncomingRequestsParams(userId: userId));

  await for (final result in stream) {
    yield result.fold(ifLeft: (_) => [], ifRight: (list) => list);
  }
});

/// Stream lời mời kết bạn đã gửi.
final outgoingRequestsStreamProvider =
    StreamProvider<List<FriendshipEntity>>((ref) async* {
  final userId = ref.watch(authNotifierProvider).user?.uid;
  if (userId == null) {
    yield [];
    return;
  }
  final useCase = ref.watch(getOutgoingRequestsUseCaseProvider);
  final stream = useCase(GetOutgoingRequestsParams(userId: userId));

  await for (final result in stream) {
    yield result.fold(ifLeft: (_) => [], ifRight: (list) => list);
  }
});

/// Provider danh sách bạn bè đang online
final onlineFriendsProvider = Provider<List<FriendshipEntity>>((ref) {
  final friendsAsync = ref.watch(friendsStreamProvider);
  if (friendsAsync.value == null) return [];
  
  final friends = friendsAsync.value!;
  final currentUserId = ref.watch(authNotifierProvider).user?.uid ?? '';
  
  return friends.where((f) {
    final otherUserId = f.otherUserId(currentUserId);
    final userAsync = ref.watch(userProfileProvider(otherUserId));
    final user = userAsync.value;
    if (user == null) return false;
    return user.status != UserStatus.offline && user.status != UserStatus.invisible;
  }).toList();
});

// ── State Classes ──────────────────────────────────────────────

class FriendActionState {
  final bool isLoading;
  final String? error;
  final bool success;

  const FriendActionState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  FriendActionState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
  }) {
    return FriendActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      success: success ?? this.success,
    );
  }
}

class SearchState {
  final List<UserEntity> results;
  final bool isLoading;
  final String? error;
  final String query;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
  });

  SearchState copyWith({
    List<UserEntity>? results,
    bool? isLoading,
    String? error,
    String? query,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      query: query ?? this.query,
    );
  }
}

// ── Notifiers ──────────────────────────────────────────────────

/// Notifier tìm kiếm user.
class SearchUsersNotifier extends StateNotifier<SearchState> {
  final SearchUsersUseCase _useCase;

  SearchUsersNotifier({required SearchUsersUseCase useCase})
    : _useCase = useCase,
      super(const SearchState());

  Future<void> search(String query) async {
    state = state.copyWith(isLoading: true, error: null, query: query);

    if (query.trim().isEmpty) {
      state = const SearchState();
      return;
    }

    final result = await _useCase(SearchUsersParams(query: query));

    state = result.fold(
      ifLeft: (failure) =>
          state.copyWith(isLoading: false, error: failure.message),
      ifRight: (users) => state.copyWith(isLoading: false, results: users),
    );
  }

  void clear() {
    state = const SearchState();
  }
}

/// Notifier xử lý các hành động friend (send, accept, decline, cancel, remove, block).
class FriendActionNotifier extends StateNotifier<FriendActionState> {
  final SendFriendRequestUseCase _sendRequest;
  final AcceptFriendRequestUseCase _acceptRequest;
  final DeclineFriendRequestUseCase _declineRequest;
  final CancelFriendRequestUseCase _cancelRequest;
  final RemoveFriendUseCase _removeFriend;
  final BlockUserUseCase _blockUser;

  FriendActionNotifier({
    required SendFriendRequestUseCase sendRequest,
    required AcceptFriendRequestUseCase acceptRequest,
    required DeclineFriendRequestUseCase declineRequest,
    required CancelFriendRequestUseCase cancelRequest,
    required RemoveFriendUseCase removeFriend,
    required BlockUserUseCase blockUser,
  }) : _sendRequest = sendRequest,
       _acceptRequest = acceptRequest,
       _declineRequest = declineRequest,
       _cancelRequest = cancelRequest,
       _removeFriend = removeFriend,
       _blockUser = blockUser,
       super(const FriendActionState());

  Future<bool> sendFriendRequest(String targetUserId) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    final result = await _sendRequest(
      SendFriendRequestParams(targetUserId: targetUserId),
    );
    return result.fold(
      ifLeft: (f) {
        state = state.copyWith(isLoading: false, error: f.message);
        return false;
      },
      ifRight: (_) {
        state = state.copyWith(isLoading: false, success: true);
        return true;
      },
    );
  }

  Future<bool> acceptFriendRequest(String friendshipId) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    final result = await _acceptRequest(
      AcceptFriendRequestParams(friendshipId: friendshipId),
    );
    return result.fold(
      ifLeft: (f) {
        state = state.copyWith(isLoading: false, error: f.message);
        return false;
      },
      ifRight: (_) {
        state = state.copyWith(isLoading: false, success: true);
        return true;
      },
    );
  }

  Future<bool> declineFriendRequest(String friendshipId) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    final result = await _declineRequest(
      DeclineFriendRequestParams(friendshipId: friendshipId),
    );
    return result.fold(
      ifLeft: (f) {
        state = state.copyWith(isLoading: false, error: f.message);
        return false;
      },
      ifRight: (_) {
        state = state.copyWith(isLoading: false, success: true);
        return true;
      },
    );
  }

  Future<bool> cancelFriendRequest(String friendshipId) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    final result = await _cancelRequest(
      CancelFriendRequestParams(friendshipId: friendshipId),
    );
    return result.fold(
      ifLeft: (f) {
        state = state.copyWith(isLoading: false, error: f.message);
        return false;
      },
      ifRight: (_) {
        state = state.copyWith(isLoading: false, success: true);
        return true;
      },
    );
  }

  Future<bool> removeFriend(String friendshipId) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    final result = await _removeFriend(
      RemoveFriendParams(friendshipId: friendshipId),
    );
    return result.fold(
      ifLeft: (f) {
        state = state.copyWith(isLoading: false, error: f.message);
        return false;
      },
      ifRight: (_) {
        state = state.copyWith(isLoading: false, success: true);
        return true;
      },
    );
  }

  Future<bool> blockUser(String targetUserId) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    final result = await _blockUser(
      BlockUserParams(targetUserId: targetUserId),
    );
    return result.fold(
      ifLeft: (f) {
        state = state.copyWith(isLoading: false, error: f.message);
        return false;
      },
      ifRight: (_) {
        state = state.copyWith(isLoading: false, success: true);
        return true;
      },
    );
  }

  void clearError() {
    state = state.copyWith(error: null, success: false);
  }
}

// ── Provider ──────────────────────────────────────────────────

final searchUsersNotifierProvider =
    StateNotifierProvider.autoDispose<SearchUsersNotifier, SearchState>((ref) {
      return SearchUsersNotifier(
        useCase: ref.watch(searchUsersUseCaseProvider),
      );
    });

final friendActionNotifierProvider =
    StateNotifierProvider<FriendActionNotifier, FriendActionState>((ref) {
      return FriendActionNotifier(
        sendRequest: ref.watch(sendFriendRequestUseCaseProvider),
        acceptRequest: ref.watch(acceptFriendRequestUseCaseProvider),
        declineRequest: ref.watch(declineFriendRequestUseCaseProvider),
        cancelRequest: ref.watch(cancelFriendRequestUseCaseProvider),
        removeFriend: ref.watch(removeFriendUseCaseProvider),
        blockUser: ref.watch(blockUserUseCaseProvider),
      );
    });

/// Provider lắng nghe realtime thông tin user theo uid (dùng cho hiển thị bạn bè).
final userProfileProvider = StreamProvider.family<UserEntity?, String>(
  (ref, userId) {
    if (userId.isEmpty) return Stream.value(null);
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromFirestore(doc.data()!, userId).toEntity();
    });
  },
);
