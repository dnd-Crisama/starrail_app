import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/role_repository.dart';

class AssignRoleParams {
  final String serverId;
  final String userId;
  final String roleId;

  const AssignRoleParams({
    required this.serverId,
    required this.userId,
    required this.roleId,
  });
}

class AssignRoleToMemberUseCase implements UseCase<void, AssignRoleParams> {
  final RoleRepository repository;
  AssignRoleToMemberUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AssignRoleParams params) async {
    try {
      await repository.assignRoleToMember(
        serverId: params.serverId,
        userId: params.userId,
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
