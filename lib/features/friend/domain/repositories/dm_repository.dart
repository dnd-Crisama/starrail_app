// lib/features/friend/domain/repositories/dm_repository.dart
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../entities/dm_chat_entity.dart';
import '../entities/dm_message_entity.dart';

/// Interface Repository cho hệ thống DM.
abstract class DmRepository {
  /// Lấy hoặc tạo cuộc hội thoại DM 1-1 giữa currentUser và [otherUserId].
  /// Trả về chatId.
  Future<Either<Failure, String>> getOrCreateDmChat(String otherUserId);

  /// Tạo Group DM với nhiều participants và tên nhóm bắt buộc.
  Future<Either<Failure, DmChatEntity>> createGroupDm({
    required List<String> participantIds,
    required String name,
    String? iconUrl,
  });

  /// Stream danh sách cuộc hội thoại DM của currentUser, sắp xếp theo lastMessageAt.
  Stream<Either<Failure, List<DmChatEntity>>> watchDmChats(String userId);

  /// Stream danh sách tin nhắn trong [chatId], sắp xếp theo createdAt tăng dần.
  Stream<Either<Failure, List<DmMessageEntity>>> watchDmMessages(String chatId);

  /// Gửi tin nhắn DM.
  Future<Either<Failure, DmMessageEntity>> sendDmMessage({
    required String chatId,
    required String content,
    String? replyToMessageId,
  });

  /// Xóa mềm tin nhắn (chuyển isDeleted = true).
  Future<Either<Failure, void>> deleteDmMessage({
    required String chatId,
    required String messageId,
  });

  /// Sửa nội dung tin nhắn.
  Future<Either<Failure, void>> editDmMessage({
    required String chatId,
    required String messageId,
    required String newContent,
  });

  /// Lấy thông tin một chat cụ thể.
  Future<Either<Failure, DmChatEntity>> getDmChat(String chatId);

  /// Xóa cuộc hội thoại DM.
  Future<Either<Failure, void>> deleteDmChat(String chatId);

  /// Cập nhật thông tin Group DM.
  Future<Either<Failure, void>> updateGroupDm({
    required String chatId,
    required String name,
    String? iconUrl,
    List<String>? participantIds,
  });
}
