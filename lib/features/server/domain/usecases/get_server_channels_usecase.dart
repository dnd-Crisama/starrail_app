import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/channel_entity.dart';
import '../repositories/channel_repository.dart';

class GetServerChannelsUseCase
    implements UseCase<Stream<List<ChannelEntity>>, GetServerChannelsParams> {
  final ChannelRepository repository;

  GetServerChannelsUseCase(this.repository);

  @override
  Future<Either<Failure, Stream<List<ChannelEntity>>>> call(
    GetServerChannelsParams params,
  ) async {
    try {
      final stream = repository.getServerChannelsStream(
        serverId: params.serverId,
      );
      return Either.right<Failure, Stream<List<ChannelEntity>>>(stream);
    } on Failure catch (failure) {
      return Either.left<Failure, Stream<List<ChannelEntity>>>(failure);
    } catch (e) {
      return Either.left<Failure, Stream<List<ChannelEntity>>>(
        ServerFailure(message: e.toString()),
      );
    }
  }
}

class GetServerChannelsParams {
  final String serverId;

  const GetServerChannelsParams({required this.serverId});
}
