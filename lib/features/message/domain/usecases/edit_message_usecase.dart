import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message_entity.dart';
import '../repositories/message_repository.dart';

class EditMessageParams {
  final String serverId;
  final String channelId;
  final String messageId;
  final String newContent;

  const EditMessageParams({
    required this.serverId,
    required this.channelId,
    required this.messageId,
    required this.newContent,
  });
}

class EditMessageUseCase implements UseCase<MessageEntity, EditMessageParams> {
  final MessageRepository repository;
  EditMessageUseCase(this.repository);

  @override
  Future<Either<Failure, MessageEntity>> call(EditMessageParams params) async {
    try {
      return await repository.editMessage(
        serverId: params.serverId,
        channelId: params.channelId,
        messageId: params.messageId,
        newContent: params.newContent,
      );
    } on Failure catch (failure) {
      return Either.left<Failure, MessageEntity>(failure);
    } catch (e) {
      return Either.left<Failure, MessageEntity>(
        ServerFailure(message: e.toString()),
      );
    }
  }
}
