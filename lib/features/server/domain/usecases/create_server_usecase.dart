// lib/features/server/domain/usecases/create_server_usecase.dart
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/server_entity.dart';
import '../repositories/server_repository.dart';

class CreateServerParams {
  final String name;
  final String? iconUrl;
  const CreateServerParams({required this.name, this.iconUrl});
}

class CreateServerUseCase implements UseCase<ServerEntity, CreateServerParams> {
  final ServerRepository repository;
  CreateServerUseCase(this.repository);

  @override
  Future<Either<Failure, ServerEntity>> call(CreateServerParams params) async {
    try {
      final server = await repository.createServer(
        name: params.name,
        iconUrl: params.iconUrl,
      );
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
