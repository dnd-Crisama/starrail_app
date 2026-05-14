// lib/features/friend/domain/entities/dm_message_entity.dart
import 'package:equatable/equatable.dart';

/// Loại tin nhắn DM.
enum DmMessageType { text, image, file }

/// Entity đại diện cho một tin nhắn trong cuộc hội thoại DM.
class DmMessageEntity extends Equatable {
  final String messageId;
  final String chatId;
  final String senderId;
  final String content;
  final DmMessageType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final bool isEdited;
  final String? replyToMessageId;

  const DmMessageEntity({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.type = DmMessageType.text,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.isEdited = false,
    this.replyToMessageId,
  });

  DmMessageEntity copyWith({
    String? messageId,
    String? chatId,
    String? senderId,
    String? content,
    DmMessageType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? isEdited,
    String? replyToMessageId,
  }) {
    return DmMessageEntity(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      isEdited: isEdited ?? this.isEdited,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
    );
  }

  @override
  List<Object?> get props => [
    messageId,
    chatId,
    senderId,
    content,
    type,
    createdAt,
    updatedAt,
    isDeleted,
    isEdited,
    replyToMessageId,
  ];
}
