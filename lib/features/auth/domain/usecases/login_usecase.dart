import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginParams {
  final String email;
  final String password;
  const LoginParams({required this.email, required this.password});
}

class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  final AuthRepository repository;
  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) async {
    try {
      final user = await repository.login(
        email: params.email,
        password: params.password,
      );
      return Either.right<Failure, UserEntity>(user);
    } on Failure catch (failure) {
      // Bắt giữu nguyên kiểu Failure (CacheFailure, AuthFailure, v.v.)
      return Either.left<Failure, UserEntity>(failure);
    } catch (e) {
      return Either.left<Failure, UserEntity>(
        ServerFailure(message: e.toString()),
      );
    }
  }
}
