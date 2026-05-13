import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/message_repository.dart';

class ToggleReactionParams {
  final String serverId;
  final String channelId;
  final String messageId;
  final String emoji;
  final String userId;

  const ToggleReactionParams({
    required this.serverId,
    required this.channelId,
    required this.messageId,
    required this.emoji,
    required this.userId,
  });
}

class ToggleReactionUseCase implements UseCase<void, ToggleReactionParams> {
  final MessageRepository repository;
  ToggleReactionUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ToggleReactionParams params) async {
    try {
      return await repository.toggleReaction(
        serverId: params.serverId,
        channelId: params.channelId,
        messageId: params.messageId,
        emoji: params.emoji,
        userId: params.userId,
      );
    } on Failure catch (failure) {
      return Either.left<Failure, void>(failure);
    } catch (e) {
      return Either.left<Failure, void>(ServerFailure(message: e.toString()));
    }
  }
}
