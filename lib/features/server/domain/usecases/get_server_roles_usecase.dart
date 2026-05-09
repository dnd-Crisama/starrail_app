import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/role_entity.dart';
import '../repositories/role_repository.dart';

class GetServerRolesParams {
  final String serverId;
  const GetServerRolesParams({required this.serverId});
}

class GetServerRolesUseCase
    implements UseCase<Stream<List<RoleEntity>>, GetServerRolesParams> {
  final RoleRepository repository;
  GetServerRolesUseCase(this.repository);

  @override
  Future<Either<Failure, Stream<List<RoleEntity>>>> call(
    GetServerRolesParams params,
  ) async {
    try {
      final stream = repository.getServerRolesStream(serverId: params.serverId);
      return Either.right<Failure, Stream<List<RoleEntity>>>(stream);
    } on Failure catch (failure) {
      return Either.left<Failure, Stream<List<RoleEntity>>>(failure);
    } catch (e) {
      return Either.left<Failure, Stream<List<RoleEntity>>>(
        ServerFailure(message: e.toString()),
      );
    }
  }
}
