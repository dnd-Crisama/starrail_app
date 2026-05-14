// lib/features/friend/domain/usecases/block_user_usecase.dart
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/friend_repository.dart';

class BlockUserParams extends Equatable {
  final String targetUserId;
  const BlockUserParams({required this.targetUserId});
  @override
  List<Object?> get props => [targetUserId];
}

/// Chặn user. Document friendship được giữ lại với status=BLOCKED.
class BlockUserUseCase implements UseCase<void, BlockUserParams> {
  final FriendRepository _repository;
  BlockUserUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(BlockUserParams params) {
    return _repository.blockUser(params.targetUserId);
  }
}
