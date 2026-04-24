import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

/// Giao tiếp trực tiếp với Cloud Firestore collection 'users'.
abstract class UserRemoteDatasource {
  Future<void> createUserDocument(UserModel user);
  Future<UserModel> getUserData(String uid);
  Future<bool> checkUsernameExists(String username);
  Future<void> updateStatus(String uid, String status);
}

class UserRemoteDatasourceImpl implements UserRemoteDatasource {
  final FirebaseFirestore firestore;

  UserRemoteDatasourceImpl({required this.firestore});

  @override
  Future<void> createUserDocument(UserModel user) async {
    try {
      await firestore.collection('users').doc(user.uid).set(user.toFirestore());
    } catch (e) {
      throw ServerException(message: 'Failed to create user document: $e');
    }
  }

  @override
  Future<UserModel> getUserData(String uid) async {
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        throw const CacheException(message: 'User document not found');
      }
      return UserModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw ServerException(message: 'Failed to get user data: $e');
    }
  }

  @override
  Future<bool> checkUsernameExists(String username) async {
    try {
      final normalizedUsername = username.toLowerCase().trim();
      final querySnapshot = await firestore
          .collection('users')
          .where('username', isEqualTo: normalizedUsername)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw ServerException(message: 'Failed to check username: $e');
    }
  }

  @override
  Future<void> updateStatus(String uid, String status) async {
    try {
      await firestore.collection('users').doc(uid).update({
        'status': status,
        'lastSeenAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException(message: 'Failed to update status: $e');
    }
  }
}
