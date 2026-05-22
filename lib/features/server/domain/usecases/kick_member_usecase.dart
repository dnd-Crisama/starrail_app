// lib/features/server/domain/usecases/kick_member_usecase.dart
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/server_repository.dart';

class KickMemberParams {
  final String serverId;
  final String targetUserId;

  const KickMemberParams({required this.serverId, required this.targetUserId});
}

class KickMemberUseCase implements UseCase<void, KickMemberParams> {
  final ServerRepository repository;

  KickMemberUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(KickMemberParams params) async {
    try {
      await repository.kickMember(
        serverId: params.serverId,
        targetUserId: params.targetUserId,
      );
      return Either.right<Failure, void>(null);
    } on Failure catch (failure) {
      return Either.left<Failure, void>(failure);
    } catch (e) {
      return Either.left<Failure, void>(ServerFailure(message: e.toString()));
    }
  }
}
