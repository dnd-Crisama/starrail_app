import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message_entity.dart';

/// Repository interface cho Message — Domain layer không biết Firebase
abstract class MessageRepository {
  /// Gửi tin nhắn mới, trả về message đã tạo
  Future<Either<Failure, MessageEntity>> sendMessage({
    required String serverId,
    required String channelId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
    List<String> mentionTargetIds = const [],
    String? replyToMessageId,
    List<AttachmentEntity> attachments = const [],
  });

  /// Lấy stream tin nhắn real-time cho một channel
  /// [limit] số tin nhắn tối đa mỗi lần load
  Stream<List<MessageEntity>> getMessagesStream({
    required String serverId,
    required String channelId,
    int limit = 50,
  });

  /// Lấy thêm tin nhắn cũ hơn (pagination)
  /// [lastMessageCreatedAt] thời gian tin nhắn cũ nhất đã load
  Future<Either<Failure, List<MessageEntity>>> getMessagesBefore({
    required String serverId,
    required String channelId,
    required DateTime lastMessageCreatedAt,
    int limit = 50,
  });

  /// Xóa mềm tin nhắn (soft delete)
  Future<Either<Failure, void>> deleteMessage({
    required String serverId,
    required String channelId,
    required String messageId,
  });

  /// Sửa nội dung tin nhắn
  Future<Either<Failure, MessageEntity>> editMessage({
    required String serverId,
    required String channelId,
    required String messageId,
    required String newContent,
  });

  /// Toggle reaction: thêm nếu chưa có, xóa nếu đã react
  Future<Either<Failure, void>> toggleReaction({
    required String serverId,
    required String channelId,
    required String messageId,
    required String emoji,
    required String userId,
  });

  /// Lấy một tin nhắn theo ID (dùng cho reply preview)
  Future<Either<Failure, MessageEntity?>> getMessageById({
    required String serverId,
    required String channelId,
    required String messageId,
  });

  /// Đánh dấu channel đã đọc — cập nhật lastReadMessageId
  Future<Either<Failure, void>> markChannelAsRead({
    required String serverId,
    required String channelId,
    required String userId,
    required String lastReadMessageId,
  });

  /// Lấy lastReadMessageId cho user trong channel
  Future<Either<Failure, String?>> getLastReadMessageId({
    required String serverId,
    required String channelId,
    required String userId,
  });
}
