// lib/features/friend/domain/usecases/get_outgoing_requests_usecase.dart
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/friendship_entity.dart';
import '../repositories/friend_repository.dart';

class GetOutgoingRequestsParams extends Equatable {
  final String userId;
  const GetOutgoingRequestsParams({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class GetOutgoingRequestsUseCase {
  final FriendRepository _repository;
  GetOutgoingRequestsUseCase(this._repository);

  Stream<Either<Failure, List<FriendshipEntity>>> call(
    GetOutgoingRequestsParams params,
  ) {
    return _repository.watchOutgoingRequests(params.userId);
  }
}
