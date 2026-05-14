// lib/features/friend/domain/usecases/send_dm_message_usecase.dart
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../entities/dm_message_entity.dart';
import '../repositories/dm_repository.dart';

class SendDmMessageParams extends Equatable {
  final String chatId;
  final String content;
  final String? replyToMessageId;
  const SendDmMessageParams({
    required this.chatId,
    required this.content,
    this.replyToMessageId,
  });
  @override
  List<Object?> get props => [chatId, content, replyToMessageId];
}

class SendDmMessageUseCase
    implements UseCase<DmMessageEntity, SendDmMessageParams> {
  final DmRepository _repository;
  SendDmMessageUseCase(this._repository);

  @override
  Future<Either<Failure, DmMessageEntity>> call(SendDmMessageParams params) {
    if (params.content.trim().isEmpty) {
      return Future.value(
        Either.left(
          const ServerFailure(message: 'Nội dung tin nhắn không được để trống'),
        ),
      );
    }
    return _repository.sendDmMessage(
      chatId: params.chatId,
      content: params.content.trim(),
      replyToMessageId: params.replyToMessageId,
    );
  }
}
