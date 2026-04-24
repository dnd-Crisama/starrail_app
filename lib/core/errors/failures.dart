import 'package:equatable/equatable.dart';

/// Base class cho Domain layer errors.
/// Failure là dữ liệu sạch, không phụ thuộc framework hay Firebase.
/// UseCase nhận Failure thay vì Exception.
abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Lỗi từ server/backend.
class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

/// Lỗi từ cache/local storage.
class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

/// Lỗi mạng.
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}

/// Lỗi xác thực.
class AuthFailure extends Failure {
  final String? code;

  const AuthFailure({required super.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Lỗi upload/storage.
class StorageFailure extends Failure {
  const StorageFailure({required super.message});
}

/// Lỗi không xác định.
class UnknownFailure extends Failure {
  const UnknownFailure({required super.message});
}
