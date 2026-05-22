// lib/features/server/domain/repositories/server_repository.dart
import '../../../../core/errors/failures.dart';
import '../entities/server_entity.dart';
import '../entities/server_member_entity.dart';

abstract class ServerRepository {
  /// Tạo server mới.
  /// Trả về ServerEntity sau khi tạo.
  /// User hiện tại sẽ trở thành owner.
  Future<ServerEntity> createServer({required String name, String? iconUrl});

  /// Join server bằng invite code.
  /// Ném ServerFailure nếu code không hợp lệ hoặc user đã member.
  Future<ServerEntity> joinServer({required String inviteCode});

  /// Rời khỏi server.
  /// Ném ServerFailure nếu user không phải member.
  Future<void> leaveServer({required String serverId});

  Future<void> kickMember({
    required String serverId,
    required String targetUserId,
  });

  /// Xóa server (chỉ owner).
  /// Ném ServerFailure nếu user không phải owner.
  /// Xóa toàn bộ subcollections.
  Future<void> deleteServer({required String serverId});

  /// Lấy danh sách server của user hiện tại.
  /// Stream để update real-time.
  Stream<List<ServerEntity>> getUserServersStream();

  /// Lấy thông tin server.
  Future<ServerEntity> getServer({required String serverId});

  /// Kiểm tra user có phải member của server.
  Future<bool> isServerMember({
    required String serverId,
    required String userId,
  });

  /// Lắng nghe danh sách thành viên của server.
  Stream<List<ServerMemberEntity>> watchServerMembers({
    required String serverId,
  });
}
