import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/server_member_entity.dart';
import '../repositories/server_repository.dart';

class GetServerMembersParams {
  final String serverId;
  const GetServerMembersParams({required this.serverId});
}

class GetServerMembersUseCase
    implements UseCase<Stream<List<ServerMemberEntity>>, GetServerMembersParams> {
  final ServerRepository repository;
  GetServerMembersUseCase(this.repository);

  @override
  Future<Either<Failure, Stream<List<ServerMemberEntity>>>> call(
    GetServerMembersParams params,
  ) async {
    try {
      final stream = repository.watchServerMembers(serverId: params.serverId);
      return Either.right(stream);
    } catch (e) {
      return Either.left(ServerFailure(message: e.toString()));
    }
  }
}
