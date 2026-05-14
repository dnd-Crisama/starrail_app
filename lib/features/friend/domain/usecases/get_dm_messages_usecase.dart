// lib/features/friend/domain/usecases/get_dm_messages_usecase.dart
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/dm_message_entity.dart';
import '../repositories/dm_repository.dart';

class GetDmMessagesParams extends Equatable {
  final String chatId;
  const GetDmMessagesParams({required this.chatId});
  @override
  List<Object?> get props => [chatId];
}

class GetDmMessagesUseCase {
  final DmRepository _repository;
  GetDmMessagesUseCase(this._repository);

  Stream<Either<Failure, List<DmMessageEntity>>> call(
    GetDmMessagesParams params,
  ) {
    return _repository.watchDmMessages(params.chatId);
  }
}
