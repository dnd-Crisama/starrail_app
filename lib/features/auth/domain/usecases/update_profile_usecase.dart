import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class UpdateProfileParams {
  final String? username;
  final String? bio;
  final String? avatarUrl;
  const UpdateProfileParams({this.username, this.bio, this.avatarUrl});
}

class UpdateProfileUseCase implements UseCase<UserEntity, UpdateProfileParams> {
  final UserRepository repository;
  UpdateProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(UpdateProfileParams params) async {
    try {
      final user = await repository.updateProfile(
        username: params.username,
        bio: params.bio,
        avatarUrl: params.avatarUrl,
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
