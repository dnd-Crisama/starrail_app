import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/channel_entity.dart';
import '../../domain/repositories/channel_repository.dart';
import '../../domain/usecases/create_channel_usecase.dart';
import '../../domain/usecases/delete_channel_usecase.dart';
import '../../domain/usecases/get_server_channels_usecase.dart';
import '../../domain/usecases/update_channel_usecase.dart';
import '../../data/datasources/channel_remote_datasource.dart';
import '../../data/repositories/channel_repository_impl.dart';
import '../providers/role_provider.dart' show RoleManagementState;

// ── Dependency Injection ───────────────────────────────────────

final _channelRemoteDatasourceProvider = Provider<ChannelRemoteDatasource>((
  ref,
) {
  return ChannelRemoteDatasourceImpl(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

final _channelRepositoryProvider = Provider<ChannelRepository>((ref) {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  return ChannelRepositoryImpl(
    channelRemoteDatasource: ref.watch(_channelRemoteDatasourceProvider),
    currentUserId: currentUserId,
  );
});

final _createChannelUseCaseProvider = Provider<CreateChannelUseCase>((ref) {
  return CreateChannelUseCase(ref.watch(_channelRepositoryProvider));
});

final _updateChannelUseCaseProvider = Provider<UpdateChannelUseCase>((ref) {
  return UpdateChannelUseCase(ref.watch(_channelRepositoryProvider));
});

final _deleteChannelUseCaseProvider = Provider<DeleteChannelUseCase>((ref) {
  return DeleteChannelUseCase(ref.watch(_channelRepositoryProvider));
});

final _getServerChannelsUseCaseProvider = Provider<GetServerChannelsUseCase>((
  ref,
) {
  return GetServerChannelsUseCase(ref.watch(_channelRepositoryProvider));
});

// ── Stream Provider cho danh sách kênh real-time ───────────────

final serverChannelsStreamProvider =
    StreamProvider.family<List<ChannelEntity>, String>((ref, serverId) async* {
      final useCase = ref.watch(_getServerChannelsUseCaseProvider);
      final result = await useCase(GetServerChannelsParams(serverId: serverId));

      yield* result.fold(
        ifLeft: (failure) {
          throw failure.message;
        },
        ifRight: (stream) => stream,
      );
    });

// ── State Classes ──────────────────────────────────────────────

class ChannelManagementState {
  final bool isLoading;
  final String? errorMessage;

  const ChannelManagementState({this.isLoading = false, this.errorMessage});

  ChannelManagementState copyWith({bool? isLoading, String? errorMessage}) {
    return ChannelManagementState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

// ── Notifiers ──────────────────────────────────────────────────

class ChannelManagementNotifier extends StateNotifier<ChannelManagementState> {
  final CreateChannelUseCase _createChannelUseCase;
  final UpdateChannelUseCase _updateChannelUseCase;
  final DeleteChannelUseCase _deleteChannelUseCase;

  ChannelManagementNotifier({
    required CreateChannelUseCase createChannelUseCase,
    required UpdateChannelUseCase updateChannelUseCase,
    required DeleteChannelUseCase deleteChannelUseCase,
  }) : _createChannelUseCase = createChannelUseCase,
       _updateChannelUseCase = updateChannelUseCase,
       _deleteChannelUseCase = deleteChannelUseCase,
       super(const ChannelManagementState());

  Future<void> createChannel({
    required String serverId,
    required String name,
    required ChannelType type,
    String? categoryId,
    int? position,
    String? topic,
    List<String>? allowedViewRoleIds,
    List<String>? allowedSendRoleIds,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _createChannelUseCase(
      CreateChannelParams(
        serverId: serverId,
        name: name,
        type: type,
        categoryId: categoryId,
        position: position,
        topic: topic,
        allowedViewRoleIds: allowedViewRoleIds,
        allowedSendRoleIds: allowedSendRoleIds,
      ),
    );

    state = result.fold(
      ifLeft: (failure) =>
          state.copyWith(isLoading: false, errorMessage: failure.message),
      ifRight: (_) => state.copyWith(isLoading: false),
    );
  }

  Future<void> updateChannel({
    required String serverId,
    required String channelId,
    String? name,
    ChannelType? type,
    String? topic,
    int? position,
    List<String>? allowedViewRoleIds,
    List<String>? allowedSendRoleIds,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _updateChannelUseCase(
      UpdateChannelParams(
        serverId: serverId,
        channelId: channelId,
        name: name,
        type: type,
        topic: topic,
        position: position,
        allowedViewRoleIds: allowedViewRoleIds,
        allowedSendRoleIds: allowedSendRoleIds,
      ),
    );

    state = result.fold(
      ifLeft: (failure) =>
          state.copyWith(isLoading: false, errorMessage: failure.message),
      ifRight: (_) => state.copyWith(isLoading: false),
    );
  }

  Future<void> deleteChannel({
    required String serverId,
    required String channelId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _deleteChannelUseCase(
      DeleteChannelParams(serverId: serverId, channelId: channelId),
    );

    state = result.fold(
      ifLeft: (failure) =>
          state.copyWith(isLoading: false, errorMessage: failure.message),
      ifRight: (_) => state.copyWith(isLoading: false),
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// ── Providers ──────────────────────────────────────────────────

final channelManagementNotifierProvider =
    StateNotifierProvider<ChannelManagementNotifier, ChannelManagementState>((
      ref,
    ) {
      return ChannelManagementNotifier(
        createChannelUseCase: ref.watch(_createChannelUseCaseProvider),
        updateChannelUseCase: ref.watch(_updateChannelUseCaseProvider),
        deleteChannelUseCase: ref.watch(_deleteChannelUseCaseProvider),
      );
    });
