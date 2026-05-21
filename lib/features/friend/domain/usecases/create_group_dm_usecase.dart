// lib/features/friend/domain/usecases/create_group_dm_usecase.dart
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../entities/dm_chat_entity.dart';
import '../repositories/dm_repository.dart';

class CreateGroupDmParams extends Equatable {
  final List<String> participantIds;
  final String name;
  final String? iconUrl;
  const CreateGroupDmParams({
    required this.participantIds,
    required this.name,
    this.iconUrl,
  });
  @override
  List<Object?> get props => [participantIds, name, iconUrl];
}

class CreateGroupDmUseCase
    implements UseCase<DmChatEntity, CreateGroupDmParams> {
  final DmRepository _repository;
  CreateGroupDmUseCase(this._repository);

  @override
  Future<Either<Failure, DmChatEntity>> call(CreateGroupDmParams params) {
    if (params.participantIds.length < 2) {
      return Future.value(
        Either.left(
          const ServerFailure(
            message: 'Group DM cần ít nhất 2 thành viên khác',
          ),
        ),
      );
    }
    return _repository.createGroupDm(
      participantIds: params.participantIds,
      name: params.name.trim(),
      iconUrl: params.iconUrl,
    );
  }
}
