// lib/features/friend/domain/usecases/update_group_dm_usecase.dart
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/dm_repository.dart';

class UpdateGroupDmParams extends Equatable {
  final String chatId;
  final String name;
  final String? iconUrl;
  final List<String>? participantIds;

  const UpdateGroupDmParams({
    required this.chatId,
    required this.name,
    this.iconUrl,
    this.participantIds,
  });

  @override
  List<Object?> get props => [chatId, name, iconUrl, participantIds];
}

class UpdateGroupDmUseCase implements UseCase<void, UpdateGroupDmParams> {
  final DmRepository _repository;

  UpdateGroupDmUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(UpdateGroupDmParams params) {
    return _repository.updateGroupDm(
      chatId: params.chatId,
      name: params.name,
      iconUrl: params.iconUrl,
      participantIds: params.participantIds,
    );
  }
}
