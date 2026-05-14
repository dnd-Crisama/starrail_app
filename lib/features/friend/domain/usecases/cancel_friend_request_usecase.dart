// lib/features/friend/domain/usecases/cancel_friend_request_usecase.dart
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/friend_repository.dart';

class CancelFriendRequestParams extends Equatable {
  final String friendshipId;
  const CancelFriendRequestParams({required this.friendshipId});
  @override
  List<Object?> get props => [friendshipId];
}

/// Người gửi request hủy lời mời của mình.
class CancelFriendRequestUseCase
    implements UseCase<void, CancelFriendRequestParams> {
  final FriendRepository _repository;
  CancelFriendRequestUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(CancelFriendRequestParams params) {
    return _repository.cancelFriendRequest(params.friendshipId);
  }
}
