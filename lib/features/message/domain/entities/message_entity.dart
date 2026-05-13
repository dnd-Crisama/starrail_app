import 'package:equatable/equatable.dart';

/// Loại tin nhắn
enum MessageType { text, image, file, system, sticker }

/// Thực thể Reaction: emoji + danh sách userId đã react
class ReactionEntity extends Equatable {
  final String emoji;
  final List<String> userIds;

  const ReactionEntity({required this.emoji, required this.userIds});

  int get count => userIds.length;

  bool hasReacted(String userId) => userIds.contains(userId);

  ReactionEntity copyWith({String? emoji, List<String>? userIds}) {
    return ReactionEntity(
      emoji: emoji ?? this.emoji,
      userIds: userIds ?? this.userIds,
    );
  }

  @override
  List<Object?> get props => [emoji, userIds];
}

/// Thực thể Attachment: file đính kèm trong tin nhắn
class AttachmentEntity extends Equatable {
  final String url;
  final String fileName;
  final String mimeType;
  final int size;
  final String kind; // IMAGE, FILE, VIDEO, AUDIO
  final String? thumbnailUrl;
  final String? storagePath;

  const AttachmentEntity({
    required this.url,
    required this.fileName,
    required this.mimeType,
    required this.size,
    required this.kind,
    this.thumbnailUrl,
    this.storagePath,
  });

  bool get isImage => kind == 'IMAGE';
  bool get isVideo => kind == 'VIDEO';
  bool get isAudio => kind == 'AUDIO';

  AttachmentEntity copyWith({
    String? url,
    String? fileName,
    String? mimeType,
    int? size,
    String? kind,
    String? thumbnailUrl,
    String? storagePath,
  }) {
    return AttachmentEntity(
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      kind: kind ?? this.kind,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      storagePath: storagePath ?? this.storagePath,
    );
  }

  @override
  List<Object?> get props => [
    url,
    fileName,
    mimeType,
    size,
    kind,
    thumbnailUrl,
    storagePath,
  ];
}

class MessageEntity extends Equatable {
  final String messageId;
  final String serverId;
  final String channelId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<String> mentionTargetIds;
  final String? replyToMessageId;
  final String? threadId;
  final bool isEdited;
  final bool isDeleted;
  final List<ReactionEntity> reactions;
  final List<AttachmentEntity> attachments;

  const MessageEntity({
    required this.messageId,
    required this.serverId,
    required this.channelId,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
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

  MessageEntity copyWith({
    String? messageId,
    String? serverId,
    String? channelId,
    String? senderId,
    String? content,
    MessageType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    List<String>? mentionTargetIds,
    String? replyToMessageId,
    String? threadId,
    bool? isEdited,
    bool? isDeleted,
    List<ReactionEntity>? reactions,
    List<AttachmentEntity>? attachments,
  }) {
    return MessageEntity(
      messageId: messageId ?? this.messageId,
      serverId: serverId ?? this.serverId,
      channelId: channelId ?? this.channelId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      mentionTargetIds: mentionTargetIds ?? this.mentionTargetIds,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      threadId: threadId ?? this.threadId,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      reactions: reactions ?? this.reactions,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  List<Object?> get props => [
    messageId,
    serverId,
    channelId,
    senderId,
    content,
    type,
    createdAt,
    updatedAt,
    deletedAt,
    mentionTargetIds,
    replyToMessageId,
    threadId,
    isEdited,
    isDeleted,
    reactions,
    attachments,
  ];
}
