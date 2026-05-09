// lib/features/server/data/datasources/server_remote_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/server_model.dart';
import '../models/server_member_model.dart';

abstract class ServerRemoteDatasource {
  Future<ServerModel> createServer({required String name, String? iconUrl});

  Future<ServerModel> joinServer({required String inviteCode});

  Future<void> leaveServer({required String serverId, required String userId});

  Future<void> deleteServer({required String serverId, required String userId});

  Stream<List<ServerModel>> getUserServersStream({required String userId});

  Future<ServerModel> getServer({required String serverId});

  Future<bool> isServerMember({
    required String serverId,
    required String userId,
  });

  /// Sinh invite code duy nhất.
  Future<String> generateUniqueInviteCode();
}

class ServerRemoteDatasourceImpl implements ServerRemoteDatasource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ServerRemoteDatasourceImpl({required this.firestore, required this.auth});

  @override
  Future<ServerModel> createServer({
    required String name,
    String? iconUrl,
  }) async {
    try {
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        throw const AuthException(message: 'User not authenticated');
      }

      // Sinh inviteCode duy nhất
      final inviteCode = await generateUniqueInviteCode();

      // Tạo document server
      final newServerRef = firestore.collection('servers').doc();
      final serverModel = ServerModel(
        serverId: newServerRef.id,
        name: name,
        iconUrl: iconUrl ?? '',
        ownerId: currentUser.uid,
        inviteCode: inviteCode,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Batch write: server doc + member doc + default @everyone role
      final batch = firestore.batch();
      batch.set(newServerRef, serverModel.toFirestore());

      // Tạo @everyone role mặc định
      final defaultRoleRef = newServerRef.collection('roles').doc();
      batch.set(defaultRoleRef, {
        'serverId': newServerRef.id,
        'name': '@everyone',
        'color': 0xFF99AAB5,
        'permissions': ['VIEW_CHANNEL', 'SEND_MESSAGE', 'CONNECT'],
        'hierarchyLevel': 0,
        'isDefault': true,
        'isManagedBySystem': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final memberRef = newServerRef.collection('members').doc(currentUser.uid);
      final memberModel = ServerMemberModel(
        userId: currentUser.uid,
        serverId: newServerRef.id,
        joinedAt: DateTime.now(),
        roleIds: [defaultRoleRef.id],
      );
      batch.set(memberRef, memberModel.toFirestore());

      await batch.commit();

      Logger.info(
        'Server created: ${newServerRef.id} with inviteCode: $inviteCode',
        tag: 'ServerDatasource',
      );

      return serverModel;
    } catch (e) {
      throw ServerException(message: 'Failed to create server: $e');
    }
  }

  @override
  Future<ServerModel> joinServer({required String inviteCode}) async {
    try {
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        throw const AuthException(message: 'User not authenticated');
      }

      // Tìm server theo inviteCode
      final serverQuery = await firestore
          .collection('servers')
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();

      if (serverQuery.docs.isEmpty) {
        throw const ServerException(message: 'Invalid invite code');
      }

      final serverDoc = serverQuery.docs.first;
      final serverId = serverDoc.id;
      final serverData = serverDoc.data();

      // Kiểm tra user đã là member chưa
      final memberDoc = await firestore
          .collection('servers')
          .doc(serverId)
          .collection('members')
          .doc(currentUser.uid)
          .get();

      if (memberDoc.exists) {
        throw const ServerException(message: 'Already member of this server');
      }

      // Tìm default @everyone role để gán cho member mới
      final defaultRoleQuery = await firestore
          .collection('servers')
          .doc(serverId)
          .collection('roles')
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      final defaultRoleId = defaultRoleQuery.docs.isNotEmpty
          ? defaultRoleQuery.docs.first.id
          : '';

      // Thêm user vào members với @everyone role
      final memberModel = ServerMemberModel(
        userId: currentUser.uid,
        serverId: serverId,
        joinedAt: DateTime.now(),
        roleIds: defaultRoleId.isNotEmpty ? [defaultRoleId] : [],
      );

      await firestore
          .collection('servers')
          .doc(serverId)
          .collection('members')
          .doc(currentUser.uid)
          .set(memberModel.toFirestore());

      Logger.info('User joined server: $serverId', tag: 'ServerDatasource');

      return ServerModel.fromFirestore(serverData, serverId);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to join server: $e');
    }
  }

  @override
  Future<void> leaveServer({
    required String serverId,
    required String userId,
  }) async {
    try {
      // Kiểm tra user có phải owner không (nếu là owner, không cho leave)
      final serverDoc = await firestore
          .collection('servers')
          .doc(serverId)
          .get();
      if (!serverDoc.exists) {
        throw const ServerException(message: 'Server not found');
      }

      final ownerId = serverDoc.data()?['ownerId'] as String?;
      if (ownerId == userId) {
        throw const ServerException(
          message: 'Owner cannot leave. Transfer ownership first.',
        );
      }

      // Xóa member document
      await firestore
          .collection('servers')
          .doc(serverId)
          .collection('members')
          .doc(userId)
          .delete();

      Logger.info('User left server: $serverId', tag: 'ServerDatasource');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to leave server: $e');
    }
  }

  @override
  Future<void> deleteServer({
    required String serverId,
    required String userId,
  }) async {
    try {
      // Kiểm tra user là owner
      final serverDoc = await firestore
          .collection('servers')
          .doc(serverId)
          .get();
      if (!serverDoc.exists) {
        throw const ServerException(message: 'Server not found');
      }

      final ownerId = serverDoc.data()?['ownerId'] as String?;
      if (ownerId != userId) {
        throw const ServerException(message: 'Only owner can delete server');
      }

      // Xóa toàn bộ members
      final membersQuery = await firestore
          .collection('servers')
          .doc(serverId)
          .collection('members')
          .get();

      final batch = firestore.batch();
      for (final doc in membersQuery.docs) {
        batch.delete(doc.reference);
      }

      // Xóa server document
      batch.delete(firestore.collection('servers').doc(serverId));

      await batch.commit();

      Logger.info('Server deleted: $serverId', tag: 'ServerDatasource');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to delete server: $e');
    }
  }

  @override
  Stream<List<ServerModel>> getUserServersStream({required String userId}) {
    return firestore
        .collectionGroup('members')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((membersSnapshot) async {
          if (membersSnapshot.docs.isEmpty) {
            return [];
          }

          // Lấy serverIds từ members
          final serverIds = membersSnapshot.docs
              .map((doc) => doc.reference.parent.parent?.id)
              .whereType<String>()
              .toList();

          if (serverIds.isEmpty) {
            return [];
          }

          // Lấy server documents
          final List<ServerModel> servers = [];
          for (final serverId in serverIds) {
            try {
              final serverDoc = await firestore
                  .collection('servers')
                  .doc(serverId)
                  .get();
              if (serverDoc.exists) {
                servers.add(
                  ServerModel.fromFirestore(
                    serverDoc.data() ?? {},
                    serverDoc.id,
                  ),
                );
              }
            } catch (e) {
              Logger.error(
                'Error loading server $serverId: $e',
                tag: 'ServerDatasource',
              );
            }
          }

          return servers;
        });
  }

  @override
  Future<ServerModel> getServer({required String serverId}) async {
    try {
      final serverDoc = await firestore
          .collection('servers')
          .doc(serverId)
          .get();
      if (!serverDoc.exists) {
        throw const ServerException(message: 'Server not found');
      }

      return ServerModel.fromFirestore(serverDoc.data() ?? {}, serverDoc.id);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Failed to get server: $e');
    }
  }

  @override
  Future<bool> isServerMember({
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

      return memberDoc.exists;
    } catch (e) {
      throw ServerException(message: 'Failed to check membership: $e');
    }
  }

  @override
  Future<String> generateUniqueInviteCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String code;
    bool isUnique = false;

    do {
      code = '';
      for (int i = 0; i < 6; i++) {
        code +=
            chars[(DateTime.now().millisecondsSinceEpoch + i) % chars.length];
      }

      // Kiểm tra code đã tồn tại chưa
      final existing = await firestore
          .collection('servers')
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();

      isUnique = existing.docs.isEmpty;
    } while (!isUnique);

    return code;
  }
}
