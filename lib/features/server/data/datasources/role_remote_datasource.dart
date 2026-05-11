import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/role_model.dart';
import '../models/server_member_model.dart';

abstract class RoleRemoteDatasource {
  Future<RoleModel> createRole({
    required String serverId,
    required String name,
    int color = 0xFF99AAB5,
    List<String> permissions = const [],
    int hierarchyLevel = 1,
  });

  Future<RoleModel> updateRole({
    required String serverId,
    required String roleId,
    String? name,
    int? color,
    List<String>? permissions,
    int? hierarchyLevel,
  });

  Future<void> deleteRole({required String serverId, required String roleId});

  Stream<List<RoleModel>> getServerRolesStream({required String serverId});

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

  Future<RoleModel> getDefaultRole({required String serverId});

  Future<String?> getServerOwnerId({required String serverId});

  Future<ServerMemberModel?> getServerMember({
    required String serverId,
    required String userId,
  });

  Future<RoleModel?> getRole({
    required String serverId,
    required String roleId,
  });
}

class RoleRemoteDatasourceImpl implements RoleRemoteDatasource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  RoleRemoteDatasourceImpl({required this.firestore, required this.auth});

  @override
  Future<RoleModel> createRole({
    required String serverId,
    required String name,
    int color = 0xFF99AAB5,
    List<String> permissions = const [],
    int hierarchyLevel = 1,
  }) async {
    try {
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        throw const AuthException(message: 'Người dùng chưa xác thực');
      }

      final roleRef = firestore
          .collection('servers')
          .doc(serverId)
          .collection('roles')
          .doc();

      final roleModel = RoleModel(
        roleId: roleRef.id,
        serverId: serverId,
        name: name,
        color: color,
        permissions: permissions,
        hierarchyLevel: hierarchyLevel,
        isDefault: false,
        isManagedBySystem: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await roleRef.set(roleModel.toFirestore());

      Logger.info(
        'Role created: ${roleRef.id} in server: $serverId',
        tag: 'RoleDatasource',
      );

      return roleModel;
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Tạo vai trò thất bại: $e');
    }
  }

  @override
  Future<RoleModel> updateRole({
    required String serverId,
    required String roleId,
    String? name,
    int? color,
    List<String>? permissions,
    int? hierarchyLevel,
  }) async {
    try {
      final roleRef = firestore
          .collection('servers')
          .doc(serverId)
          .collection('roles')
          .doc(roleId);

      final roleDoc = await roleRef.get();
      if (!roleDoc.exists) {
        throw const ServerException(message: 'Không tìm thấy vai trò');
      }

      final existing = RoleModel.fromFirestore(roleDoc.data()!, roleDoc.id);

      if (existing.isDefault && name != null && name != existing.name) {
        throw const ServerException(
          message: 'Không thể đổi tên vai trò mặc định @everyone',
        );
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (name != null) updateData['name'] = name;
      if (color != null) updateData['color'] = color;
      if (permissions != null) updateData['permissions'] = permissions;
      if (hierarchyLevel != null) updateData['hierarchyLevel'] = hierarchyLevel;

      await roleRef.update(updateData);

      final updatedDoc = await roleRef.get();
      Logger.info('Role updated: $roleId', tag: 'RoleDatasource');

      return RoleModel.fromFirestore(updatedDoc.data()!, updatedDoc.id);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Cập nhật vai trò thất bại: $e');
    }
  }

  @override
  Future<void> deleteRole({
    required String serverId,
    required String roleId,
  }) async {
    try {
      final roleRef = firestore
          .collection('servers')
          .doc(serverId)
          .collection('roles')
          .doc(roleId);

      final roleDoc = await roleRef.get();
      if (!roleDoc.exists) {
        throw const ServerException(message: 'Không tìm thấy vai trò');
      }

      final roleData = roleDoc.data()!;
      if (roleData['isDefault'] == true) {
        throw const ServerException(
          message: 'Không thể xóa vai trò mặc định @everyone',
        );
      }

      // Remove roleId from all members who have it
      final membersWithRole = await firestore
          .collection('servers')
          .doc(serverId)
          .collection('members')
          .where('roleIds', arrayContains: roleId)
          .get();

      final batch = firestore.batch();
      for (final memberDoc in membersWithRole.docs) {
        final currentRoleIds = List<String>.from(
          memberDoc.data()['roleIds'] as List? ?? [],
        );
        currentRoleIds.remove(roleId);
        batch.update(memberDoc.reference, {'roleIds': currentRoleIds});
      }

      batch.delete(roleRef);
      await batch.commit();

      Logger.info(
        'Role deleted: $roleId from server: $serverId',
        tag: 'RoleDatasource',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Xóa vai trò thất bại: $e');
    }
  }

  @override
  Stream<List<RoleModel>> getServerRolesStream({required String serverId}) {
    return firestore
        .collection('servers')
        .doc(serverId)
        .collection('roles')
        .orderBy('hierarchyLevel', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RoleModel.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Future<void> assignRoleToMember({
    required String serverId,
    required String userId,
    required String roleId,
  }) async {
    try {
      final memberRef = firestore
          .collection('servers')
          .doc(serverId)
          .collection('members')
          .doc(userId);

      final memberDoc = await memberRef.get();
      if (!memberDoc.exists) {
        throw const ServerException(
          message: 'Không tìm thấy thành viên trong server',
        );
      }

      await memberRef.update({
        'roleIds': FieldValue.arrayUnion([roleId]),
      });

      Logger.info(
        'Role $roleId assigned to user $userId in server $serverId',
        tag: 'RoleDatasource',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Gán vai trò thất bại: $e');
    }
  }

  @override
  Future<void> removeRoleFromMember({
    required String serverId,
    required String userId,
    required String roleId,
  }) async {
    try {
      final memberRef = firestore
          .collection('servers')
          .doc(serverId)
          .collection('members')
          .doc(userId);

      final memberDoc = await memberRef.get();
      if (!memberDoc.exists) {
        throw const ServerException(
          message: 'Không tìm thấy thành viên trong server',
        );
      }

      await memberRef.update({
        'roleIds': FieldValue.arrayRemove([roleId]),
      });

      Logger.info(
        'Role $roleId removed from user $userId in server $serverId',
        tag: 'RoleDatasource',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Gỡ vai trò thất bại: $e');
    }
  }

  @override
  Future<RoleModel> getDefaultRole({required String serverId}) async {
    try {
      final query = await firestore
          .collection('servers')
          .doc(serverId)
          .collection('roles')
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw const ServerException(message: 'Không tìm thấy vai trò mặc định');
      }

      final doc = query.docs.first;
      return RoleModel.fromFirestore(doc.data(), doc.id);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: 'Lấy vai trò mặc định thất bại: $e');
    }
  }

  @override
  Future<String?> getServerOwnerId({required String serverId}) async {
    try {
      final serverDoc = await firestore
          .collection('servers')
          .doc(serverId)
          .get();
      return serverDoc.data()?['ownerId'] as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<ServerMemberModel?> getServerMember({
    required String serverId,
    required String userId,
  }) async {
    try {
      final memberDoc = await firestore
          .collection('servers')
          .doc(serverId)
          .collection('members')
          .doc(userId)
          .get();

      if (!memberDoc.exists) return null;
      return ServerMemberModel.fromFirestore(
        memberDoc.data()!,
        memberDoc.id,
        serverId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<RoleModel?> getRole({
    required String serverId,
    required String roleId,
  }) async {
    try {
      final roleDoc = await firestore
          .collection('servers')
          .doc(serverId)
          .collection('roles')
          .doc(roleId)
          .get();

      if (!roleDoc.exists) return null;
      return RoleModel.fromFirestore(roleDoc.data()!, roleDoc.id);
    } catch (e) {
      return null;
    }
  }
}
