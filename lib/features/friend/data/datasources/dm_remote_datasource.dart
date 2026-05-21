// lib/features/friend/data/datasources/dm_remote_datasource.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/dm_chat_model.dart';
import '../models/dm_message_model.dart';

abstract class DmRemoteDatasource {
  /// Lấy hoặc tạo cuộc hội thoại DM 1-1. Trả về chatId.
  Future<String> getOrCreateDmChat(String otherUserId);

  /// Tạo Group DM.
  Future<DmChatModel> createGroupDm({
    required List<String> participantIds,
    required String name,
    String? iconUrl,
  });

  /// Stream danh sách cuộc hội thoại DM của user.
  Stream<List<DmChatModel>> watchDmChats(String userId);

  /// Stream danh sách tin nhắn trong chat.
  Stream<List<DmMessageModel>> watchDmMessages(String chatId);

  /// Gửi tin nhắn DM.
  Future<DmMessageModel> sendDmMessage({
    required String chatId,
    required String content,
    String? replyToMessageId,
  });

  /// Xóa mềm tin nhắn.
  Future<void> deleteDmMessage({
    required String chatId,
    required String messageId,
  });

  /// Sửa nội dung tin nhắn.
  Future<void> editDmMessage({
    required String chatId,
    required String messageId,
    required String newContent,
  });

  /// Lấy thông tin một chat.
  Future<DmChatModel> getDmChat(String chatId);

  /// Xóa cuộc hội thoại DM.
  Future<void> deleteDmChat(String chatId);

  /// Cập nhật thông tin Group DM.
  Future<void> updateGroupDm({
    required String chatId,
    required String name,
    String? iconUrl,
    List<String>? participantIds,
  });
}

class DmRemoteDatasourceImpl implements DmRemoteDatasource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  DmRemoteDatasourceImpl({required this.firestore, required this.auth});

  String get _currentUserId {
    final uid = auth.currentUser?.uid;
    if (uid == null) throw const AuthException(message: 'Chưa đăng nhập');
    return uid;
  }

  @override
  Future<String> getOrCreateDmChat(String otherUserId) async {
    try {
      final currentId = _currentUserId;

      // Tìm chat đã tồn tại giữa 2 user
      // Query: participants array-contains currentId, type = DM
      final snapshot = await firestore
          .collection('userChats')
          .where('participants', arrayContains: currentId)
          .where('type', isEqualTo: 'DM')
          .get();

      // Lọc client-side để tìm chat chứa cả otherUserId
      final existing = snapshot.docs.firstWhere(
        (doc) {
          final participants = List<String>.from(
            doc.data()['participants'] as List? ?? [],
          );
          return participants.contains(otherUserId) &&
              participants.length == 2;
        },
        orElse: () => throw StateError('not_found'),
      );

      Logger.info(
        'Found existing DM chat: ${existing.id}',
        tag: 'DmDatasource',
      );
      return existing.id;
    } on StateError {
      // Tạo chat mới
      return _createDmChatInternal(_currentUserId, otherUserId);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Lấy/tạo DM chat thất bại: $e');
    }
  }

  Future<String> _createDmChatInternal(
    String userId1,
    String userId2,
  ) async {
    final ref = firestore.collection('userChats').doc();
    await ref.set({
      'type': 'DM',
      'participants': [userId1, userId2],
      'name': '',
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessagePreview': '',
    });
    Logger.info('Created DM chat: ${ref.id}', tag: 'DmDatasource');
    return ref.id;
  }

  @override
  Future<DmChatModel> createGroupDm({
    required List<String> participantIds,
    required String name,
    String? iconUrl,
  }) async {
    try {
      final currentId = _currentUserId;

      // Đảm bảo currentUser được include trong participants
      final allParticipants = {currentId, ...participantIds}.toList();

      final ref = firestore.collection('userChats').doc();
      final now = DateTime.now();

      await ref.set({
        'type': 'GROUP_DM',
        'participants': allParticipants,
        'name': name,
        if (iconUrl != null) 'iconUrl': iconUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessagePreview': '',
      });

      Logger.info('Created Group DM: ${ref.id}', tag: 'DmDatasource');

      return DmChatModel(
        chatId: ref.id,
        type: 'GROUP_DM',
        participants: allParticipants,
        name: name,
        iconUrl: iconUrl,
        createdAt: now,
        lastMessageAt: now,
      );
    } catch (e) {
      throw ServerException(message: 'Tạo Group DM thất bại: $e');
    }
  }

  @override
  Stream<List<DmChatModel>> watchDmChats(String userId) {
    return firestore
        .collection('userChats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final models = snapshot.docs
          .map((doc) => DmChatModel.fromFirestore(doc.data(), doc.id))
          .toList();
      models.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      return models;
    });
  }

  @override
  Stream<List<DmMessageModel>> watchDmMessages(String chatId) {
    return firestore
        .collection('userChats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    DmMessageModel.fromFirestore(doc.data(), doc.id, chatId),
              )
              .toList(),
        );
  }

  @override
  Future<DmMessageModel> sendDmMessage({
    required String chatId,
    required String content,
    String? replyToMessageId,
  }) async {
    try {
      final senderId = _currentUserId;
      final now = DateTime.now();

      // Batch: tạo message + cập nhật lastMessageAt của chat
      final batch = firestore.batch();

      final msgRef = firestore
          .collection('userChats')
          .doc(chatId)
          .collection('messages')
          .doc();

      batch.set(msgRef, {
        'senderId': senderId,
        'content': content,
        'type': 'TEXT',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isDeleted': false,
        'isEdited': false,
        if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      });

      // Cập nhật preview ở chat document
      batch.update(firestore.collection('userChats').doc(chatId), {
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessagePreview': content.length > 80
            ? '${content.substring(0, 80)}...'
            : content,
      });

      await batch.commit();

      Logger.info('DM message sent: ${msgRef.id}', tag: 'DmDatasource');

      return DmMessageModel(
        messageId: msgRef.id,
        chatId: chatId,
        senderId: senderId,
        content: content,
        createdAt: now,
        updatedAt: now,
        replyToMessageId: replyToMessageId,
      );
    } catch (e) {
      throw ServerException(message: 'Gửi tin nhắn DM thất bại: $e');
    }
  }

  @override
  Future<void> deleteDmMessage({
    required String chatId,
    required String messageId,
  }) async {
    try {
      await firestore
          .collection('userChats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            'isDeleted': true,
            'content': '',
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw ServerException(message: 'Xóa tin nhắn DM thất bại: $e');
    }
  }

  @override
  Future<void> editDmMessage({
    required String chatId,
    required String messageId,
    required String newContent,
  }) async {
    try {
      await firestore
          .collection('userChats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
            'content': newContent,
            'isEdited': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw ServerException(message: 'Sửa tin nhắn DM thất bại: $e');
    }
  }

  @override
  Future<DmChatModel> getDmChat(String chatId) async {
    try {
      final doc = await firestore.collection('userChats').doc(chatId).get();
      if (!doc.exists) {
        throw const ServerException(message: 'Không tìm thấy chat');
      }
      return DmChatModel.fromFirestore(doc.data()!, chatId);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Lấy thông tin chat thất bại: $e');
    }
  }

  @override
  Future<void> deleteDmChat(String chatId) async {
    try {
      final currentId = _currentUserId;
      final doc = await firestore.collection('userChats').doc(chatId).get();
      if (!doc.exists) {
        throw const ServerException(message: 'Cuộc hội thoại không tồn tại');
      }

      final data = doc.data();
      final isGroup = data?['type'] == 'GROUP_DM';
      if (isGroup) {
        final participants = List<String>.from(data?['participants'] as List? ?? []);
        if (participants.isEmpty || participants.first != currentId) {
          throw const ServerException(message: 'Chỉ chủ nhóm mới được xóa group chat');
        }
      }

      await firestore.collection('userChats').doc(chatId).delete();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Xóa cuộc hội thoại thất bại: $e');
    }
  }

  @override
  Future<void> updateGroupDm({
    required String chatId,
    required String name,
    String? iconUrl,
    List<String>? participantIds,
  }) async {
    try {
      await firestore.collection('userChats').doc(chatId).update({
        'name': name,
        if (iconUrl != null) 'iconUrl': iconUrl,
        if (participantIds != null) 'participants': participantIds,
      });
    } catch (e) {
      throw ServerException(message: 'Cập nhật nhóm thất bại: $e');
    }
  }
}
