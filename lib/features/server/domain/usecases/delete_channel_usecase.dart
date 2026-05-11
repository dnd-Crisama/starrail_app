import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/channel_repository.dart';

class DeleteChannelUseCase implements UseCase<void, DeleteChannelParams> {
  final ChannelRepository repository;

  DeleteChannelUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteChannelParams params) async {
    try {
      await repository.deleteChannel(
        serverId: params.serverId,
        channelId: params.channelId,
      );
      return Either.right<Failure, void>(null);
    } on Failure catch (failure) {
      return Either.left<Failure, void>(failure);
    } catch (e) {
      return Either.left<Failure, void>(ServerFailure(message: e.toString()));
    }
  }
}

class DeleteChannelParams {
  final String serverId;
  final String channelId;

  const DeleteChannelParams({required this.serverId, required this.channelId});
}
