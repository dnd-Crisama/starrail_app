// lib/features/friend/domain/usecases/decline_friend_request_usecase.dart
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/friend_repository.dart';

class DeclineFriendRequestParams extends Equatable {
  final String friendshipId;
  const DeclineFriendRequestParams({required this.friendshipId});
  @override
  List<Object?> get props => [friendshipId];
}

class DeclineFriendRequestUseCase
    implements UseCase<void, DeclineFriendRequestParams> {
  final FriendRepository _repository;
  DeclineFriendRequestUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(DeclineFriendRequestParams params) {
    return _repository.declineFriendRequest(params.friendshipId);
  }
}
