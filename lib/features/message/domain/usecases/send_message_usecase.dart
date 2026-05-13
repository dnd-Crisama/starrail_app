import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message_entity.dart';
import '../repositories/message_repository.dart';

class SendMessageParams {
  final String serverId;
  final String channelId;
  final String senderId;
  final String content;
  final MessageType type;
  final List<String> mentionTargetIds;
  final String? replyToMessageId;
  final List<AttachmentEntity> attachments;

  const SendMessageParams({
    required this.serverId,
    required this.channelId,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
    this.mentionTargetIds = const [],
    this.replyToMessageId,
    this.attachments = const [],
  });
}

class SendMessageUseCase implements UseCase<MessageEntity, SendMessageParams> {
  final MessageRepository repository;
  SendMessageUseCase(this.repository);

  @override
  Future<Either<Failure, MessageEntity>> call(SendMessageParams params) async {
    try {
      return await repository.sendMessage(
        serverId: params.serverId,
        channelId: params.channelId,
        senderId: params.senderId,
        content: params.content,
        type: params.type,
        mentionTargetIds: params.mentionTargetIds,
        replyToMessageId: params.replyToMessageId,
        attachments: params.attachments,
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
