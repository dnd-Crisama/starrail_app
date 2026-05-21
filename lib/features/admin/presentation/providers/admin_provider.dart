import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../server/data/models/server_model.dart';
import '../../../server/domain/entities/server_entity.dart';

enum AdminUserFilter { all, regular, superAdmin, disabled }

final adminUserSearchQueryProvider = StateProvider<String>((ref) => '');
final adminServerSearchQueryProvider = StateProvider<String>((ref) => '');
final adminUserFilterProvider = StateProvider<AdminUserFilter>(
  (ref) => AdminUserFilter.all,
);

final isCurrentUserSuperAdminProvider = StreamProvider<bool>((ref) {
  final userId = ref.watch(
    authNotifierProvider.select((state) => state.user?.uid),
  );
  if (userId == null || userId.isEmpty) return Stream.value(false);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) => doc.data()?['isSuperAdmin'] as bool? ?? false);
});

final adminUsersStreamProvider = StreamProvider<List<UserEntity>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (doc) => UserModel.fromFirestore(doc.data(), doc.id).toEntity(),
            )
            .toList(),
      );
});

final adminServersStreamProvider = StreamProvider<List<ServerEntity>>((ref) {
  return FirebaseFirestore.instance
      .collection('servers')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (doc) => ServerModel.fromFirestore(doc.data(), doc.id).toEntity(),
            )
            .toList(),
      );
});

final filteredAdminUsersProvider = Provider<AsyncValue<List<UserEntity>>>((
  ref,
) {
  final usersAsync = ref.watch(adminUsersStreamProvider);
  final query = ref.watch(adminUserSearchQueryProvider).trim().toLowerCase();
  final filter = ref.watch(adminUserFilterProvider);

  return usersAsync.whenData((users) {
    return users
        .where((user) {
          final matchesFilter = switch (filter) {
            AdminUserFilter.all => true,
            AdminUserFilter.regular => !user.isSuperAdmin,
            AdminUserFilter.superAdmin => user.isSuperAdmin,
            AdminUserFilter.disabled => user.isDisabled,
          };
          if (!matchesFilter) return false;

          if (query.isEmpty) return true;
          return user.username.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query) ||
              user.uid.toLowerCase().contains(query);
        })
        .toList(growable: false);
  });
});

final filteredAdminServersProvider = Provider<AsyncValue<List<ServerEntity>>>((
  ref,
) {
  final serversAsync = ref.watch(adminServersStreamProvider);
  final query = ref.watch(adminServerSearchQueryProvider).trim().toLowerCase();

  return serversAsync.whenData((servers) {
    if (query.isEmpty) return servers;
    return servers
        .where((server) {
          return server.name.toLowerCase().contains(query) ||
              server.serverId.toLowerCase().contains(query) ||
              server.ownerId.toLowerCase().contains(query) ||
              server.inviteCode.toLowerCase().contains(query);
        })
        .toList(growable: false);
  });
});

class AdminActionState {
  final bool isLoading;
  final String? errorMessage;

  const AdminActionState({this.isLoading = false, this.errorMessage});

  AdminActionState copyWith({bool? isLoading, String? errorMessage}) {
    return AdminActionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AdminActionNotifier extends StateNotifier<AdminActionState> {
  final Ref _ref;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AdminActionNotifier({
    required Ref ref,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _ref = ref,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       super(const AdminActionState());

  Future<bool> setUserDisabled({
    required String userId,
    required bool isDisabled,
  }) async {
    return _runAdminAction(() async {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == userId && isDisabled) {
        throw Exception('Không thể khóa tài khoản đang đăng nhập');
      }
      await _firestore.collection('users').doc(userId).update({
        'isDisabled': isDisabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<bool> setUserSuperAdmin({
    required String userId,
    required bool isSuperAdmin,
  }) async {
    return _runAdminAction(() async {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == userId && !isSuperAdmin) {
        throw Exception('Không thể tự gỡ quyền super admin của chính mình');
      }
      await _firestore.collection('users').doc(userId).update({
        'isSuperAdmin': isSuperAdmin,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<bool> setServerSuspended({
    required String serverId,
    required bool isSuspended,
  }) async {
    return _runAdminAction(() async {
      await _firestore.collection('servers').doc(serverId).update({
        'isSuspended': isSuspended,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<bool> deleteServer({required String serverId}) async {
    return _runAdminAction(() async {
      final serverRef = _firestore.collection('servers').doc(serverId);

      final channels = await serverRef.collection('channels').get();
      for (final channel in channels.docs) {
        final messages = await channel.reference.collection('messages').get();
        final messagesBatch = _firestore.batch();
        for (final message in messages.docs) {
          messagesBatch.delete(message.reference);
        }
        await messagesBatch.commit();
      }

      for (final collectionName in ['members', 'roles', 'channels']) {
        await _deleteCollection(serverRef.collection(collectionName));
      }
      await serverRef.delete();
    });
  }

  Future<void> _deleteCollection(CollectionReference collection) async {
    final snapshot = await collection.get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<bool> _runAdminAction(Future<void> Function() action) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final isAdmin = await _ref.read(isCurrentUserSuperAdminProvider.future);
      if (!isAdmin) {
        throw Exception('Bạn không có quyền super admin');
      }
      await action();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final adminActionNotifierProvider =
    StateNotifierProvider<AdminActionNotifier, AdminActionState>((ref) {
      return AdminActionNotifier(ref: ref);
    });
