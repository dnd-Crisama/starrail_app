// lib/features/friend/data/models/friendship_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/friendship_entity.dart';

class FriendshipModel {
  final String friendshipId;
  final String user1Id;
  final String user2Id;
  final String status; // PENDING, ACCEPTED, BLOCKED
  final String requesterId;
  final String actionUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FriendshipModel({
    required this.friendshipId,
    required this.user1Id,
    required this.user2Id,
    required this.status,
    required this.requesterId,
    required this.actionUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FriendshipModel.fromFirestore(
    Map<String, dynamic> map,
    String docId,
  ) {
    return FriendshipModel(
      friendshipId: docId,
      user1Id: map['user1Id'] as String? ?? '',
      user2Id: map['user2Id'] as String? ?? '',
      status: map['status'] as String? ?? 'PENDING',
      requesterId: map['requesterId'] as String? ?? '',
      actionUserId: map['actionUserId'] as String? ?? '',
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'status': status,
      'requesterId': requesterId,
      'actionUserId': actionUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toFirestoreUpdate() {
    return {
      'status': status,
      'actionUserId': actionUserId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  FriendshipEntity toEntity() {
    return FriendshipEntity(
      friendshipId: friendshipId,
      user1Id: user1Id,
      user2Id: user2Id,
      status: _parseStatus(status),
      requesterId: requesterId,
      actionUserId: actionUserId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static FriendshipStatus _parseStatus(String status) {
    switch (status) {
      case 'ACCEPTED':
        return FriendshipStatus.accepted;
      case 'BLOCKED':
        return FriendshipStatus.blocked;
      default:
        return FriendshipStatus.pending;
    }
  }

  static String statusToString(FriendshipStatus status) {
    switch (status) {
      case FriendshipStatus.accepted:
        return 'ACCEPTED';
      case FriendshipStatus.blocked:
        return 'BLOCKED';
      case FriendshipStatus.pending:
        return 'PENDING';
    }
  }
}
