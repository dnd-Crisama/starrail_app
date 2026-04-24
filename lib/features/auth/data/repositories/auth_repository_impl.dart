import 'package:firebase_auth/firebase_auth.dart' hide AuthException;
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/user_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource authRemoteDatasource;
  final UserRemoteDatasource userRemoteDatasource;

  AuthRepositoryImpl({
    required this.authRemoteDatasource,
    required this.userRemoteDatasource,
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
      return newUser.toEntity().copyWith(status: UserStatus.online);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      final firebaseUser = await authRemoteDatasource.getCurrentFirebaseUser();
      if (firebaseUser != null) {
        // Cập nhật offline trước khi cắt kết nối
        await userRemoteDatasource.updateStatus(firebaseUser.uid, 'OFFLINE');
      }
      await authRemoteDatasource.signOut();
    } catch (e) {
      // Dù lỗi vẫn cố sign out để user không bị kẹt
      await authRemoteDatasource.signOut();
      throw ServerFailure(message: e.toString());
    }
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
      return userModel.toEntity();
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
}
