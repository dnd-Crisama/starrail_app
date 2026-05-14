// lib/features/friend/data/datasources/friend_remote_datasource.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/data/models/user_model.dart';
import '../models/friendship_model.dart';

abstract class FriendRemoteDatasource {
  /// Tìm user theo username (prefix match, tối đa 20 kết quả).
  Future<List<UserModel>> searchUsersByUsername(String query);

  /// Gửi lời mời kết bạn.
  Future<FriendshipModel> sendFriendRequest(String targetUserId);

  /// Chấp nhận lời mời kết bạn.
  Future<FriendshipModel> acceptFriendRequest(String friendshipId);

  /// Từ chối lời mời kết bạn — xóa document.
  Future<void> declineFriendRequest(String friendshipId);

  /// Hủy lời mời đã gửi — xóa document.
  Future<void> cancelFriendRequest(String friendshipId);

  /// Xóa bạn bè — xóa document.
  Future<void> removeFriend(String friendshipId);

  /// Chặn user — giữ document với status=BLOCKED.
  Future<void> blockUser(String targetUserId);

  /// Stream danh sách bạn bè (ACCEPTED).
  Stream<List<FriendshipModel>> watchFriends(String userId);

  /// Stream lời mời nhận được (PENDING, không phải người gửi).
  Stream<List<FriendshipModel>> watchIncomingRequests(String userId);

  /// Stream lời mời đã gửi (PENDING, là người gửi).
  Stream<List<FriendshipModel>> watchOutgoingRequests(String userId);

  /// Lấy friendship giữa 2 user cụ thể.
  Future<FriendshipModel?> getFriendship(
    String currentUserId,
    String targetUserId,
  );
}

class FriendRemoteDatasourceImpl implements FriendRemoteDatasource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  FriendRemoteDatasourceImpl({required this.firestore, required this.auth});

  String get _currentUserId {
    final uid = auth.currentUser?.uid;
    if (uid == null) throw const AuthException(message: 'Chưa đăng nhập');
    return uid;
  }

  /// Tính user1Id/user2Id dựa trên lexicographic order để đảm bảo unique pair.
  String _user1Id(String a, String b) => a.compareTo(b) < 0 ? a : b;
  String _user2Id(String a, String b) => a.compareTo(b) < 0 ? b : a;

  @override
  Future<List<UserModel>> searchUsersByUsername(String query) async {
    try {
      final normalized = query.toLowerCase().trim();
      // Firestore prefix search: username >= query AND username <= query\uf8ff
      final snapshot = await firestore
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: normalized)
          .where('username', isLessThanOrEqualTo: '$normalized\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs
          .where((doc) => doc.id != _currentUserId) // loại trừ chính mình
          .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Tìm kiếm user thất bại: $e');
    }
  }

  @override
  Future<FriendshipModel> sendFriendRequest(String targetUserId) async {
    try {
      final currentId = _currentUserId;

      if (currentId == targetUserId) {
        throw const ServerException(
          message: 'Không thể kết bạn với chính mình',
        );
      }

      final u1 = _user1Id(currentId, targetUserId);
      final u2 = _user2Id(currentId, targetUserId);

      // Kiểm tra đã tồn tại friendship chưa
      final existing = await firestore
          .collection('friendships')
          .where('user1Id', isEqualTo: u1)
          .where('user2Id', isEqualTo: u2)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        final existingStatus = existing.docs.first.data()['status'];
        if (existingStatus == 'BLOCKED') {
          throw const ServerException(
            message: 'Không thể gửi lời mời cho người dùng này',
          );
        }
        throw const ServerException(
          message: 'Đã có mối quan hệ với người dùng này',
        );
      }

      // Tạo document mới
      final ref = firestore.collection('friendships').doc();
      final model = FriendshipModel(
        friendshipId: ref.id,
        user1Id: u1,
        user2Id: u2,
        status: 'PENDING',
        requesterId: currentId,
        actionUserId: currentId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.set(model.toFirestore());
      Logger.info(
        'Friend request sent: $currentId -> $targetUserId',
        tag: 'FriendDatasource',
      );
      return model;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Gửi lời mời thất bại: $e');
    }
  }

  @override
  Future<FriendshipModel> acceptFriendRequest(String friendshipId) async {
    try {
      final currentId = _currentUserId;
      final ref = firestore.collection('friendships').doc(friendshipId);
      final doc = await ref.get();

      if (!doc.exists) {
        throw const ServerException(message: 'Lời mời không tồn tại');
      }

      final data = doc.data()!;
      final requesterId = data['requesterId'] as String;

      // Chỉ người nhận mới được chấp nhận
      if (requesterId == currentId) {
        throw const ServerException(
          message: 'Không thể chấp nhận lời mời của chính mình',
        );
      }

      await ref.update({
        'status': 'ACCEPTED',
        'actionUserId': currentId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final updatedDoc = await ref.get();
      return FriendshipModel.fromFirestore(updatedDoc.data()!, friendshipId);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Chấp nhận lời mời thất bại: $e');
    }
  }

  @override
  Future<void> declineFriendRequest(String friendshipId) async {
    try {
      await firestore.collection('friendships').doc(friendshipId).delete();
      Logger.info('Friend request declined: $friendshipId', tag: 'FriendDatasource');
    } catch (e) {
      throw ServerException(message: 'Từ chối lời mời thất bại: $e');
    }
  }

  @override
  Future<void> cancelFriendRequest(String friendshipId) async {
    try {
      final currentId = _currentUserId;
      final doc = await firestore
          .collection('friendships')
          .doc(friendshipId)
          .get();

      if (!doc.exists) {
        throw const ServerException(message: 'Lời mời không tồn tại');
      }

      // Chỉ người gửi mới được hủy
      final requesterId = doc.data()!['requesterId'] as String;
      if (requesterId != currentId) {
        throw const ServerException(
          message: 'Chỉ người gửi mới có thể hủy lời mời',
        );
      }

      await firestore.collection('friendships').doc(friendshipId).delete();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Hủy lời mời thất bại: $e');
    }
  }

  @override
  Future<void> removeFriend(String friendshipId) async {
    try {
      await firestore.collection('friendships').doc(friendshipId).delete();
      Logger.info('Friend removed: $friendshipId', tag: 'FriendDatasource');
    } catch (e) {
      throw ServerException(message: 'Xóa bạn thất bại: $e');
    }
  }

  @override
  Future<void> blockUser(String targetUserId) async {
    try {
      final currentId = _currentUserId;
      final u1 = _user1Id(currentId, targetUserId);
      final u2 = _user2Id(currentId, targetUserId);

      // Kiểm tra đã có friendship chưa
      final existing = await firestore
          .collection('friendships')
          .where('user1Id', isEqualTo: u1)
          .where('user2Id', isEqualTo: u2)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        // Cập nhật thành BLOCKED
        await existing.docs.first.reference.update({
          'status': 'BLOCKED',
          'actionUserId': currentId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Tạo document mới với trạng thái BLOCKED
        final ref = firestore.collection('friendships').doc();
        await ref.set({
          'user1Id': u1,
          'user2Id': u2,
          'status': 'BLOCKED',
          'requesterId': currentId,
          'actionUserId': currentId,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      Logger.info('User blocked: $targetUserId', tag: 'FriendDatasource');
    } catch (e) {
      throw ServerException(message: 'Chặn user thất bại: $e');
    }
  }

  @override
  Stream<List<FriendshipModel>> watchFriends(String userId) {
    // Lắng nghe cả hai chiều: user là user1 hoặc user2
    final stream1 = firestore
        .collection('friendships')
        .where('user1Id', isEqualTo: userId)
        .where('status', isEqualTo: 'ACCEPTED')
        .snapshots();

    final stream2 = firestore
        .collection('friendships')
        .where('user2Id', isEqualTo: userId)
        .where('status', isEqualTo: 'ACCEPTED')
        .snapshots();

    // Kết hợp 2 stream bằng cách transform stream1 và stream2
    // Dùng asyncExpand để merge thủ công
    return _mergeQueryStreams(stream1, stream2, userId);
  }

  @override
  Stream<List<FriendshipModel>> watchIncomingRequests(String userId) {
    final stream1 = firestore
        .collection('friendships')
        .where('user1Id', isEqualTo: userId)
        .where('status', isEqualTo: 'PENDING')
        .snapshots();

    final stream2 = firestore
        .collection('friendships')
        .where('user2Id', isEqualTo: userId)
        .where('status', isEqualTo: 'PENDING')
        .snapshots();

    return _mergeQueryStreams(stream1, stream2, userId).map((friendships) {
      // Chỉ lấy những lời mời mà userId KHÔNG phải người gửi
      return friendships
          .where((f) => f.requesterId != userId)
          .toList();
    });
  }

  @override
  Stream<List<FriendshipModel>> watchOutgoingRequests(String userId) {
    final stream1 = firestore
        .collection('friendships')
        .where('user1Id', isEqualTo: userId)
        .where('status', isEqualTo: 'PENDING')
        .snapshots();

    final stream2 = firestore
        .collection('friendships')
        .where('user2Id', isEqualTo: userId)
        .where('status', isEqualTo: 'PENDING')
        .snapshots();

    return _mergeQueryStreams(stream1, stream2, userId).map((friendships) {
      // Chỉ lấy những lời mời mà userId là người gửi
      return friendships
          .where((f) => f.requesterId == userId)
          .toList();
    });
  }

  @override
  Future<FriendshipModel?> getFriendship(
    String currentUserId,
    String targetUserId,
  ) async {
    try {
      final u1 = _user1Id(currentUserId, targetUserId);
      final u2 = _user2Id(currentUserId, targetUserId);

      final snapshot = await firestore
          .collection('friendships')
          .where('user1Id', isEqualTo: u1)
          .where('user2Id', isEqualTo: u2)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return FriendshipModel.fromFirestore(doc.data(), doc.id);
    } catch (e) {
      throw ServerException(message: 'Lấy friendship thất bại: $e');
    }
  }

  /// Merge 2 stream query thành 1 stream duy nhất, loại trùng lặp.
  /// Firestore không hỗ trợ OR query nên cần merge thủ công.
  Stream<List<FriendshipModel>> _mergeQueryStreams(
    Stream<QuerySnapshot<Map<String, dynamic>>> stream1,
    Stream<QuerySnapshot<Map<String, dynamic>>> stream2,
    String userId,
  ) {
    // Dùng 2 biến để lưu kết quả mới nhất của mỗi stream
    List<FriendshipModel> list1 = [];
    List<FriendshipModel> list2 = [];

    late StreamController<List<FriendshipModel>> controller;

    controller = StreamController<List<FriendshipModel>>(
      onListen: () {
        stream1.listen(
          (snapshot) {
            list1 = snapshot.docs
                .map(
                  (doc) => FriendshipModel.fromFirestore(doc.data(), doc.id),
                )
                .toList();
            if (!controller.isClosed) {
              controller.add(_mergeLists(list1, list2));
            }
          },
          onError: (e) {
            if (!controller.isClosed) controller.addError(e);
          },
        );

        stream2.listen(
          (snapshot) {
            list2 = snapshot.docs
                .map(
                  (doc) => FriendshipModel.fromFirestore(doc.data(), doc.id),
                )
                .toList();
            if (!controller.isClosed) {
              controller.add(_mergeLists(list1, list2));
            }
          },
          onError: (e) {
            if (!controller.isClosed) controller.addError(e);
          },
        );
      },
      onCancel: () => controller.close(),
    );

    return controller.stream;
  }

  List<FriendshipModel> _mergeLists(
    List<FriendshipModel> list1,
    List<FriendshipModel> list2,
  ) {
    final map = <String, FriendshipModel>{};
    for (final item in [...list1, ...list2]) {
      map[item.friendshipId] = item;
    }
    return map.values.toList();
  }
}


