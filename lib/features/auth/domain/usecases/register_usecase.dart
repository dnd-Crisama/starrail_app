import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterParams {
  final String email;
  final String password;
  final String username;
  const RegisterParams({
    required this.email,
    required this.password,
    required this.username,
  });
}

class RegisterUseCase implements UseCase<UserEntity, RegisterParams> {
  final AuthRepository repository;
  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(RegisterParams params) async {
    try {
      final user = await repository.register(
        email: params.email,
        password: params.password,
        username: params.username,
      );
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
