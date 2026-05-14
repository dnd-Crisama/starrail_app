// lib/features/friend/domain/repositories/friend_repository.dart
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/friendship_entity.dart';

/// Interface Repository cho hệ thống bạn bè.
/// Domain layer chỉ biết interface này, không biết Firebase hay Firestore.
abstract class FriendRepository {
  /// Tìm user theo username (partial match).
  Future<Either<Failure, List<UserEntity>>> searchUsersByUsername(
    String query,
  );

  /// Gửi lời mời kết bạn đến [targetUserId].
  Future<Either<Failure, FriendshipEntity>> sendFriendRequest(
    String targetUserId,
  );

  /// Chấp nhận lời mời kết bạn theo [friendshipId].
  Future<Either<Failure, FriendshipEntity>> acceptFriendRequest(
    String friendshipId,
  );

  /// Từ chối lời mời kết bạn theo [friendshipId].
  /// Document sẽ bị xóa.
  Future<Either<Failure, void>> declineFriendRequest(String friendshipId);

  /// Hủy lời mời đã gửi theo [friendshipId] (chỉ người gửi mới được hủy).
  Future<Either<Failure, void>> cancelFriendRequest(String friendshipId);

  /// Xóa bạn bè (unfriend). Document bị xóa.
  Future<Either<Failure, void>> removeFriend(String friendshipId);

  /// Chặn user. Document giữ lại với status=BLOCKED.
  Future<Either<Failure, void>> blockUser(String targetUserId);

  /// Stream danh sách bạn bè (status=ACCEPTED) của [userId].
  Stream<Either<Failure, List<FriendshipEntity>>> watchFriends(String userId);

  /// Stream lời mời kết bạn nhận được (status=PENDING, requester != userId).
  Stream<Either<Failure, List<FriendshipEntity>>> watchIncomingRequests(
    String userId,
  );

  /// Stream lời mời kết bạn đã gửi (status=PENDING, requester == userId).
  Stream<Either<Failure, List<FriendshipEntity>>> watchOutgoingRequests(
    String userId,
  );

  /// Lấy thông tin Friendship giữa 2 user cụ thể (nếu có).
  Future<Either<Failure, FriendshipEntity?>> getFriendship(
    String currentUserId,
    String targetUserId,
  );
}
