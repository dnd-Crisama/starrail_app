import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/message_model.dart';
import '../../domain/entities/message_entity.dart';

/// Datasource thao tác trực tiếp với Firestore cho messages
class MessageRemoteDatasource {
  final FirebaseFirestore firestore;

  MessageRemoteDatasource({required this.firestore});

  /// Đường dẫn đến collection messages của channel
  CollectionReference _messagesRef(String serverId, String channelId) {
    return firestore
        .collection('servers')
        .doc(serverId)
        .collection('channels')
        .doc(channelId)
        .collection('messages');
  }

  /// Gửi tin nhắn mới — tạo document với auto-generated ID
  Future<MessageEntity> sendMessage({
    required String serverId,
    required String channelId,
    required String senderId,
    required String content,
    String type = 'TEXT',
    List<String> mentionTargetIds = const [],
    String? replyToMessageId,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    await _ensureCanSendMessage(
      serverId: serverId,
      channelId: channelId,
      senderId: senderId,
    );

    final docRef = _messagesRef(serverId, channelId).doc();
    final now = Timestamp.now();

    final messageModel = MessageModel(
      messageId: docRef.id,
      serverId: serverId,
      channelId: channelId,
      senderId: senderId,
      content: content,
      type: type,
      createdAt: now,
      updatedAt: now,
      mentionTargetIds: mentionTargetIds,
      replyToMessageId: replyToMessageId,
      attachments: attachments.map((a) => AttachmentModel.fromMap(a)).toList(),
    );

    // Batch write: tạo message + cập nhật lastMessageAt của channel
    final batch = firestore.batch();
    batch.set(docRef, messageModel.toFirestore());

    // Cập nhật lastMessageAt trên channel document
    final channelRef = firestore
        .collection('servers')
        .doc(serverId)
        .collection('channels')
        .doc(channelId);
    batch.update(channelRef, {'lastMessageAt': now});

    await batch.commit();
    return messageModel.toEntity();
  }

  Future<void> _ensureCanSendMessage({
    required String serverId,
    required String channelId,
    required String senderId,
  }) async {
    final channelDoc = await firestore
        .collection('servers')
        .doc(serverId)
        .collection('channels')
        .doc(channelId)
        .get();
    final channelData = channelDoc.data();
    if (channelData == null) {
      throw const ServerException(message: 'Không tìm thấy kênh');
    }

    final canSendInServer = await _hasPermission(
      serverId: serverId,
      userId: senderId,
      permission: 'SEND_MESSAGE',
    );
    if (!canSendInServer) {
      throw const ServerException(message: 'Bạn không có quyền gửi tin nhắn');
    }

    final allowedSendRoleIds = List<String>.from(
      channelData['allowedSendRoleIds'] as List? ?? [],
    );
    if (allowedSendRoleIds.isEmpty) return;

    if (await _isServerOwner(serverId: serverId, userId: senderId)) return;

    final memberRoleIds = await _getMemberRoleIds(
      serverId: serverId,
      userId: senderId,
    );

    final canSend = memberRoleIds.any(allowedSendRoleIds.contains);
    if (!canSend) {
      throw const ServerException(
        message: 'Bạn không có quyền chat trong kênh này',
      );
    }
  }

  /// Stream tin nhắn real-time, sắp xếp theo createdAt tăng dần (cũ → mới)
  Stream<List<MessageEntity>> getMessagesStream({
    required String serverId,
    required String channelId,
    int limit = 50,
  }) {
    return _messagesRef(serverId, channelId)
        .orderBy('createdAt', descending: false)
        .limitToLast(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc).toEntity())
              .toList();
        });
  }

  /// Lấy tin nhắn cũ hơn cho pagination (trước lastMessageCreatedAt)
  Future<List<MessageEntity>> getMessagesBefore({
    required String serverId,
    required String channelId,
    required DateTime lastMessageCreatedAt,
    int limit = 50,
  }) async {
    final snapshot = await _messagesRef(serverId, channelId)
        .orderBy('createdAt', descending: true)
        .startAfter([Timestamp.fromDate(lastMessageCreatedAt)])
        .limit(limit)
        .get();

    // Reverse để giữ thứ tự cũ → mới
    final messages =
        snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc).toEntity())
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return messages;
  }

  /// Xóa mềm tin nhắn (đánh dấu isDeleted = true, không xóa document)
  Future<void> deleteMessage({
    required String serverId,
    required String channelId,
    required String messageId,
  }) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      throw const AuthException(message: 'Người dùng chưa xác thực');
    }
    final messageDoc = await _messagesRef(
      serverId,
      channelId,
    ).doc(messageId).get();
    if (!messageDoc.exists) {
      throw const ServerException(message: 'Không tìm thấy tin nhắn');
    }
    final messageData = messageDoc.data() as Map<String, dynamic>?;
    final senderId = messageData?['senderId'] as String? ?? '';
    final canDeleteOthers = await _hasPermission(
      serverId: serverId,
      userId: currentUserId,
      permission: 'DELETE_MESSAGE',
    );
    if (senderId != currentUserId && !canDeleteOthers) {
      throw const ServerException(message: 'Bạn không có quyền xóa tin nhắn');
    }

    await _messagesRef(serverId, channelId).doc(messageId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'content': '',
    });
  }

  /// Sửa nội dung tin nhắn
  Future<MessageEntity> editMessage({
    required String serverId,
    required String channelId,
    required String messageId,
    required String newContent,
  }) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      throw const AuthException(message: 'Người dùng chưa xác thực');
    }
    final messageDoc = await _messagesRef(
      serverId,
      channelId,
    ).doc(messageId).get();
    if (!messageDoc.exists) {
      throw const ServerException(message: 'Không tìm thấy tin nhắn');
    }
    final messageData = messageDoc.data() as Map<String, dynamic>?;
    final senderId = messageData?['senderId'] as String? ?? '';
    final canEditOthers = await _hasPermission(
      serverId: serverId,
      userId: currentUserId,
      permission: 'EDIT_MESSAGE',
    );
    if (senderId != currentUserId && !canEditOthers) {
      throw const ServerException(message: 'Bạn không có quyền sửa tin nhắn');
    }

    await _messagesRef(serverId, channelId).doc(messageId).update({
      'content': newContent,
      'isEdited': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Đọc lại document đã update
    final doc = await _messagesRef(serverId, channelId).doc(messageId).get();
    return MessageModel.fromFirestore(doc).toEntity();
  }

  /// Toggle reaction: thêm nếu chưa có, xóa nếu đã react
  /// Dùng transaction để tránh race condition khi nhiều user react cùng lúc
  Future<void> toggleReaction({
    required String serverId,
    required String channelId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    final docRef = _messagesRef(serverId, channelId).doc(messageId);

    return firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final reactionsData = List<Map<String, dynamic>>.from(
        (data['reactions'] as List<dynamic>? ?? []).map(
          (r) => Map<String, dynamic>.from(r as Map),
        ),
      );

      // Tìm reaction có emoji tương ứng
      final existingIndex = reactionsData.indexWhere(
        (r) => r['emoji'] == emoji,
      );

      if (existingIndex >= 0) {
        // Emoji đã tồn tại — toggle userId
        final userIds = List<String>.from(
          reactionsData[existingIndex]['userIds'],
        );
        if (userIds.contains(userId)) {
          userIds.remove(userId);
          if (userIds.isEmpty) {
            // Không còn ai react → xóa reaction entry
            reactionsData.removeAt(existingIndex);
          } else {
            reactionsData[existingIndex]['userIds'] = userIds;
          }
        } else {
          userIds.add(userId);
          reactionsData[existingIndex]['userIds'] = userIds;
        }
      } else {
        // Emoji chưa tồn tại — thêm mới
        reactionsData.add({
          'emoji': emoji,
          'userIds': [userId],
        });
      }

      transaction.update(docRef, {'reactions': reactionsData});
    });
  }

  /// Lấy một tin nhắn theo ID (dùng để hiển thị reply preview)
  Future<MessageEntity?> getMessageById({
    required String serverId,
    required String channelId,
    required String messageId,
  }) async {
    final doc = await _messagesRef(serverId, channelId).doc(messageId).get();
    if (!doc.exists) return null;
    return MessageModel.fromFirestore(doc).toEntity();
  }

  /// Đánh dấu channel đã đọc — lưu lastReadMessageId cho user
  Future<void> markChannelAsRead({
    required String serverId,
    required String channelId,
    required String userId,
    required String lastReadMessageId,
  }) async {
    final readStatusRef = firestore
        .collection('servers')
        .doc(serverId)
        .collection('channels')
        .doc(channelId)
        .collection('readStatus')
        .doc(userId);

    await readStatusRef.set({
      'lastReadMessageId': lastReadMessageId,
      'lastReadAt': FieldValue.serverTimestamp(),
      'userId': userId,
    }, SetOptions(merge: true));
  }

  /// Lấy lastReadMessageId cho user trong channel
  Future<String?> getLastReadMessageId({
    required String serverId,
    required String channelId,
    required String userId,
  }) async {
    final doc = await firestore
        .collection('servers')
        .doc(serverId)
        .collection('channels')
        .doc(channelId)
        .collection('readStatus')
        .doc(userId)
        .get();

    if (!doc.exists) return null;
    return doc.data()?['lastReadMessageId'] as String?;
  }

  Future<bool> _isServerOwner({
    required String serverId,
    required String userId,
  }) async {
    final serverDoc = await firestore.collection('servers').doc(serverId).get();
    return serverDoc.data()?['ownerId'] == userId;
  }

  Future<bool> _hasPermission({
    required String serverId,
    required String userId,
    required String permission,
  }) async {
    if (await _isServerOwner(serverId: serverId, userId: userId)) return true;

    final roles = await _getMemberRoles(serverId: serverId, userId: userId);
    return roles.any((role) {
      final permissions = List<String>.from(role['permissions'] as List? ?? []);
      return permissions.contains(permission) ||
          permissions.contains('MANAGE_SERVER');
    });
  }

  Future<List<String>> _getMemberRoleIds({
    required String serverId,
    required String userId,
  }) async {
    final memberDoc = await firestore
        .collection('servers')
        .doc(serverId)
        .collection('members')
        .doc(userId)
        .get();
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
    return roleIds.toList();
  }

  Future<List<Map<String, dynamic>>> _getMemberRoles({
    required String serverId,
    required String userId,
  }) async {
    final roleIds = await _getMemberRoleIds(serverId: serverId, userId: userId);
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
