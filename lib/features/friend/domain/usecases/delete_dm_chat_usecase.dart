// lib/features/friend/domain/usecases/delete_dm_chat_usecase.dart
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/dm_repository.dart';

class DeleteDmChatParams extends Equatable {
  final String chatId;

  const DeleteDmChatParams({required this.chatId});

  @override
  List<Object?> get props => [chatId];
}

class DeleteDmChatUseCase implements UseCase<void, DeleteDmChatParams> {
  final DmRepository _repository;

  DeleteDmChatUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(DeleteDmChatParams params) {
    return _repository.deleteDmChat(params.chatId);
  }
}
