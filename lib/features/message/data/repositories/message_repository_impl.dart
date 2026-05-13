import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/message_remote_datasource.dart';
import '../models/message_model.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDatasource remoteDatasource;

  MessageRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failure, MessageEntity>> sendMessage({
    required String serverId,
    required String channelId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    List<String> mentionTargetIds = const [],
    String? replyToMessageId,
    List<AttachmentEntity> attachments = const [],
  }) async {
    try {
      final message = await remoteDatasource.sendMessage(
        serverId: serverId,
        channelId: channelId,
        senderId: senderId,
        content: content,
        type: _typeToString(type),
        mentionTargetIds: mentionTargetIds,
        replyToMessageId: replyToMessageId,
        attachments: attachments
            .map((a) => AttachmentModel.fromEntity(a).toMap())
            .toList(),
      );
      return Either.right<Failure, MessageEntity>(message);
    } on ServerException catch (e) {
      return Either.left<Failure, MessageEntity>(
        ServerFailure(message: e.message),
      );
    } catch (e) {
      return Either.left<Failure, MessageEntity>(
        ServerFailure(message: 'Gửi tin nhắn thất bại: $e'),
      );
    }
  }

  @override
  Stream<List<MessageEntity>> getMessagesStream({
    required String serverId,
    required String channelId,
    int limit = 50,
  }) {
    return remoteDatasource.getMessagesStream(
      serverId: serverId,
      channelId: channelId,
      limit: limit,
    );
  }

  @override
  Future<Either<Failure, List<MessageEntity>>> getMessagesBefore({
    required String serverId,
    required String channelId,
    required DateTime lastMessageCreatedAt,
    int limit = 50,
  }) async {
    try {
      final messages = await remoteDatasource.getMessagesBefore(
        serverId: serverId,
        channelId: channelId,
        lastMessageCreatedAt: lastMessageCreatedAt,
        limit: limit,
      );
      return Either.right<Failure, List<MessageEntity>>(messages);
    } on ServerException catch (e) {
      return Either.left<Failure, List<MessageEntity>>(
        ServerFailure(message: e.message),
      );
    } catch (e) {
      return Either.left<Failure, List<MessageEntity>>(
        ServerFailure(message: 'Tải tin nhắn cũ thất bại: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage({
    required String serverId,
    required String channelId,
    required String messageId,
  }) async {
    try {
      await remoteDatasource.deleteMessage(
        serverId: serverId,
        channelId: channelId,
        messageId: messageId,
      );
      return Either.right<Failure, void>(null);
    } on ServerException catch (e) {
      return Either.left<Failure, void>(ServerFailure(message: e.message));
    } catch (e) {
      return Either.left<Failure, void>(
        ServerFailure(message: 'Xóa tin nhắn thất bại: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, MessageEntity>> editMessage({
    required String serverId,
    required String channelId,
    required String messageId,
    required String newContent,
  }) async {
    try {
      final message = await remoteDatasource.editMessage(
        serverId: serverId,
        channelId: channelId,
        messageId: messageId,
        newContent: newContent,
      );
      return Either.right<Failure, MessageEntity>(message);
    } on ServerException catch (e) {
      return Either.left<Failure, MessageEntity>(
        ServerFailure(message: e.message),
      );
    } catch (e) {
      return Either.left<Failure, MessageEntity>(
        ServerFailure(message: 'Sửa tin nhắn thất bại: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> toggleReaction({
    required String serverId,
    required String channelId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    try {
      await remoteDatasource.toggleReaction(
        serverId: serverId,
        channelId: channelId,
        messageId: messageId,
        emoji: emoji,
        userId: userId,
      );
      return Either.right<Failure, void>(null);
    } on ServerException catch (e) {
      return Either.left<Failure, void>(ServerFailure(message: e.message));
    } catch (e) {
      return Either.left<Failure, void>(
        ServerFailure(message: 'Thao tác reaction thất bại: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, MessageEntity?>> getMessageById({
    required String serverId,
    required String channelId,
    required String messageId,
  }) async {
    try {
      final message = await remoteDatasource.getMessageById(
        serverId: serverId,
        channelId: channelId,
        messageId: messageId,
      );
      return Either.right<Failure, MessageEntity?>(message);
    } on ServerException catch (e) {
      return Either.left<Failure, MessageEntity?>(
        ServerFailure(message: e.message),
      );
    } catch (e) {
      return Either.left<Failure, MessageEntity?>(
        ServerFailure(message: 'Tải tin nhắn thất bại: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> markChannelAsRead({
    required String serverId,
    required String channelId,
    required String userId,
    required String lastReadMessageId,
  }) async {
    try {
      await remoteDatasource.markChannelAsRead(
        serverId: serverId,
        channelId: channelId,
        userId: userId,
        lastReadMessageId: lastReadMessageId,
      );
      return Either.right<Failure, void>(null);
    } on ServerException catch (e) {
      return Either.left<Failure, void>(ServerFailure(message: e.message));
    } catch (e) {
      return Either.left<Failure, void>(
        ServerFailure(message: 'Đánh dấu đã đọc thất bại: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, String?>> getLastReadMessageId({
    required String serverId,
    required String channelId,
    required String userId,
  }) async {
    try {
      final lastReadId = await remoteDatasource.getLastReadMessageId(
        serverId: serverId,
        channelId: channelId,
        userId: userId,
      );
      return Either.right<Failure, String?>(lastReadId);
    } on ServerException catch (e) {
      return Either.left<Failure, String?>(ServerFailure(message: e.message));
    } catch (e) {
      return Either.left<Failure, String?>(
        ServerFailure(message: 'Lấy trạng thái đọc thất bại: $e'),
      );
    }
  }

  String _typeToString(MessageType type) {
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
}
