import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message_entity.dart';
import '../repositories/message_repository.dart';

class DeleteMessageParams {
  final String serverId;
  final String channelId;
  final String messageId;

  const DeleteMessageParams({
    required this.serverId,
    required this.channelId,
    required this.messageId,
  });
}

class DeleteMessageUseCase implements UseCase<void, DeleteMessageParams> {
  final MessageRepository repository;
  DeleteMessageUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteMessageParams params) async {
    try {
      return await repository.deleteMessage(
        serverId: params.serverId,
        channelId: params.channelId,
        messageId: params.messageId,
      );
    } on Failure catch (failure) {
      return Either.left<Failure, void>(failure);
    } catch (e) {
      return Either.left<Failure, void>(ServerFailure(message: e.toString()));
    }
  }
}
