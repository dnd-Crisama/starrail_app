// lib/features/server/presentation/providers/server_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/data/datasources/cloudinary_storage_datasource.dart';
import '../../domain/entities/server_entity.dart';
import '../../domain/repositories/server_repository.dart';
import '../../domain/usecases/create_server_usecase.dart';
import '../../domain/usecases/delete_server_usecase.dart';
import '../../domain/usecases/get_user_servers_usecase.dart';
import '../../domain/usecases/join_server_usecase.dart';
import '../../domain/usecases/leave_server_usecase.dart';
import '../../domain/usecases/get_server_members_usecase.dart';
import '../../data/datasources/server_remote_datasource.dart';
import '../../data/repositories/server_repository_impl.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ── Dependency Injection ───────────────────────────────────────

final _serverRemoteDatasourceProvider = Provider<ServerRemoteDatasource>((ref) {
  return ServerRemoteDatasourceImpl(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

final _serverRepositoryProvider = Provider<ServerRepository>((ref) {
  final currentUserId = ref.watch(
    authNotifierProvider.select((state) => state.user?.uid),
  );
  return ServerRepositoryImpl(
    serverRemoteDatasource: ref.watch(_serverRemoteDatasourceProvider),
    currentUserId: currentUserId ?? '',
  );
});

final createServerUseCaseProvider = Provider<CreateServerUseCase>((ref) {
  return CreateServerUseCase(ref.watch(_serverRepositoryProvider));
});

final joinServerUseCaseProvider = Provider<JoinServerUseCase>((ref) {
  return JoinServerUseCase(ref.watch(_serverRepositoryProvider));
});

final leaveServerUseCaseProvider = Provider<LeaveServerUseCase>((ref) {
  return LeaveServerUseCase(ref.watch(_serverRepositoryProvider));
});

final deleteServerUseCaseProvider = Provider<DeleteServerUseCase>((ref) {
  return DeleteServerUseCase(ref.watch(_serverRepositoryProvider));
});

final getUserServersUseCaseProvider = Provider<GetUserServersUseCase>((ref) {
  return GetUserServersUseCase(ref.watch(_serverRepositoryProvider));
});

final getServerMembersUseCaseProvider = Provider<GetServerMembersUseCase>((
  ref,
) {
  return GetServerMembersUseCase(ref.watch(_serverRepositoryProvider));
});

// ── Stream Provider cho danh sách servers real-time ───────────

final userServersStreamProvider = StreamProvider<List<ServerEntity>>((
  ref,
) async* {
  final currentUserId = ref.watch(
    authNotifierProvider.select((state) => state.user?.uid),
  );
  if (currentUserId == null || currentUserId.isEmpty) {
    yield const <ServerEntity>[];
    return;
  }

  final useCase = ref.watch(getUserServersUseCaseProvider);
  final result = await useCase(const NoParams());

  yield* result.fold(
    ifLeft: (failure) {
      throw failure.message;
    },
    ifRight: (stream) => stream,
  );
});

// ── State Classes ──────────────────────────────────────────────

class CreateServerState {
  final bool isLoading;
  final ServerEntity? createdServer;
  final String? errorMessage;

  const CreateServerState({
    this.isLoading = false,
    this.createdServer,
    this.errorMessage,
  });

  CreateServerState copyWith({
    bool? isLoading,
    ServerEntity? createdServer,
    String? errorMessage,
  }) {
    return CreateServerState(
      isLoading: isLoading ?? this.isLoading,
      createdServer: createdServer ?? this.createdServer,
      errorMessage: errorMessage,
    );
  }
}

class JoinServerState {
  final bool isLoading;
  final ServerEntity? joinedServer;
  final String? errorMessage;

  const JoinServerState({
    this.isLoading = false,
    this.joinedServer,
    this.errorMessage,
  });

  JoinServerState copyWith({
    bool? isLoading,
    ServerEntity? joinedServer,
    String? errorMessage,
  }) {
    return JoinServerState(
      isLoading: isLoading ?? this.isLoading,
      joinedServer: joinedServer ?? this.joinedServer,
      errorMessage: errorMessage,
    );
  }
}

// ── Notifiers ──────────────────────────────────────────────────

class CreateServerNotifier extends StateNotifier<CreateServerState> {
  final CreateServerUseCase _useCase;

  CreateServerNotifier({required CreateServerUseCase useCase})
    : _useCase = useCase,
      super(const CreateServerState());

  Future<void> createServer({required String name, String? iconUrl}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _useCase(
      CreateServerParams(name: name, iconUrl: iconUrl),
    );

    state = result.fold(
      ifLeft: (failure) =>
          state.copyWith(isLoading: false, errorMessage: failure.message),
      ifRight: (server) =>
          state.copyWith(isLoading: false, createdServer: server),
    );
  }
}

class JoinServerNotifier extends StateNotifier<JoinServerState> {
  final JoinServerUseCase _useCase;

  JoinServerNotifier({required JoinServerUseCase useCase})
    : _useCase = useCase,
      super(const JoinServerState());

  Future<void> joinServer({required String inviteCode}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _useCase(JoinServerParams(inviteCode: inviteCode));

    state = result.fold(
      ifLeft: (failure) =>
          state.copyWith(isLoading: false, errorMessage: failure.message),
      ifRight: (server) =>
          state.copyWith(isLoading: false, joinedServer: server),
    );
  }
}

// ── Providers ──────────────────────────────────────────────────

final createServerNotifierProvider =
    StateNotifierProvider<CreateServerNotifier, CreateServerState>((ref) {
      return CreateServerNotifier(
        useCase: ref.watch(createServerUseCaseProvider),
      );
    });

final joinServerNotifierProvider =
    StateNotifierProvider<JoinServerNotifier, JoinServerState>((ref) {
      return JoinServerNotifier(useCase: ref.watch(joinServerUseCaseProvider));
    });

// ── Server Settings State & Notifier ────────────────────────────

class ServerSettingsState {
  final bool isLoading;
  final String? errorMessage;
  final bool actionCompleted;

  const ServerSettingsState({
    this.isLoading = false,
    this.errorMessage,
    this.actionCompleted = false,
  });

  ServerSettingsState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? actionCompleted,
  }) {
    return ServerSettingsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      actionCompleted: actionCompleted ?? this.actionCompleted,
    );
  }
}

class ServerSettingsNotifier extends StateNotifier<ServerSettingsState> {
  final LeaveServerUseCase _leaveServerUseCase;
  final DeleteServerUseCase _deleteServerUseCase;

  ServerSettingsNotifier({
    required LeaveServerUseCase leaveServerUseCase,
    required DeleteServerUseCase deleteServerUseCase,
  }) : _leaveServerUseCase = leaveServerUseCase,
       _deleteServerUseCase = deleteServerUseCase,
       super(const ServerSettingsState());

  Future<bool> leaveServer({required String serverId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _leaveServerUseCase(
      LeaveServerParams(serverId: serverId),
    );
    return result.fold(
      ifLeft: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      ifRight: (_) {
        state = state.copyWith(isLoading: false, actionCompleted: true);
        return true;
      },
    );
  }

  Future<bool> deleteServer({required String serverId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _deleteServerUseCase(
      DeleteServerParams(serverId: serverId),
    );
    return result.fold(
      ifLeft: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      ifRight: (_) {
        state = state.copyWith(isLoading: false, actionCompleted: true);
        return true;
      },
    );
  }

  Future<bool> updateServerIcon({
    required String serverId,
    required XFile imageFile,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final imageUrl = await CloudinaryStorageDatasource().uploadImage(
        imageFile,
      );
      await FirebaseFirestore.instance
          .collection('servers')
          .doc(serverId)
          .update({
            'iconUrl': imageUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể cập nhật ảnh server: $e',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final serverSettingsNotifierProvider =
    StateNotifierProvider<ServerSettingsNotifier, ServerSettingsState>((ref) {
      return ServerSettingsNotifier(
        leaveServerUseCase: ref.watch(leaveServerUseCaseProvider),
        deleteServerUseCase: ref.watch(deleteServerUseCaseProvider),
      );
    });

// ── Provider kiểm tra user có phải owner của server không ───────

final isServerOwnerProvider = Provider.family<bool, String>((ref, serverId) {
  final serversAsync = ref.watch(userServersStreamProvider);
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  return serversAsync.maybeWhen(
    data: (servers) {
      final server = servers.where((s) => s.serverId == serverId).firstOrNull;
      return server?.ownerId == currentUserId;
    },
    orElse: () => false,
  );
});

// ── Provider lấy thông tin user (owner) theo userId ──────────────

final ownerUserProfileProvider = FutureProvider.family<UserModel?, String>((
  ref,
  userId,
) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc.data()!, doc.id);
  } catch (e) {
    return null;
  }
});
