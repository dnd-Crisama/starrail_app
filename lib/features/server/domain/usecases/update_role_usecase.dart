import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/role_entity.dart';
import '../repositories/role_repository.dart';

class UpdateRoleParams {
  final String serverId;
  final String roleId;
  final String? name;
  final int? color;
  final List<String>? permissions;
  final int? hierarchyLevel;

  const UpdateRoleParams({
    required this.serverId,
    required this.roleId,
    this.name,
    this.color,
    this.permissions,
    this.hierarchyLevel,
  });
}

class UpdateRoleUseCase implements UseCase<RoleEntity, UpdateRoleParams> {
  final RoleRepository repository;
  UpdateRoleUseCase(this.repository);

  @override
  Future<Either<Failure, RoleEntity>> call(UpdateRoleParams params) async {
    try {
      final role = await repository.updateRole(
        serverId: params.serverId,
        roleId: params.roleId,
        name: params.name,
        color: params.color,
        permissions: params.permissions,
        hierarchyLevel: params.hierarchyLevel,
      );
      return Either.right<Failure, RoleEntity>(role);
    } on Failure catch (failure) {
      return Either.left<Failure, RoleEntity>(failure);
    } catch (e) {
      return Either.left<Failure, RoleEntity>(
        ServerFailure(message: e.toString()),
      );
    }
  }
}
