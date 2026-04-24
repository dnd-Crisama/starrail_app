import 'package:equatable/equatable.dart';
import '../errors/failures.dart';

/// Base class cho tất cả UseCase.
/// Đổi 'Type' thành 'T' để tránh trùng với class Type mặc định của Dart.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();
  @override
  List<Object?> get props => [];
}

/// Custom Either class để xử lý Success/Failure không cần thư viện fpdart.
class Either<L, R> {
  final L? _left;
  final R? _right;
  final bool _isLeft;

  Either._left(this._left) : _right = null, _isLeft = true;
  Either._right(this._right) : _left = null, _isLeft = false;

  bool get isLeft => _isLeft;
  bool get isRight => !_isLeft;

  static Either<L, R> left<L, R>(L value) => Either._left(value);
  static Either<L, R> right<L, R>(R value) => Either._right(value);

  T fold<T>({
    required T Function(L left) ifLeft,
    required T Function(R right) ifRight,
  }) {
    if (_isLeft) {
      return ifLeft(_left as L);
    } else {
      return ifRight(_right as R);
    }
  }
}
