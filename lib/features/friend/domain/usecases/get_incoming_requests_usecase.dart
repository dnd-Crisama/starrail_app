// lib/features/friend/domain/usecases/get_incoming_requests_usecase.dart
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/friendship_entity.dart';
import '../repositories/friend_repository.dart';

class GetIncomingRequestsParams extends Equatable {
  final String userId;
  const GetIncomingRequestsParams({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class GetIncomingRequestsUseCase {
  final FriendRepository _repository;
  GetIncomingRequestsUseCase(this._repository);

  Stream<Either<Failure, List<FriendshipEntity>>> call(
    GetIncomingRequestsParams params,
  ) {
    return _repository.watchIncomingRequests(params.userId);
  }
}
