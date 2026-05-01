import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_datasource.dart';
import '../datasources/storage_remote_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDatasource userRemoteDatasource;
  final StorageRemoteDatasource storageRemoteDatasource;
  final String currentUserId;

  UserRepositoryImpl({
    required this.userRemoteDatasource,
    required this.storageRemoteDatasource,
    required this.currentUserId,
  });

  @override
  Future<UserEntity> getCurrentUser() async {
    try {
      final userModel = await userRemoteDatasource.getUserData(currentUserId);
      return userModel.toEntity();
    } on CacheException {
      rethrow;
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<UserEntity> updateProfile({
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      // 1. Nếu có đổi username, kiểm tra duy nhất trước
      if (username != null && username.isNotEmpty) {
        final exists = await userRemoteDatasource.checkUsernameExists(username);
        if (exists) {
          throw const ServerFailure(message: 'Tên người dùng đã tồn tại.');
        }
      }

      // 2. Tạo map dữ liệu cần update trực tiếp (không cần tạo object UserModel)
      final Map<String, dynamic> updateData = {};
      if (username != null && username.isNotEmpty)
        updateData['username'] = username.toLowerCase().trim();
      if (bio != null) updateData['bio'] = bio;
      if (avatarUrl != null) updateData['avatarUrl'] = avatarUrl;

      // 3. Gọi Firestore update
      final updatedUserModel = await userRemoteDatasource.updateProfileData(
        currentUserId,
        updateData,
      );

      return updatedUserModel.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> updateStatus(UserStatus status) async {
    try {
      await userRemoteDatasource.updateStatus(
        currentUserId,
        status.name.toUpperCase(),
      );
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
