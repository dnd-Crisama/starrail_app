// lib/features/server/domain/usecases/leave_server_usecase.dart
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/server_repository.dart';

class LeaveServerParams {
  final String serverId;
  const LeaveServerParams({required this.serverId});
}

class LeaveServerUseCase implements UseCase<void, LeaveServerParams> {
  final ServerRepository repository;
  LeaveServerUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(LeaveServerParams params) async {
    try {
      await repository.leaveServer(serverId: params.serverId);
      return Either.right<Failure, void>(null);
    } on Failure catch (failure) {
      return Either.left<Failure, void>(failure);
    } catch (e) {
      return Either.left<Failure, void>(ServerFailure(message: e.toString()));
    }
  }
}
