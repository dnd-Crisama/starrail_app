import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message_entity.dart';
import '../repositories/message_repository.dart';

class GetMessageByIdParams {
  final String serverId;
  final String channelId;
  final String messageId;

  const GetMessageByIdParams({
    required this.serverId,
    required this.channelId,
    required this.messageId,
  });
}

class GetMessageByIdUseCase
    implements UseCase<MessageEntity?, GetMessageByIdParams> {
  final MessageRepository repository;
  GetMessageByIdUseCase(this.repository);

  @override
  Future<Either<Failure, MessageEntity?>> call(
    GetMessageByIdParams params,
  ) async {
    try {
      return await repository.getMessageById(
        serverId: params.serverId,
        channelId: params.channelId,
        messageId: params.messageId,
      );
    } on Failure catch (failure) {
      return Either.left<Failure, MessageEntity?>(failure);
    } catch (e) {
      return Either.left<Failure, MessageEntity?>(
        ServerFailure(message: e.toString()),
      );
    }
  }
}
