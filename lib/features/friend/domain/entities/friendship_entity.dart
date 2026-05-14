// lib/features/friend/domain/entities/friendship_entity.dart
import 'package:equatable/equatable.dart';

/// Trạng thái của mối quan hệ bạn bè.
enum FriendshipStatus {
  pending,   // Đã gửi lời mời, chờ xác nhận
  accepted,  // Đã kết bạn thành công
  blocked,   // Bị chặn
}

/// Entity đại diện cho mối quan hệ bạn bè giữa 2 người dùng.
/// user1Id luôn nhỏ hơn user2Id (lexicographic) để đảm bảo unique pair.
class FriendshipEntity extends Equatable {
  final String friendshipId;
  final String user1Id;
  final String user2Id;
  final FriendshipStatus status;

  /// Người gửi lời mời ban đầu.
  final String requesterId;

  /// Người thực hiện hành động cuối cùng (accept, block, v.v.).
  final String actionUserId;

  final DateTime createdAt;
  final DateTime updatedAt;

  const FriendshipEntity({
    required this.friendshipId,
    required this.user1Id,
    required this.user2Id,
    required this.status,
    required this.requesterId,
    required this.actionUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Xác định có phải người gửi request hay không dựa trên userId hiện tại.
  bool isRequester(String currentUserId) => requesterId == currentUserId;

  /// Lấy userId của người kia (không phải currentUser).
  String otherUserId(String currentUserId) =>
      user1Id == currentUserId ? user2Id : user1Id;

  FriendshipEntity copyWith({
    String? friendshipId,
    String? user1Id,
    String? user2Id,
    FriendshipStatus? status,
    String? requesterId,
    String? actionUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FriendshipEntity(
      friendshipId: friendshipId ?? this.friendshipId,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      status: status ?? this.status,
      requesterId: requesterId ?? this.requesterId,
      actionUserId: actionUserId ?? this.actionUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    friendshipId,
    user1Id,
    user2Id,
    status,
    requesterId,
    actionUserId,
  ];
}
