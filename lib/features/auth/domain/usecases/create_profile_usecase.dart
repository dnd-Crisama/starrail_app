import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class CreateProfileParams {
  final String username;
  const CreateProfileParams({required this.username});
}

class CreateProfileUseCase implements UseCase<UserEntity, CreateProfileParams> {
  final AuthRepository repository;
  CreateProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(CreateProfileParams params) async {
    try {
      final user = await repository.createProfile(username: params.username);
      return Either.right<Failure, UserEntity>(user);
    } on Failure catch (failure) {
      return Either.left<Failure, UserEntity>(failure);
    } catch (e) {
      return Either.left<Failure, UserEntity>(
        ServerFailure(message: e.toString()),
      );
    }
  }
}
