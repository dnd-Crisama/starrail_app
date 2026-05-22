// lib/features/server/data/datasources/server_remote_datasource.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/permission.dart';
import '../models/server_model.dart';
import '../models/server_member_model.dart';

abstract class ServerRemoteDatasource {
  Future<ServerModel> createServer({required String name, String? iconUrl});

  Future<ServerModel> joinServer({required String inviteCode});

  Future<void> leaveServer({required String serverId, required String userId});

  Future<void> kickMember({
    required String serverId,
    required String actorUserId,
    required String targetUserId,
  });

  Future<void> deleteServer({required String serverId, required String userId});

  Stream<List<ServerModel>> getUserServersStream({required String userId});

  Future<ServerModel> getServer({required String serverId});

  /// Kiểm tra user có phải member của server.
  Future<bool> isServerMember({
    required String serverId,
    required String userId,
  });

  /// Sinh invite code duy nhất.
  Future<String> generateUniqueInviteCode();

  /// Lắng nghe danh sách thành viên của một server
  Stream<List<ServerMemberModel>> watchServerMembers({
    required String serverId,
  });
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
        throw const AuthException(message: 'Người dùng chưa xác thực');
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

      // Tạo kênh văn bản mặc định "general"
      final defaultChannelRef = newServerRef.collection('channels').doc();
      batch.set(defaultChannelRef, {
        'serverId': newServerRef.id,
        'name': 'general',
        'type': 'text',
        'categoryId': '',
        'position': 0,
        'topic': 'Kênh trò chuyện chung',
        'isDefault': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Tạo kênh thoại mặc định "Chung"
      final defaultVoiceRef = newServerRef.collection('channels').doc();
      batch.set(defaultVoiceRef, {
        'serverId': newServerRef.id,
        'name': 'Chung',
        'type': 'voice',
        'categoryId': '',
        'position': 1,
        'topic': '',
        'isDefault': true,
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
      throw ServerException(message: 'Tạo server thất bại: $e');
    }
  }

  @override
  Future<ServerModel> joinServer({required String inviteCode}) async {
    try {
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        throw const AuthException(message: 'Người dùng chưa xác thực');
      }

      // Tìm server theo inviteCode
      final serverQuery = await firestore
          .collection('servers')
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();

      if (serverQuery.docs.isEmpty) {
        throw const ServerException(message: 'Mã lời mời không hợp lệ');
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
        throw const ServerException(
          message: 'Bạn đã là thành viên của server này',
        );
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
      throw ServerException(message: 'Tham gia server thất bại: $e');
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
        throw const ServerException(message: 'Không tìm thấy server');
      }

      final ownerId = serverDoc.data()?['ownerId'] as String?;
      if (ownerId == userId) {
        throw const ServerException(
          message:
              'Chủ sở hữu không thể rời đi. Hãy chuyển quyền sở hữu trước.',
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
      throw ServerException(message: 'Rời server thất bại: $e');
    }
  }

  @override
  Future<void> kickMember({
    required String serverId,
    required String actorUserId,
    required String targetUserId,
  }) async {
    try {
      if (actorUserId.isEmpty) {
        throw const AuthException(message: 'Người dùng chưa xác thực');
      }

      if (actorUserId == targetUserId) {
        throw const ServerException(message: 'Bạn không thể tự đá chính mình');
      }

      final serverDoc = await firestore
          .collection('servers')
          .doc(serverId)
          .get();
      if (!serverDoc.exists) {
        throw const ServerException(message: 'Không tìm thấy server');
      }

      final ownerId = serverDoc.data()?['ownerId'] as String?;
      if (targetUserId == ownerId) {
        throw const ServerException(message: 'Không thể đá chủ sở hữu server');
      }

      final actorCanKick =
          actorUserId == ownerId ||
          await _memberHasPermission(
            serverId: serverId,
            userId: actorUserId,
            permission: Permission.kickMembers.value,
          );
      if (!actorCanKick) {
        throw const ServerException(
          message: 'Bạn không có quyền đá thành viên',
        );
      }

      final targetMemberRef = firestore
          .collection('servers')
          .doc(serverId)
          .collection('members')
          .doc(targetUserId);
      final targetMemberDoc = await targetMemberRef.get();
      if (!targetMemberDoc.exists) {
        throw const ServerException(
          message: 'Thành viên không tồn tại trong server',
        );
      }

      await targetMemberRef.delete();

      Logger.info(
        'User $targetUserId kicked from server: $serverId',
        tag: 'ServerDatasource',
      );
    } catch (e) {
      if (e is ServerException || e is AuthException) rethrow;
      throw ServerException(message: 'Đá thành viên thất bại: $e');
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
        throw const ServerException(message: 'Không tìm thấy server');
      }

      final ownerId = serverDoc.data()?['ownerId'] as String?;
      if (ownerId != userId) {
        throw const ServerException(
          message: 'Chỉ chủ sở hữu mới có thể xóa server',
        );
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
      throw ServerException(message: 'Xóa server thất bại: $e');
    }
  }

  @override
  Stream<List<ServerModel>> getUserServersStream({required String userId}) {
    return _watchUserServers(userId: userId);
  }

  Stream<List<ServerModel>> _watchUserServers({required String userId}) {
    late StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
    membersSubscription;
    final serverSubscriptions =
        <String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>{};
    final serverIds = <String>[];
    final serverModels = <String, ServerModel>{};

    final controller = StreamController<List<ServerModel>>(
      onCancel: () async {
        await membersSubscription.cancel();
        for (final subscription in serverSubscriptions.values) {
          await subscription.cancel();
        }
        serverSubscriptions.clear();
      },
    );

    void emitServers() {
      if (controller.isClosed) return;
      controller.add([
        for (final serverId in serverIds)
          if (serverModels.containsKey(serverId)) serverModels[serverId]!,
      ]);
    }

    membersSubscription = firestore
        .collectionGroup('members')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen(
          (membersSnapshot) {
            final nextServerIds = membersSnapshot.docs
                .map((doc) => doc.reference.parent.parent?.id)
                .whereType<String>()
                .toSet()
                .toList();

            final removedServerIds = serverIds
                .where((serverId) => !nextServerIds.contains(serverId))
                .toList();
            for (final removedServerId in removedServerIds) {
              serverSubscriptions.remove(removedServerId)?.cancel();
              serverModels.remove(removedServerId);
            }

            serverIds
              ..clear()
              ..addAll(nextServerIds);

            for (final serverId in nextServerIds) {
              if (serverSubscriptions.containsKey(serverId)) continue;

              serverSubscriptions[serverId] = firestore
                  .collection('servers')
                  .doc(serverId)
                  .snapshots()
                  .listen(
                    (serverDoc) {
                      if (serverDoc.exists) {
                        serverModels[serverId] = ServerModel.fromFirestore(
                          serverDoc.data() ?? {},
                          serverDoc.id,
                        );
                      } else {
                        serverModels.remove(serverId);
                      }
                      emitServers();
                    },
                    onError: (Object error, StackTrace stackTrace) {
                      Logger.error(
                        'Error loading server $serverId: $error',
                        tag: 'ServerDatasource',
                      );
                      if (!controller.isClosed) {
                        controller.addError(error, stackTrace);
                      }
                    },
                  );
            }

            if (nextServerIds.isEmpty) {
              emitServers();
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!controller.isClosed) {
              controller.addError(error, stackTrace);
            }
          },
        );

    return controller.stream;
  }

  @override
  Future<ServerModel> getServer({required String serverId}) async {
    try {
      final serverDoc = await firestore
          .collection('servers')
          .doc(serverId)
          .get();
      if (!serverDoc.exists) {
        throw const ServerException(message: 'Không tìm thấy server');
      }

      return ServerModel.fromFirestore(serverDoc.data() ?? {}, serverDoc.id);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Lấy thông tin server thất bại: $e');
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
      throw ServerException(
        message: 'Kiểm tra tư cách thành viên thất bại: $e',
      );
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

  Future<bool> _memberHasPermission({
    required String serverId,
    required String userId,
    required String permission,
  }) async {
    final memberDoc = await firestore
        .collection('servers')
        .doc(serverId)
        .collection('members')
        .doc(userId)
        .get();
    if (!memberDoc.exists) return false;

    final memberRoleIds = <String>{
      ...List<String>.from(memberDoc.data()?['roleIds'] as List? ?? const []),
    };

    final defaultRoleQuery = await firestore
        .collection('servers')
        .doc(serverId)
        .collection('roles')
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();
    if (defaultRoleQuery.docs.isNotEmpty) {
      memberRoleIds.add(defaultRoleQuery.docs.first.id);
    }

    for (final roleId in memberRoleIds) {
      final roleDoc = await firestore
          .collection('servers')
          .doc(serverId)
          .collection('roles')
          .doc(roleId)
          .get();
      final permissions = List<String>.from(
        roleDoc.data()?['permissions'] as List? ?? const [],
      );
      if (permissions.contains(permission) ||
          permissions.contains(Permission.manageServer.value)) {
        return true;
      }
    }

    return false;
  }

  @override
  Stream<List<ServerMemberModel>> watchServerMembers({
    required String serverId,
  }) {
    return firestore
        .collection('servers')
        .doc(serverId)
        .collection('members')
        // Order by joinedAt to keep it consistent
        .orderBy('joinedAt')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => ServerMemberModel.fromFirestore(
                  doc.data(),
                  doc.id,
                  serverId,
                ),
              )
              .toList();
        });
  }
}
