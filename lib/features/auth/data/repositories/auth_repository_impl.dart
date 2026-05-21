import 'dart:async';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/presence_remote_datasource.dart';
import '../datasources/user_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource authRemoteDatasource;
  final UserRemoteDatasource userRemoteDatasource;
  final PresenceRemoteDatasource presenceRemoteDatasource;

  AuthRepositoryImpl({
    required this.authRemoteDatasource,
    required this.userRemoteDatasource,
    required this.presenceRemoteDatasource,
  });

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Auth với Firebase
      final userCredential = await authRemoteDatasource.signIn(
        email: email,
        password: password,
      );
      final uid = userCredential.user!.uid;

      // 2. Lấy profile từ Firestore
      final userModel = await userRemoteDatasource.getUserData(uid);

      // 3. Cập nhật trạng thái Online
      await userRemoteDatasource.updateStatus(uid, 'ONLINE');
      _updateRealtimePresenceBestEffort(uid, 'ONLINE');

      return userModel.toEntity().copyWith(status: UserStatus.online);
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message, code: e.code);
    } on CacheException catch (_) {
      throw const CacheFailure(
        message: 'Tài khoản chưa được thiết lập profile. Vui lòng tạo profile.',
      );
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<UserEntity> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // 1. Tạo Auth user
      final userCredential = await authRemoteDatasource.signUp(
        email: email,
        password: password,
      );
      final uid = userCredential.user!.uid;

      // 2. Kiểm tra username duy nhất
      final exists = await userRemoteDatasource.checkUsernameExists(username);
      if (exists) {
        // Nếu trùng, xóa tài khoản Auth vừa tạo để dọn dẹp
        await userCredential.user?.delete();
        throw const ServerFailure(message: 'Tên người dùng đã tồn tại.');
      }

      // 3. Tạo Firestore document
      final newUser = UserModel(
        uid: uid,
        username: username,
        email: email,
        status: 'ONLINE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastSeenAt: DateTime.now(),
      );

      await userRemoteDatasource.createUserDocument(newUser);
      _updateRealtimePresenceBestEffort(uid, 'ONLINE');

      return newUser.toEntity().copyWith(status: UserStatus.online);
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<UserEntity> createProfile({required String username}) async {
    try {
      final firebaseUser = await authRemoteDatasource.getCurrentFirebaseUser();
      if (firebaseUser == null) {
        throw const AuthFailure(message: 'Chưa đăng nhập.');
      }

      final exists = await userRemoteDatasource.checkUsernameExists(username);
      if (exists) {
        throw const ServerFailure(message: 'Tên người dùng đã tồn tại.');
      }

      final newUser = UserModel(
        uid: firebaseUser.uid,
        username: username,
        email: firebaseUser.email ?? '',
        status: 'ONLINE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastSeenAt: DateTime.now(),
      );

      await userRemoteDatasource.createUserDocument(newUser);
      _updateRealtimePresenceBestEffort(firebaseUser.uid, 'ONLINE');
      return newUser.toEntity().copyWith(status: UserStatus.online);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> logout() async {
    final firebaseUser = await authRemoteDatasource.getCurrentFirebaseUser();
    if (firebaseUser != null) {
        // Cập nhật offline trước khi cắt kết nối
      await userRemoteDatasource
          .updateStatus(firebaseUser.uid, 'OFFLINE')
          .timeout(const Duration(seconds: 5))
          .catchError((_) {});
      _updateRealtimePresenceBestEffort(firebaseUser.uid, 'OFFLINE');
    }
    await authRemoteDatasource.signOut();
      // Dù lỗi vẫn cố sign out để user không bị kẹt
  }

  @override
  Future<UserEntity> getCurrentUser() async {
    try {
      final firebaseUser = await authRemoteDatasource.getCurrentFirebaseUser();
      if (firebaseUser == null) {
        throw const AuthFailure(message: 'Chưa đăng nhập.');
      }

      final userModel = await userRemoteDatasource.getUserData(
        firebaseUser.uid,
      );
      final user = userModel.toEntity();
      if (user.status != UserStatus.invisible && user.status != UserStatus.dnd) {
        await userRemoteDatasource.updateStatus(firebaseUser.uid, 'ONLINE');
        _updateRealtimePresenceBestEffort(firebaseUser.uid, 'ONLINE');
        return user.copyWith(status: UserStatus.online);
      }

      return user;
    } on CacheException {
      rethrow; // Ném lỗi lên trên để router biết là chưa có profile
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<bool> checkUsernameExists(String username) async {
    try {
      return await userRemoteDatasource.checkUsernameExists(username);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  void _updateRealtimePresenceBestEffort(String uid, String status) {
    unawaited(
      presenceRemoteDatasource
          .updatePresenceStatus(uid, status)
          .timeout(const Duration(seconds: 3))
          .catchError((_) {}),
    );
  }
}
