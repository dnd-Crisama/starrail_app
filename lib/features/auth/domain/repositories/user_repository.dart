import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class UserRepository {
  /// Lấy thông tin user hiện tại.
  Future<UserEntity> getCurrentUser();

  /// Cập nhật profile (username, bio, avatarUrl).
  /// Nếu một field là null, nó sẽ không được cập nhật.
  Future<UserEntity> updateProfile({
    String? username,
    String? bio,
    String? avatarUrl,
  });

  /// Cập nhật trạng thái presence (online, idle, offline).
  Future<void> updateStatus(UserStatus status);

  /// Kiểm tra username đã tồn tại chưa (trừ user hiện tại).
  Future<bool> checkUsernameExists(String username);
}
