/// Base exception cho Data layer.
/// Được throw bởi Datasource khi giao tiếp với Firebase, Storage, v.v.
/// Không được để lọt ra ngoài Data layer — phải được catch và map thành Failure.
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException({required this.message, this.code});

  @override
  String toString() => '$runtimeType: $message (code: $code)';
}

/// Lỗi từ server-side (Firebase, API).
class ServerException extends AppException {
  const ServerException({required super.message, super.code});
}

/// Lỗi từ cache/local storage.
class CacheException extends AppException {
  const CacheException({required super.message, super.code});
}

/// Lỗi mạng (không có kết nối, timeout).
class NetworkException extends AppException {
  const NetworkException({required super.message, super.code});
}

/// Lỗi xác thực (Firebase Auth).
class AuthException extends AppException {
  const AuthException({required super.message, super.code});
}

/// Lỗi upload file.
class StorageException extends AppException {
  const StorageException({required super.message, super.code});
}

/// Lỗi không xác định được loại.
class UnknownException extends AppException {
  const UnknownException({required super.message, super.code});
}
