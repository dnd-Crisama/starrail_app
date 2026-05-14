// lib/features/friend/domain/usecases/delete_dm_message_usecase.dart
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/dm_repository.dart';

class DeleteDmMessageParams extends Equatable {
  final String chatId;
  final String messageId;
  const DeleteDmMessageParams({required this.chatId, required this.messageId});
  @override
  List<Object?> get props => [chatId, messageId];
}

class DeleteDmMessageUseCase implements UseCase<void, DeleteDmMessageParams> {
  final DmRepository _repository;
  DeleteDmMessageUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(DeleteDmMessageParams params) {
    return _repository.deleteDmMessage(
      chatId: params.chatId,
      messageId: params.messageId,
    );
  }
}
