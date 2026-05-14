// lib/features/friend/domain/usecases/get_or_create_dm_chat_usecase.dart
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/dm_repository.dart';

class GetOrCreateDmChatParams extends Equatable {
  final String otherUserId;
  const GetOrCreateDmChatParams({required this.otherUserId});
  @override
  List<Object?> get props => [otherUserId];
}

/// Lấy chatId nếu đã có DM với [otherUserId], hoặc tạo mới nếu chưa có.
class GetOrCreateDmChatUseCase
    implements UseCase<String, GetOrCreateDmChatParams> {
  final DmRepository _repository;
  GetOrCreateDmChatUseCase(this._repository);

  @override
  Future<Either<Failure, String>> call(GetOrCreateDmChatParams params) {
    return _repository.getOrCreateDmChat(params.otherUserId);
  }
}
