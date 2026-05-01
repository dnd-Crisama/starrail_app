import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class UpdateStatusParams {
  final UserStatus status;
  const UpdateStatusParams({required this.status});
}

class UpdateStatusUseCase implements UseCase<void, UpdateStatusParams> {
  final UserRepository repository;
  UpdateStatusUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateStatusParams params) async {
    try {
      await repository.updateStatus(params.status);
      return Either.right<Failure, void>(null);
    } on Failure catch (failure) {
      return Either.left<Failure, void>(failure);
    } catch (e) {
      return Either.left<Failure, void>(ServerFailure(message: e.toString()));
    }
  }
}
