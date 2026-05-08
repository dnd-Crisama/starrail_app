// lib/features/server/domain/usecases/get_user_servers_usecase.dart
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/server_entity.dart';
import '../repositories/server_repository.dart';

class GetUserServersUseCase
    implements UseCase<Stream<List<ServerEntity>>, NoParams> {
  final ServerRepository repository;
  GetUserServersUseCase(this.repository);

  @override
  Future<Either<Failure, Stream<List<ServerEntity>>>> call(
    NoParams params,
  ) async {
    try {
      final stream = repository.getUserServersStream();
      return Either.right<Failure, Stream<List<ServerEntity>>>(stream);
    } catch (e) {
      return Either.left<Failure, Stream<List<ServerEntity>>>(
        ServerFailure(message: e.toString()),
      );
    }
  }
}
