import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/channel_entity.dart';
import '../repositories/channel_repository.dart';

class UpdateChannelUseCase
    implements UseCase<ChannelEntity, UpdateChannelParams> {
  final ChannelRepository repository;

  UpdateChannelUseCase(this.repository);

  @override
  Future<Either<Failure, ChannelEntity>> call(
    UpdateChannelParams params,
  ) async {
    try {
      final channel = await repository.updateChannel(
        serverId: params.serverId,
        channelId: params.channelId,
        name: params.name,
        type: params.type,
        topic: params.topic,
        position: params.position,
      );
      return Either.right<Failure, ChannelEntity>(channel);
    } on Failure catch (failure) {
      return Either.left<Failure, ChannelEntity>(failure);
    } catch (e) {
      return Either.left<Failure, ChannelEntity>(
        ServerFailure(message: e.toString()),
      );
    }
  }
}

class UpdateChannelParams {
  final String serverId;
  final String channelId;
  final String? name;
  final ChannelType? type;
  final String? topic;
  final int? position;

  const UpdateChannelParams({
    required this.serverId,
    required this.channelId,
    this.name,
    this.type,
    this.topic,
    this.position,
  });
}
