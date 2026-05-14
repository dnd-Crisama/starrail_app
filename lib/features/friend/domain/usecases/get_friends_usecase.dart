// lib/features/friend/domain/usecases/get_friends_usecase.dart
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../entities/friendship_entity.dart';
import '../repositories/friend_repository.dart';

class GetFriendsParams extends Equatable {
  final String userId;
  const GetFriendsParams({required this.userId});
  @override
  List<Object?> get props => [userId];
}

/// UseCase trả về Stream danh sách bạn bè (status=ACCEPTED) theo real-time.
class GetFriendsUseCase {
  final FriendRepository _repository;
  GetFriendsUseCase(this._repository);

  Stream<Either<Failure, List<FriendshipEntity>>> call(
    GetFriendsParams params,
  ) {
    return _repository.watchFriends(params.userId);
  }
}
