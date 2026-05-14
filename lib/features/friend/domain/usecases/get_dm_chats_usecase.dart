// lib/features/friend/domain/usecases/get_dm_chats_usecase.dart
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/dm_chat_entity.dart';
import '../repositories/dm_repository.dart';

class GetDmChatsParams extends Equatable {
  final String userId;
  const GetDmChatsParams({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class GetDmChatsUseCase {
  final DmRepository _repository;
  GetDmChatsUseCase(this._repository);

  Stream<Either<Failure, List<DmChatEntity>>> call(GetDmChatsParams params) {
    return _repository.watchDmChats(params.userId);
  }
}
