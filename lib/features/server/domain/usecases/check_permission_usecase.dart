import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/permission.dart';
import '../repositories/role_repository.dart';

class CheckPermissionParams {
  final String serverId;
  final String userId;
  final Permission permission;

  const CheckPermissionParams({
    required this.serverId,
    required this.userId,
    required this.permission,
  });
}

class CheckPermissionUseCase implements UseCase<bool, CheckPermissionParams> {
  final RoleRepository repository;
  CheckPermissionUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(CheckPermissionParams params) async {
    try {
      final hasPermission = await repository.hasPermission(
        serverId: params.serverId,
        userId: params.userId,
        permission: params.permission.value,
      );
      return Either.right<Failure, bool>(hasPermission);
    } on Failure catch (failure) {
      return Either.left<Failure, bool>(failure);
    } catch (e) {
      return Either.left<Failure, bool>(ServerFailure(message: e.toString()));
    }
  }
}
