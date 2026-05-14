// lib/features/friend/data/models/dm_message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/dm_message_entity.dart';

class DmMessageModel {
  final String messageId;
  final String chatId;
  final String senderId;
  final String content;
  final String type; // TEXT, IMAGE, FILE
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final bool isEdited;
  final String? replyToMessageId;

  const DmMessageModel({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.type = 'TEXT',
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.isEdited = false,
    this.replyToMessageId,
  });

  factory DmMessageModel.fromFirestore(
    Map<String, dynamic> map,
    String docId,
    String chatId,
  ) {
    return DmMessageModel(
      messageId: docId,
      chatId: chatId,
      senderId: map['senderId'] as String? ?? '',
      content: map['content'] as String? ?? '',
      type: map['type'] as String? ?? 'TEXT',
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      isDeleted: map['isDeleted'] as bool? ?? false,
      isEdited: map['isEdited'] as bool? ?? false,
      replyToMessageId: map['replyToMessageId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'content': content,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isDeleted': isDeleted,
      'isEdited': isEdited,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  DmMessageEntity toEntity() {
    return DmMessageEntity(
      messageId: messageId,
      chatId: chatId,
      senderId: senderId,
      content: content,
      type: _parseType(type),
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: isDeleted,
      isEdited: isEdited,
      replyToMessageId: replyToMessageId,
    );
  }

  static DmMessageType _parseType(String type) {
    switch (type) {
      case 'IMAGE':
        return DmMessageType.image;
      case 'FILE':
        return DmMessageType.file;
      default:
        return DmMessageType.text;
    }
  }
}
