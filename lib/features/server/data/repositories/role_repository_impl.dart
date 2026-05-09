import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/permission.dart';
import '../../domain/entities/role_entity.dart';
import '../../domain/repositories/role_repository.dart';
import '../datasources/role_remote_datasource.dart';
import '../models/role_model.dart';

class RoleRepositoryImpl implements RoleRepository {
  final RoleRemoteDatasource roleRemoteDatasource;
  final String currentUserId;

  RoleRepositoryImpl({
    required this.roleRemoteDatasource,
    required this.currentUserId,
  });

  @override
  Future<RoleEntity> createRole({
    required String serverId,
    required String name,
    int color = 0xFF99AAB5,
    List<String> permissions = const [],
    int hierarchyLevel = 1,
  }) async {
    try {
      final model = await roleRemoteDatasource.createRole(
        serverId: serverId,
        name: name,
        color: color,
        permissions: permissions,
        hierarchyLevel: hierarchyLevel,
      );
      return model.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<RoleEntity> updateRole({
    required String serverId,
    required String roleId,
    String? name,
    int? color,
    List<String>? permissions,
    int? hierarchyLevel,
  }) async {
    try {
      final model = await roleRemoteDatasource.updateRole(
        serverId: serverId,
        roleId: roleId,
        name: name,
        color: color,
        permissions: permissions,
        hierarchyLevel: hierarchyLevel,
      );
      return model.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> deleteRole({
    required String serverId,
    required String roleId,
  }) async {
    try {
      await roleRemoteDatasource.deleteRole(serverId: serverId, roleId: roleId);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Stream<List<RoleEntity>> getServerRolesStream({required String serverId}) {
    return roleRemoteDatasource
        .getServerRolesStream(serverId: serverId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<void> assignRoleToMember({
    required String serverId,
    required String userId,
    required String roleId,
  }) async {
    try {
      await roleRemoteDatasource.assignRoleToMember(
        serverId: serverId,
        userId: userId,
        roleId: roleId,
      );
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> removeRoleFromMember({
    required String serverId,
    required String userId,
    required String roleId,
  }) async {
    try {
      await roleRemoteDatasource.removeRoleFromMember(
        serverId: serverId,
        userId: userId,
        roleId: roleId,
      );
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<bool> hasPermission({
    required String serverId,
    required String userId,
    required String permission,
  }) async {
    try {
      // Owner always has all permissions
      final ownerId = await roleRemoteDatasource.getServerOwnerId(
        serverId: serverId,
      );
      if (ownerId == userId) return true;

      final roles = await getMemberRoles(serverId: serverId, userId: userId);

      final perm = Permission.fromValue(permission);
      return roles.any((role) => role.hasPermission(perm));
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<RoleEntity>> getMemberRoles({
    required String serverId,
    required String userId,
  }) async {
    try {
      // Get member's roleIds
      final member = await roleRemoteDatasource.getServerMember(
        serverId: serverId,
        userId: userId,
      );

      if (member == null) return [];

      final roleIds = List<String>.from(member.roleIds);

      // Add default @everyone role
      try {
        final defaultRole = await roleRemoteDatasource.getDefaultRole(
          serverId: serverId,
        );
        if (!roleIds.contains(defaultRole.roleId)) {
          roleIds.add(defaultRole.roleId);
        }
      } catch (_) {}

      if (roleIds.isEmpty) return [];

      // Fetch each role
      final List<RoleEntity> roles = [];
      for (final roleId in roleIds) {
        final roleModel = await roleRemoteDatasource.getRole(
          serverId: serverId,
          roleId: roleId,
        );
        if (roleModel != null) {
          roles.add(roleModel.toEntity());
        }
      }

      return roles;
    } catch (e) {
      throw ServerFailure(message: 'Failed to get member roles: $e');
    }
  }
}
