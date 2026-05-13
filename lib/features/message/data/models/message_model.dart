import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/message_entity.dart';

class ReactionModel {
  final String emoji;
  final List<String> userIds;

  const ReactionModel({required this.emoji, required this.userIds});

  factory ReactionModel.fromMap(Map<String, dynamic> map) {
    return ReactionModel(
      emoji: map['emoji'] as String? ?? '',
      userIds: List<String>.from(map['userIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {'emoji': emoji, 'userIds': userIds};
  }

  ReactionEntity toEntity() {
    return ReactionEntity(emoji: emoji, userIds: userIds);
  }

  static ReactionModel fromEntity(ReactionEntity entity) {
    return ReactionModel(emoji: entity.emoji, userIds: entity.userIds);
  }
}

class AttachmentModel {
  final String url;
  final String fileName;
  final String mimeType;
  final int size;
  final String kind;
  final String? thumbnailUrl;
  final String? storagePath;

  const AttachmentModel({
    required this.url,
    required this.fileName,
    required this.mimeType,
    required this.size,
    required this.kind,
    this.thumbnailUrl,
    this.storagePath,
  });

  factory AttachmentModel.fromMap(Map<String, dynamic> map) {
    return AttachmentModel(
      url: map['url'] as String? ?? '',
      fileName: map['fileName'] as String? ?? '',
      mimeType: map['mimeType'] as String? ?? '',
      size: map['size'] as int? ?? 0,
      kind: map['kind'] as String? ?? 'FILE',
      thumbnailUrl: map['thumbnailUrl'] as String?,
      storagePath: map['storagePath'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'fileName': fileName,
      'mimeType': mimeType,
      'size': size,
      'kind': kind,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (storagePath != null) 'storagePath': storagePath,
    };
  }

  AttachmentEntity toEntity() {
    return AttachmentEntity(
      url: url,
      fileName: fileName,
      mimeType: mimeType,
      size: size,
      kind: kind,
      thumbnailUrl: thumbnailUrl,
      storagePath: storagePath,
    );
  }

  static AttachmentModel fromEntity(AttachmentEntity entity) {
    return AttachmentModel(
      url: entity.url,
      fileName: entity.fileName,
      mimeType: entity.mimeType,
      size: entity.size,
      kind: entity.kind,
      thumbnailUrl: entity.thumbnailUrl,
      storagePath: entity.storagePath,
    );
  }
}

class MessageModel {
  final String messageId;
  final String serverId;
  final String channelId;
  final String senderId;
  final String content;
  final String type;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final Timestamp? deletedAt;
  final List<String> mentionTargetIds;
  final String? replyToMessageId;
  final String? threadId;
  final bool isEdited;
  final bool isDeleted;
  final List<ReactionModel> reactions;
  final List<AttachmentModel> attachments;

  const MessageModel({
    required this.messageId,
    required this.serverId,
    required this.channelId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.mentionTargetIds = const [],
    this.replyToMessageId,
    this.threadId,
    this.isEdited = false,
    this.isDeleted = false,
    this.reactions = const [],
    this.attachments = const [],
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse reactions từ Firestore
    final reactionsData = data['reactions'] as List<dynamic>? ?? [];
    final reactions = reactionsData
        .map((r) => ReactionModel.fromMap(r as Map<String, dynamic>))
        .toList();

    // Parse attachments từ Firestore
    final attachmentsData = data['attachments'] as List<dynamic>? ?? [];
    final attachments = attachmentsData
        .map((a) => AttachmentModel.fromMap(a as Map<String, dynamic>))
        .toList();

    return MessageModel(
      messageId: doc.id,
      serverId: data['serverId'] as String? ?? '',
      channelId: data['channelId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      content: data['content'] as String? ?? '',
      type: data['type'] as String? ?? 'TEXT',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
      deletedAt: data['deletedAt'] as Timestamp?,
      mentionTargetIds: List<String>.from(data['mentionTargetIds'] ?? []),
      replyToMessageId: data['replyToMessageId'] as String?,
      threadId: data['threadId'] as String?,
      isEdited: data['isEdited'] as bool? ?? false,
      isDeleted: data['isDeleted'] as bool? ?? false,
      reactions: reactions,
      attachments: attachments,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'serverId': serverId,
      'channelId': channelId,
      'senderId': senderId,
      'content': content,
      'type': type,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (deletedAt != null) 'deletedAt': deletedAt,
      'mentionTargetIds': mentionTargetIds,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (threadId != null) 'threadId': threadId,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'reactions': reactions.map((r) => r.toMap()).toList(),
      'attachments': attachments.map((a) => a.toMap()).toList(),
    };
  }

  MessageEntity toEntity() {
    return MessageEntity(
      messageId: messageId,
      serverId: serverId,
      channelId: channelId,
      senderId: senderId,
      content: content,
      type: _mapType(type),
      createdAt: createdAt.toDate(),
      updatedAt: updatedAt.toDate(),
      deletedAt: deletedAt?.toDate(),
      mentionTargetIds: mentionTargetIds,
      replyToMessageId: replyToMessageId,
      threadId: threadId,
      isEdited: isEdited,
      isDeleted: isDeleted,
      reactions: reactions.map((r) => r.toEntity()).toList(),
      attachments: attachments.map((a) => a.toEntity()).toList(),
    );
  }

  static MessageType _mapType(String type) {
    switch (type.toUpperCase()) {
      case 'IMAGE':
        return MessageType.image;
      case 'FILE':
        return MessageType.file;
      case 'SYSTEM':
        return MessageType.system;
      case 'STICKER':
        return MessageType.sticker;
      default:
        return MessageType.text;
    }
  }

  static String _typeToString(MessageType type) {
    switch (type) {
      case MessageType.image:
        return 'IMAGE';
      case MessageType.file:
        return 'FILE';
      case MessageType.system:
        return 'SYSTEM';
      case MessageType.sticker:
        return 'STICKER';
      default:
        return 'TEXT';
    }
  }

  static MessageModel fromEntity(MessageEntity entity) {
    return MessageModel(
      messageId: entity.messageId,
      serverId: entity.serverId,
      channelId: entity.channelId,
      senderId: entity.senderId,
      content: entity.content,
      type: _typeToString(entity.type),
      createdAt: Timestamp.fromDate(entity.createdAt),
      updatedAt: Timestamp.fromDate(entity.updatedAt),
      deletedAt: entity.deletedAt != null
          ? Timestamp.fromDate(entity.deletedAt!)
          : null,
      mentionTargetIds: entity.mentionTargetIds,
      replyToMessageId: entity.replyToMessageId,
      threadId: entity.threadId,
      isEdited: entity.isEdited,
      isDeleted: entity.isDeleted,
      reactions: entity.reactions
          .map((r) => ReactionModel.fromEntity(r))
          .toList(),
      attachments: entity.attachments
          .map((a) => AttachmentModel.fromEntity(a))
          .toList(),
    );
  }
}
