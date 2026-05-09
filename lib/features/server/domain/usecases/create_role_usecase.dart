import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/role_entity.dart';
import '../repositories/role_repository.dart';

class CreateRoleParams {
  final String serverId;
  final String name;
  final int color;
  final List<String> permissions;
  final int hierarchyLevel;

  const CreateRoleParams({
    required this.serverId,
    required this.name,
    this.color = 0xFF99AAB5,
    this.permissions = const [],
    this.hierarchyLevel = 1,
  });
}

class CreateRoleUseCase implements UseCase<RoleEntity, CreateRoleParams> {
  final RoleRepository repository;
  CreateRoleUseCase(this.repository);

  @override
  Future<Either<Failure, RoleEntity>> call(CreateRoleParams params) async {
    try {
      final role = await repository.createRole(
        serverId: params.serverId,
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
