import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/channel_entity.dart';
import '../models/channel_model.dart';

abstract class ChannelRemoteDatasource {
  Future<ChannelModel> createChannel({
    required String serverId,
    required String name,
    required ChannelType type,
    String? categoryId,
    int? position,
    String? topic,
    List<String>? allowedViewRoleIds,
    List<String>? allowedSendRoleIds,
  });

  Future<ChannelModel> updateChannel({
    required String serverId,
    required String channelId,
    String? name,
    ChannelType? type,
    String? topic,
    int? position,
    List<String>? allowedViewRoleIds,
    List<String>? allowedSendRoleIds,
  });

  Future<void> deleteChannel({
    required String serverId,
    required String channelId,
  });

  Stream<List<ChannelModel>> getServerChannelsStream({
    required String serverId,
  });

  Future<ChannelModel> getChannel({
    required String serverId,
    required String channelId,
  });
}

class ChannelRemoteDatasourceImpl implements ChannelRemoteDatasource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ChannelRemoteDatasourceImpl({required this.firestore, required this.auth});

  @override
  Future<ChannelModel> createChannel({
    required String serverId,
    required String name,
    required ChannelType type,
    String? categoryId,
    int? position,
    String? topic,
    List<String>? allowedViewRoleIds,
    List<String>? allowedSendRoleIds,
  }) async {
    try {
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        throw const AuthException(message: 'Người dùng chưa xác thực');
      }

      await _ensureCanManageChannels(
        serverId: serverId,
        userId: currentUser.uid,
      );

      final serverDoc = await firestore
          .collection('servers')
          .doc(serverId)
          .get();
      if (!serverDoc.exists) {
        throw const ServerException(message: 'Không tìm thấy server');
      }

      final existingChannels = await firestore
          .collection('servers')
          .doc(serverId)
          .collection('channels')
          .get();
      final newPosition = position ?? existingChannels.docs.length;

      final newChannelRef = firestore
          .collection('servers')
          .doc(serverId)
          .collection('channels')
          .doc();

      final channelModel = ChannelModel(
        channelId: newChannelRef.id,
        serverId: serverId,
        name: name,
        type: type,
        categoryId: categoryId ?? '',
        position: newPosition,
        topic: topic ?? '',
        allowedViewRoleIds: allowedViewRoleIds ?? const [],
        allowedSendRoleIds: allowedSendRoleIds ?? const [],
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await newChannelRef.set(channelModel.toFirestore());
      Logger.info(
        'Channel created: ${newChannelRef.id} in server: $serverId',
        tag: 'ChannelDatasource',
      );
      return channelModel;
    } catch (e) {
      if (e is ServerException || e is AuthException) rethrow;
      throw ServerException(message: 'Tạo kênh thất bại: $e');
    }
  }

  @override
  Future<ChannelModel> updateChannel({
    required String serverId,
    required String channelId,
    String? name,
    ChannelType? type,
    String? topic,
    int? position,
    List<String>? allowedViewRoleIds,
    List<String>? allowedSendRoleIds,
  }) async {
    try {
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        throw const AuthException(message: 'Người dùng chưa xác thực');
      }
      await _ensureCanManageChannels(
        serverId: serverId,
        userId: currentUser.uid,
      );

      final channelRef = firestore
          .collection('servers')
          .doc(serverId)
          .collection('channels')
          .doc(channelId);

      final channelDoc = await channelRef.get();
      if (!channelDoc.exists) {
        throw const ServerException(message: 'Không tìm thấy kênh');
      }

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (name != null) updateData['name'] = name;
      if (type != null) {
        updateData['type'] = type == ChannelType.text ? 'text' : 'voice';
      }
      if (topic != null) updateData['topic'] = topic;
      if (position != null) updateData['position'] = position;
      if (allowedViewRoleIds != null) {
        updateData['allowedViewRoleIds'] = allowedViewRoleIds;
      }
      if (allowedSendRoleIds != null) {
        updateData['allowedSendRoleIds'] = allowedSendRoleIds;
      }

      await channelRef.update(updateData);
      final updatedDoc = await channelRef.get();
      Logger.info(
        'Channel updated: $channelId in server: $serverId',
        tag: 'ChannelDatasource',
      );
      return ChannelModel.fromFirestore(updatedDoc.data() ?? {}, updatedDoc.id);
    } catch (e) {
      if (e is ServerException || e is AuthException) rethrow;
      throw ServerException(message: 'Cập nhật kênh thất bại: $e');
    }
  }

  @override
  Future<void> deleteChannel({
    required String serverId,
    required String channelId,
  }) async {
    try {
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        throw const AuthException(message: 'Người dùng chưa xác thực');
      }
      await _ensureCanManageChannels(
        serverId: serverId,
        userId: currentUser.uid,
      );

      final channelRef = firestore
          .collection('servers')
          .doc(serverId)
          .collection('channels')
          .doc(channelId);

      final channelDoc = await channelRef.get();
      if (!channelDoc.exists) {
        throw const ServerException(message: 'Không tìm thấy kênh');
      }

      final isDefault = channelDoc.data()?['isDefault'] as bool? ?? false;
      if (isDefault) {
        throw const ServerException(message: 'Không thể xóa kênh mặc định');
      }

      final messagesSnapshot = await channelRef.collection('messages').get();
      final batch = firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(channelRef);
      await batch.commit();

      Logger.info(
        'Channel deleted: $channelId in server: $serverId',
        tag: 'ChannelDatasource',
      );
    } catch (e) {
      if (e is ServerException || e is AuthException) rethrow;
      throw ServerException(message: 'Xóa kênh thất bại: $e');
    }
  }

  @override
  Stream<List<ChannelModel>> getServerChannelsStream({
    required String serverId,
  }) {
    return firestore
        .collection('servers')
        .doc(serverId)
        .collection('channels')
        .orderBy('position', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChannelModel.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Future<ChannelModel> getChannel({
    required String serverId,
    required String channelId,
  }) async {
    try {
      final channelDoc = await firestore
          .collection('servers')
          .doc(serverId)
          .collection('channels')
          .doc(channelId)
          .get();

      if (!channelDoc.exists) {
        throw const ServerException(message: 'Không tìm thấy kênh');
      }

      return ChannelModel.fromFirestore(channelDoc.data() ?? {}, channelDoc.id);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Lấy thông tin kênh thất bại: $e');
    }
  }

  Future<void> _ensureCanManageChannels({
    required String serverId,
    required String userId,
  }) async {
    final serverDoc = await firestore.collection('servers').doc(serverId).get();
    if (!serverDoc.exists) {
      throw const ServerException(message: 'Không tìm thấy server');
    }
    if (serverDoc.data()?['ownerId'] == userId) return;

    final roles = await _getMemberRoles(serverId: serverId, userId: userId);
    final canManage = roles.any((role) {
      final permissions = List<String>.from(role['permissions'] as List? ?? []);
      return permissions.contains('MANAGE_CHANNEL') ||
          permissions.contains('MANAGE_SERVER');
    });
    if (!canManage) {
      throw const ServerException(message: 'Bạn không có quyền quản lý kênh');
    }
  }

  Future<List<Map<String, dynamic>>> _getMemberRoles({
    required String serverId,
    required String userId,
  }) async {
    final memberDoc = await firestore
        .collection('servers')
        .doc(serverId)
        .collection('members')
        .doc(userId)
        .get();
    if (!memberDoc.exists) {
      throw const ServerException(message: 'Không tìm thấy thành viên server');
    }

    final roleIds = <String>{
      ...List<String>.from(memberDoc.data()?['roleIds'] as List? ?? const []),
    };
    final defaultRole = await firestore
        .collection('servers')
        .doc(serverId)
        .collection('roles')
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();
    if (defaultRole.docs.isNotEmpty) {
      roleIds.add(defaultRole.docs.first.id);
    }

    final roles = <Map<String, dynamic>>[];
    for (final roleId in roleIds) {
      final roleDoc = await firestore
          .collection('servers')
          .doc(serverId)
          .collection('roles')
          .doc(roleId)
          .get();
      final data = roleDoc.data();
      if (data != null) roles.add(data);
    }
    return roles;
  }
}
