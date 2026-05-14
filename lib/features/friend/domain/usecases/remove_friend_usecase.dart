// lib/features/friend/domain/usecases/remove_friend_usecase.dart
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/friend_repository.dart';

class RemoveFriendParams extends Equatable {
  final String friendshipId;
  const RemoveFriendParams({required this.friendshipId});
  @override
  List<Object?> get props => [friendshipId];
}

class RemoveFriendUseCase implements UseCase<void, RemoveFriendParams> {
  final FriendRepository _repository;
  RemoveFriendUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(RemoveFriendParams params) {
    return _repository.removeFriend(params.friendshipId);
  }
}
