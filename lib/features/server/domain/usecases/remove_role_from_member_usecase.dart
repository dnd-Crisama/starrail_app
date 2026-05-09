import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/role_repository.dart';

class RemoveRoleParams {
  final String serverId;
  final String userId;
  final String roleId;

  const RemoveRoleParams({
    required this.serverId,
    required this.userId,
    required this.roleId,
  });
}

class RemoveRoleFromMemberUseCase implements UseCase<void, RemoveRoleParams> {
  final RoleRepository repository;
  RemoveRoleFromMemberUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(RemoveRoleParams params) async {
    try {
      await repository.removeRoleFromMember(
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
