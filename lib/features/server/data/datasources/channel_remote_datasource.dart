// lib/features/server/data/datasources/channel_remote_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/channel_model.dart';
import '../../domain/entities/channel_entity.dart';

abstract class ChannelRemoteDatasource {
  Future<ChannelModel> createChannel({
    required String serverId,
    required String name,
    required ChannelType type,
    String? categoryId,
    int? position,
    String? topic,
  });

  Future<ChannelModel> updateChannel({
    required String serverId,
    required String channelId,
    String? name,
    ChannelType? type,
    String? topic,
    int? position,
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
  }) async {
    try {
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        throw const AuthException(message: 'Người dùng chưa xác thực');
      }

      // Kiểm tra server tồn tại
      final serverDoc = await firestore
          .collection('servers')
          .doc(serverId)
          .get();
      if (!serverDoc.exists) {
        throw const ServerException(message: 'Không tìm thấy server');
      }

      // Lấy số lượng kênh hiện tại để tính position nếu không có
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
  }) async {
    try {
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

      await channelRef.update(updateData);

      final updatedDoc = await channelRef.get();
      Logger.info(
        'Channel updated: $channelId in server: $serverId',
        tag: 'ChannelDatasource',
      );

      return ChannelModel.fromFirestore(updatedDoc.data() ?? {}, updatedDoc.id);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Cập nhật kênh thất bại: $e');
    }
  }

  @override
  Future<void> deleteChannel({
    required String serverId,
    required String channelId,
  }) async {
    try {
      final channelRef = firestore
          .collection('servers')
          .doc(serverId)
          .collection('channels')
          .doc(channelId);

      final channelDoc = await channelRef.get();
      if (!channelDoc.exists) {
        throw const ServerException(message: 'Không tìm thấy kênh');
      }

      // Không cho xóa kênh mặc định
      final isDefault = channelDoc.data()?['isDefault'] as bool? ?? false;
      if (isDefault) {
        throw const ServerException(message: 'Không thể xóa kênh mặc định');
      }

      // Xóa tất cả messages trong kênh (nếu có)
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
      if (e is ServerException) rethrow;
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
}
