import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message_entity.dart';
import '../repositories/message_repository.dart';

class GetMessagesBeforeParams {
  final String serverId;
  final String channelId;
  final DateTime lastMessageCreatedAt;
  final int limit;

  const GetMessagesBeforeParams({
    required this.serverId,
    required this.channelId,
    required this.lastMessageCreatedAt,
    this.limit = 50,
  });
}

class GetMessagesBeforeUseCase
    implements UseCase<List<MessageEntity>, GetMessagesBeforeParams> {
  final MessageRepository repository;
  GetMessagesBeforeUseCase(this.repository);

  @override
  Future<Either<Failure, List<MessageEntity>>> call(
    GetMessagesBeforeParams params,
  ) async {
    try {
      return await repository.getMessagesBefore(
        serverId: params.serverId,
        channelId: params.channelId,
        lastMessageCreatedAt: params.lastMessageCreatedAt,
        limit: params.limit,
      );
    } on Failure catch (failure) {
      return Either.left<Failure, List<MessageEntity>>(failure);
    } catch (e) {
      return Either.left<Failure, List<MessageEntity>>(
        ServerFailure(message: e.toString()),
      );
    }
  }
}
