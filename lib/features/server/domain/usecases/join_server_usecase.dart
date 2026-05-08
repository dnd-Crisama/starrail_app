// lib/features/server/domain/usecases/join_server_usecase.dart
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/server_entity.dart';
import '../repositories/server_repository.dart';

class JoinServerParams {
  final String inviteCode;
  const JoinServerParams({required this.inviteCode});
}

class JoinServerUseCase implements UseCase<ServerEntity, JoinServerParams> {
  final ServerRepository repository;
  JoinServerUseCase(this.repository);

  @override
  Future<Either<Failure, ServerEntity>> call(JoinServerParams params) async {
    try {
      final server = await repository.joinServer(inviteCode: params.inviteCode);
      return Either.right<Failure, ServerEntity>(server);
    } on Failure catch (failure) {
      return Either.left<Failure, ServerEntity>(failure);
    } catch (e) {
      return Either.left<Failure, ServerEntity>(
        ServerFailure(message: e.toString()),
      );
    }
  }
}
