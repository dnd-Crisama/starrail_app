import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Đăng nhập bằng email và password.
  /// Trả về UserEntity nếu thành công.
  /// Ném AuthFailure nếu sai thông tin.
  Future<UserEntity> login({required String email, required String password});

  /// Đăng ký tài khoản mới và tạo profile.
  /// Ném AuthFailure nếu email tồn tại.
  /// Ném ServerFailure nếu username đã bị lấy.
  Future<UserEntity> register({
    required String email,
    required String password,
    required String username,
  });

  /// Tạo username cho user đã đăng nhập bằng Auth nhưng chưa có profile.
  Future<UserEntity> createProfile({required String username});

  /// Đăng xuất, cập nhật status offline trước khi cut session.
  Future<void> logout();

  /// Lấy thông tin user hiện tại từ Firestore.
  /// Ném CacheFailure nếu không tìm thấy document (chưa tạo profile).
  Future<UserEntity> getCurrentUser();

  /// Kiểm tra username đã tồn tại chưa.
  Future<bool> checkUsernameExists(String username);
}
