import '../entities/role_entity.dart';

abstract class RoleRepository {
  Future<RoleEntity> createRole({
    required String serverId,
    required String name,
    int color = 0xFF99AAB5,
    List<String> permissions = const [],
    int hierarchyLevel = 1,
  });

  Future<RoleEntity> updateRole({
    required String serverId,
    required String roleId,
    String? name,
    int? color,
    List<String>? permissions,
    int? hierarchyLevel,
  });

  Future<void> deleteRole({required String serverId, required String roleId});

  Stream<List<RoleEntity>> getServerRolesStream({required String serverId});

  Future<void> assignRoleToMember({
    required String serverId,
    required String userId,
    required String roleId,
  });

  Future<void> removeRoleFromMember({
    required String serverId,
    required String userId,
    required String roleId,
  });

  Future<bool> hasPermission({
    required String serverId,
    required String userId,
    required String permission,
  });

  Future<List<RoleEntity>> getMemberRoles({
    required String serverId,
    required String userId,
  });
}
