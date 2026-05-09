import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/role_repository.dart';

class DeleteRoleParams {
  final String serverId;
  final String roleId;

  const DeleteRoleParams({required this.serverId, required this.roleId});
}

class DeleteRoleUseCase implements UseCase<void, DeleteRoleParams> {
  final RoleRepository repository;
  DeleteRoleUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteRoleParams params) async {
    try {
      await repository.deleteRole(
        serverId: params.serverId,
        roleId: params.roleId,
      );
      return Either.right<Failure, void>(null);
    } on Failure catch (failure) {
      return Either.left<Failure, void>(failure);
    } catch (e) {
      return Either.left<Failure, void>(ServerFailure(message: e.toString()));
    }
  }
}
