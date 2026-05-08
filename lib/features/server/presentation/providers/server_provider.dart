// lib/features/server/presentation/providers/server_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/server_entity.dart';
import '../../domain/repositories/server_repository.dart';
import '../../domain/usecases/create_server_usecase.dart';
import '../../domain/usecases/delete_server_usecase.dart';
import '../../domain/usecases/get_user_servers_usecase.dart';
import '../../domain/usecases/join_server_usecase.dart';
import '../../domain/usecases/leave_server_usecase.dart';
import '../../data/datasources/server_remote_datasource.dart';
import '../../data/repositories/server_repository_impl.dart';

// ── Dependency Injection ───────────────────────────────────────

final _serverRemoteDatasourceProvider = Provider<ServerRemoteDatasource>((ref) {
  return ServerRemoteDatasourceImpl(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

final _serverRepositoryProvider = Provider<ServerRepository>((ref) {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  return ServerRepositoryImpl(
    serverRemoteDatasource: ref.watch(_serverRemoteDatasourceProvider),
    currentUserId: currentUserId,
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

// ── Stream Provider cho danh sách servers real-time ───────────

final userServersStreamProvider = StreamProvider<List<ServerEntity>>((
  ref,
) async* {
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
