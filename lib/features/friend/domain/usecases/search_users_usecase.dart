// lib/features/friend/domain/usecases/search_users_usecase.dart
import 'package:equatable/equatable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../repositories/friend_repository.dart';

class SearchUsersParams extends Equatable {
  final String query;
  const SearchUsersParams({required this.query});
  @override
  List<Object?> get props => [query];
}

/// Tìm kiếm user theo username để gửi lời mời kết bạn.
class SearchUsersUseCase implements UseCase<List<UserEntity>, SearchUsersParams> {
  final FriendRepository _repository;
  SearchUsersUseCase(this._repository);

  @override
  Future<Either<Failure, List<UserEntity>>> call(SearchUsersParams params) {
    if (params.query.trim().isEmpty) {
      return Future.value(Either.right([]));
    }
    return _repository.searchUsersByUsername(params.query.trim());
  }
}
