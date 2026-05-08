// lib/features/server/domain/usecases/delete_server_usecase.dart
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/server_repository.dart';

class DeleteServerParams {
  final String serverId;
  const DeleteServerParams({required this.serverId});
}

class DeleteServerUseCase implements UseCase<void, DeleteServerParams> {
  final ServerRepository repository;
  DeleteServerUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteServerParams params) async {
    try {
      await repository.deleteServer(serverId: params.serverId);
      return Either.right<Failure, void>(null);
    } on Failure catch (failure) {
      return Either.left<Failure, void>(failure);
    } catch (e) {
      return Either.left<Failure, void>(ServerFailure(message: e.toString()));
    }
  }
}
