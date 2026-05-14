// lib/features/friend/domain/usecases/accept_friend_request_usecase.dart
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../entities/friendship_entity.dart';
import '../repositories/friend_repository.dart';

class AcceptFriendRequestParams extends Equatable {
  final String friendshipId;
  const AcceptFriendRequestParams({required this.friendshipId});
  @override
  List<Object?> get props => [friendshipId];
}

class AcceptFriendRequestUseCase
    implements UseCase<FriendshipEntity, AcceptFriendRequestParams> {
  final FriendRepository _repository;
  AcceptFriendRequestUseCase(this._repository);

  @override
  Future<Either<Failure, FriendshipEntity>> call(
    AcceptFriendRequestParams params,
  ) {
    return _repository.acceptFriendRequest(params.friendshipId);
  }
}
