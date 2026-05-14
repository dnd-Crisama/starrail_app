// lib/features/friend/domain/usecases/send_friend_request_usecase.dart
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../entities/friendship_entity.dart';
import '../repositories/friend_repository.dart';

class SendFriendRequestParams extends Equatable {
  final String targetUserId;
  const SendFriendRequestParams({required this.targetUserId});
  @override
  List<Object?> get props => [targetUserId];
}

/// Gửi lời mời kết bạn đến người dùng khác.
class SendFriendRequestUseCase
    implements UseCase<FriendshipEntity, SendFriendRequestParams> {
  final FriendRepository _repository;
  SendFriendRequestUseCase(this._repository);

  @override
  Future<Either<Failure, FriendshipEntity>> call(
    SendFriendRequestParams params,
  ) {
    return _repository.sendFriendRequest(params.targetUserId);
  }
}
