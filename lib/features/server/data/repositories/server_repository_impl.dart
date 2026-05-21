// lib/features/server/data/repositories/server_repository_impl.dart
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/server_entity.dart';
import '../../domain/repositories/server_repository.dart';
import '../datasources/server_remote_datasource.dart';
import '../../domain/entities/server_member_entity.dart';

class ServerRepositoryImpl implements ServerRepository {
  final ServerRemoteDatasource serverRemoteDatasource;
  final String currentUserId;

  ServerRepositoryImpl({
    required this.serverRemoteDatasource,
    required this.currentUserId,
  });

  @override
  Future<ServerEntity> createServer({
    required String name,
    String? iconUrl,
  }) async {
    try {
      final model = await serverRemoteDatasource.createServer(
        name: name,
        iconUrl: iconUrl,
      );
      return model.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<ServerEntity> joinServer({required String inviteCode}) async {
    try {
      final model = await serverRemoteDatasource.joinServer(
        inviteCode: inviteCode,
      );
      return model.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> leaveServer({required String serverId}) async {
    try {
      await serverRemoteDatasource.leaveServer(
        serverId: serverId,
        userId: currentUserId,
      );
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> deleteServer({required String serverId}) async {
    try {
      await serverRemoteDatasource.deleteServer(
        serverId: serverId,
        userId: currentUserId,
      );
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Stream<List<ServerEntity>> getUserServersStream() {
    return serverRemoteDatasource
        .getUserServersStream(userId: currentUserId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<ServerEntity> getServer({required String serverId}) async {
    try {
      final model = await serverRemoteDatasource.getServer(serverId: serverId);
      return model.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<bool> isServerMember({
    required String serverId,
    required String userId,
  }) async {
    try {
      return await serverRemoteDatasource.isServerMember(
        serverId: serverId,
        userId: userId,
      );
    } on ServerException {
      return false;
    }
  }

  @override
  Stream<List<ServerMemberEntity>> watchServerMembers({
    required String serverId,
  }) {
    return serverRemoteDatasource
        .watchServerMembers(serverId: serverId)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }
}
