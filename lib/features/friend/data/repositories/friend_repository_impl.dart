// lib/features/friend/data/repositories/friend_repository_impl.dart
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/friendship_entity.dart';
import '../../domain/repositories/friend_repository.dart';
import '../datasources/friend_remote_datasource.dart';

class FriendRepositoryImpl implements FriendRepository {
  final FriendRemoteDatasource _datasource;

  FriendRepositoryImpl({required FriendRemoteDatasource datasource})
    : _datasource = datasource;

  @override
  Future<Either<Failure, List<UserEntity>>> searchUsersByUsername(
    String query,
  ) async {
    try {
      final models = await _datasource.searchUsersByUsername(query);
      return Either.right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Either.left(ServerFailure(message: e.message));
    } catch (e) {
      return Either.left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, FriendshipEntity>> sendFriendRequest(
    String targetUserId,
  ) async {
    try {
      final model = await _datasource.sendFriendRequest(targetUserId);
      return Either.right(model.toEntity());
    } on ServerException catch (e) {
      return Either.left(ServerFailure(message: e.message));
    } catch (e) {
      return Either.left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, FriendshipEntity>> acceptFriendRequest(
    String friendshipId,
  ) async {
    try {
      final model = await _datasource.acceptFriendRequest(friendshipId);
      return Either.right(model.toEntity());
    } on ServerException catch (e) {
      return Either.left(ServerFailure(message: e.message));
    } catch (e) {
      return Either.left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> declineFriendRequest(
    String friendshipId,
  ) async {
    try {
      await _datasource.declineFriendRequest(friendshipId);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(message: e.message));
    } catch (e) {
      return Either.left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelFriendRequest(
    String friendshipId,
  ) async {
    try {
      await _datasource.cancelFriendRequest(friendshipId);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(message: e.message));
    } catch (e) {
      return Either.left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeFriend(String friendshipId) async {
    try {
      await _datasource.removeFriend(friendshipId);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(message: e.message));
    } catch (e) {
      return Either.left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> blockUser(String targetUserId) async {
    try {
      await _datasource.blockUser(targetUserId);
      return Either.right(null);
    } on ServerException catch (e) {
      return Either.left(ServerFailure(message: e.message));
    } catch (e) {
      return Either.left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<FriendshipEntity>>> watchFriends(
    String userId,
  ) {
    return _datasource.watchFriends(userId).map(
      (models) => Either.right<Failure, List<FriendshipEntity>>(
        models.map((m) => m.toEntity()).toList(),
      ),
    ).handleError(
      (e) => Either.left<Failure, List<FriendshipEntity>>(
        ServerFailure(message: e.toString()),
      ),
    );
  }

  @override
  Stream<Either<Failure, List<FriendshipEntity>>> watchIncomingRequests(
    String userId,
  ) {
    return _datasource.watchIncomingRequests(userId).map(
      (models) => Either.right<Failure, List<FriendshipEntity>>(
        models.map((m) => m.toEntity()).toList(),
      ),
    ).handleError(
      (e) => Either.left<Failure, List<FriendshipEntity>>(
        ServerFailure(message: e.toString()),
      ),
    );
  }

  @override
  Stream<Either<Failure, List<FriendshipEntity>>> watchOutgoingRequests(
    String userId,
  ) {
    return _datasource.watchOutgoingRequests(userId).map(
      (models) => Either.right<Failure, List<FriendshipEntity>>(
        models.map((m) => m.toEntity()).toList(),
      ),
    ).handleError(
      (e) => Either.left<Failure, List<FriendshipEntity>>(
        ServerFailure(message: e.toString()),
      ),
    );
  }

  @override
  Future<Either<Failure, FriendshipEntity?>> getFriendship(
    String currentUserId,
    String targetUserId,
  ) async {
    try {
      final model = await _datasource.getFriendship(currentUserId, targetUserId);
      return Either.right(model?.toEntity());
    } on ServerException catch (e) {
      return Either.left(ServerFailure(message: e.message));
    } catch (e) {
      return Either.left(UnknownFailure(message: e.toString()));
    }
  }
}
