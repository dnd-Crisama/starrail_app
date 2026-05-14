import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/permission.dart';
import '../../domain/entities/role_entity.dart';
import '../../domain/repositories/role_repository.dart';
import '../../domain/entities/server_member_entity.dart';
import '../../domain/usecases/assign_role_to_member_usecase.dart';
import '../../domain/usecases/check_permission_usecase.dart';
import '../../domain/usecases/create_role_usecase.dart';
import '../../domain/usecases/delete_role_usecase.dart';
import '../../domain/usecases/get_server_roles_usecase.dart';
import '../../domain/usecases/remove_role_from_member_usecase.dart';
import '../../domain/usecases/update_role_usecase.dart';
import '../../data/datasources/role_remote_datasource.dart';
import '../../data/models/server_member_model.dart';
import '../../data/repositories/role_repository_impl.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user_entity.dart';

// ── Dependency Injection ───────────────────────────────────────

final _roleRemoteDatasourceProvider = Provider<RoleRemoteDatasource>((ref) {
  return RoleRemoteDatasourceImpl(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

final _roleRepositoryProvider = Provider<RoleRepository>((ref) {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  return RoleRepositoryImpl(
    roleRemoteDatasource: ref.watch(_roleRemoteDatasourceProvider),
    currentUserId: currentUserId,
  );
});

final _createRoleUseCaseProvider = Provider<CreateRoleUseCase>((ref) {
  return CreateRoleUseCase(ref.watch(_roleRepositoryProvider));
});

final _updateRoleUseCaseProvider = Provider<UpdateRoleUseCase>((ref) {
  return UpdateRoleUseCase(ref.watch(_roleRepositoryProvider));
});

final _deleteRoleUseCaseProvider = Provider<DeleteRoleUseCase>((ref) {
  return DeleteRoleUseCase(ref.watch(_roleRepositoryProvider));
});

final _getServerRolesUseCaseProvider = Provider<GetServerRolesUseCase>((ref) {
  return GetServerRolesUseCase(ref.watch(_roleRepositoryProvider));
});

final _assignRoleUseCaseProvider = Provider<AssignRoleToMemberUseCase>((ref) {
  return AssignRoleToMemberUseCase(ref.watch(_roleRepositoryProvider));
});

final _removeRoleUseCaseProvider = Provider<RemoveRoleFromMemberUseCase>((ref) {
  return RemoveRoleFromMemberUseCase(ref.watch(_roleRepositoryProvider));
});

final _checkPermissionUseCaseProvider = Provider<CheckPermissionUseCase>((ref) {
  return CheckPermissionUseCase(ref.watch(_roleRepositoryProvider));
});

// ── Stream Provider for server roles ───────────────────────────

final serverRolesStreamProvider =
    StreamProvider.family<List<RoleEntity>, String>((ref, serverId) async* {
      final useCase = ref.watch(_getServerRolesUseCaseProvider);
      final result = await useCase(GetServerRolesParams(serverId: serverId));

      yield* result.fold(
        ifLeft: (failure) {
          throw failure.message;
        },
        ifRight: (stream) => stream,
      );
    });

class ServerMemberRoleView {
  final ServerMemberEntity member;
  final UserEntity? user;

  const ServerMemberRoleView({required this.member, this.user});
}

final serverMembersWithUsersStreamProvider =
    StreamProvider.family<List<ServerMemberRoleView>, String>((
      ref,
      serverId,
    ) {
      return FirebaseFirestore.instance
          .collection('servers')
          .doc(serverId)
          .collection('members')
          .orderBy('joinedAt')
          .snapshots()
          .asyncMap((snapshot) async {
            final members = <ServerMemberRoleView>[];
            for (final doc in snapshot.docs) {
              final member = ServerMemberModel.fromFirestore(
                doc.data(),
                doc.id,
                serverId,
              ).toEntity();

              UserEntity? user;
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(member.userId)
                  .get();
              if (userDoc.exists) {
                user = UserModel.fromFirestore(
                  userDoc.data()!,
                  userDoc.id,
                ).toEntity();
              }

              members.add(ServerMemberRoleView(member: member, user: user));
            }
            return members;
          });
    });

// ── Permission check provider ──────────────────────────────────

final hasPermissionProvider =
    FutureProvider.family<
      bool,
      ({String serverId, String userId, Permission permission})
    >((ref, params) async {
      final useCase = ref.watch(_checkPermissionUseCaseProvider);
      final result = await useCase(
        CheckPermissionParams(
          serverId: params.serverId,
          userId: params.userId,
          permission: params.permission,
        ),
      );
      return result.fold(
        ifLeft: (_) => false,
        ifRight: (hasPermission) => hasPermission,
      );
    });

// ── State Classes ──────────────────────────────────────────────

class RoleManagementState {
  final bool isLoading;
  final String? errorMessage;
  final RoleEntity? selectedRole;

  const RoleManagementState({
    this.isLoading = false,
    this.errorMessage,
    this.selectedRole,
  });

  RoleManagementState copyWith({
    bool? isLoading,
    String? errorMessage,
    RoleEntity? selectedRole,
  }) {
    return RoleManagementState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedRole: selectedRole ?? this.selectedRole,
    );
  }
}

// ── Notifiers ──────────────────────────────────────────────────

class RoleManagementNotifier extends StateNotifier<RoleManagementState> {
  final CreateRoleUseCase _createRoleUseCase;
  final UpdateRoleUseCase _updateRoleUseCase;
  final DeleteRoleUseCase _deleteRoleUseCase;
  final AssignRoleToMemberUseCase _assignRoleUseCase;
  final RemoveRoleFromMemberUseCase _removeRoleUseCase;

  RoleManagementNotifier({
    required CreateRoleUseCase createRoleUseCase,
    required UpdateRoleUseCase updateRoleUseCase,
    required DeleteRoleUseCase deleteRoleUseCase,
    required AssignRoleToMemberUseCase assignRoleUseCase,
    required RemoveRoleFromMemberUseCase removeRoleUseCase,
  }) : _createRoleUseCase = createRoleUseCase,
       _updateRoleUseCase = updateRoleUseCase,
       _deleteRoleUseCase = deleteRoleUseCase,
       _assignRoleUseCase = assignRoleUseCase,
       _removeRoleUseCase = removeRoleUseCase,
       super(const RoleManagementState());

  Future<void> createRole({
    required String serverId,
    required String name,
    required int color,
    required List<String> permissions,
    required int hierarchyLevel,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _createRoleUseCase(
      CreateRoleParams(
        serverId: serverId,
        name: name,
        color: color,
        permissions: permissions,
        hierarchyLevel: hierarchyLevel,
      ),
    );

    state = result.fold(
      ifLeft: (failure) =>
          state.copyWith(isLoading: false, errorMessage: failure.message),
      ifRight: (_) => state.copyWith(isLoading: false),
    );
  }

  Future<void> updateRole({
    required String serverId,
    required String roleId,
    String? name,
    int? color,
    List<String>? permissions,
    int? hierarchyLevel,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _updateRoleUseCase(
      UpdateRoleParams(
        serverId: serverId,
        roleId: roleId,
        name: name,
        color: color,
        permissions: permissions,
        hierarchyLevel: hierarchyLevel,
      ),
    );

    state = result.fold(
      ifLeft: (failure) =>
          state.copyWith(isLoading: false, errorMessage: failure.message),
      ifRight: (_) => state.copyWith(isLoading: false),
    );
  }

  Future<void> deleteRole({
    required String serverId,
    required String roleId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _deleteRoleUseCase(
      DeleteRoleParams(serverId: serverId, roleId: roleId),
    );

    state = result.fold(
      ifLeft: (failure) =>
          state.copyWith(isLoading: false, errorMessage: failure.message),
      ifRight: (_) => state.copyWith(isLoading: false),
    );
  }

  Future<bool> assignRoleToMember({
    required String serverId,
    required String userId,
    required String roleId,
  }) async {
    final result = await _assignRoleUseCase(
      AssignRoleParams(serverId: serverId, userId: userId, roleId: roleId),
    );

    return result.fold(
      ifLeft: (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      ifRight: (_) => true,
    );
  }

  Future<bool> removeRoleFromMember({
    required String serverId,
    required String userId,
    required String roleId,
  }) async {
    final result = await _removeRoleUseCase(
      RemoveRoleParams(serverId: serverId, userId: userId, roleId: roleId),
    );

    return result.fold(
      ifLeft: (failure) {
        state = state.copyWith(errorMessage: failure.message);
        return false;
      },
      ifRight: (_) => true,
    );
  }

  void selectRole(RoleEntity? role) {
    state = state.copyWith(selectedRole: role);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// ── Providers ──────────────────────────────────────────────────

final roleManagementNotifierProvider =
    StateNotifierProvider<RoleManagementNotifier, RoleManagementState>((ref) {
      return RoleManagementNotifier(
        createRoleUseCase: ref.watch(_createRoleUseCaseProvider),
        updateRoleUseCase: ref.watch(_updateRoleUseCaseProvider),
        deleteRoleUseCase: ref.watch(_deleteRoleUseCaseProvider),
        assignRoleUseCase: ref.watch(_assignRoleUseCaseProvider),
        removeRoleUseCase: ref.watch(_removeRoleUseCaseProvider),
      );
    });

// ── Utility: Get highest role color for a member ───────────────

/// Lấy màu của role cao nhất cho một thành viên.
/// Trả về null nếu không có role nào (dùng màu mặc định).
Color? getHighestRoleColor(List<RoleEntity> roles) {
  if (roles.isEmpty) return null;
  final sortedRoles = List<RoleEntity>.from(roles)
    ..sort((a, b) => b.hierarchyLevel.compareTo(a.hierarchyLevel));
  return Color(sortedRoles.first.color);
}

/// Lấy role cao nhất.
RoleEntity? getHighestRole(List<RoleEntity> roles) {
  if (roles.isEmpty) return null;
  final sortedRoles = List<RoleEntity>.from(roles)
    ..sort((a, b) => b.hierarchyLevel.compareTo(a.hierarchyLevel));
  return sortedRoles.first;
}
