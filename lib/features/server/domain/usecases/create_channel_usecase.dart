import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/channel_entity.dart';
import '../repositories/channel_repository.dart';

class CreateChannelUseCase
    implements UseCase<ChannelEntity, CreateChannelParams> {
  final ChannelRepository repository;

  CreateChannelUseCase(this.repository);

  @override
  Future<Either<Failure, ChannelEntity>> call(
    CreateChannelParams params,
  ) async {
    try {
      final channel = await repository.createChannel(
        serverId: params.serverId,
        name: params.name,
        type: params.type,
        categoryId: params.categoryId,
        position: params.position,
        topic: params.topic,
        allowedViewRoleIds: params.allowedViewRoleIds,
        allowedSendRoleIds: params.allowedSendRoleIds,
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

class CreateChannelParams {
  final String serverId;
  final String name;
  final ChannelType type;
  final String? categoryId;
  final int? position;
  final String? topic;
  final List<String>? allowedViewRoleIds;
  final List<String>? allowedSendRoleIds;

  const CreateChannelParams({
    required this.serverId,
    required this.name,
    required this.type,
    this.categoryId,
    this.position,
    this.topic,
    this.allowedViewRoleIds,
    this.allowedSendRoleIds,
  });
}
