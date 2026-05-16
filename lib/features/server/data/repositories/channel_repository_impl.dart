import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/channel_entity.dart';
import '../../domain/repositories/channel_repository.dart';
import '../datasources/channel_remote_datasource.dart';

class ChannelRepositoryImpl implements ChannelRepository {
  final ChannelRemoteDatasource channelRemoteDatasource;
  final String currentUserId;

  ChannelRepositoryImpl({
    required this.channelRemoteDatasource,
    required this.currentUserId,
  });

  @override
  Future<ChannelEntity> createChannel({
    required String serverId,
    required String name,
    required ChannelType type,
    String? categoryId,
    int? position,
    String? topic,
    List<String>? allowedViewRoleIds,
    List<String>? allowedSendRoleIds,
  }) async {
    try {
      final channelModel = await channelRemoteDatasource.createChannel(
        serverId: serverId,
        name: name,
        type: type,
        categoryId: categoryId,
        position: position,
        topic: topic,
        allowedViewRoleIds: allowedViewRoleIds,
        allowedSendRoleIds: allowedSendRoleIds,
      );
      return channelModel.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<ChannelEntity> updateChannel({
    required String serverId,
    required String channelId,
    String? name,
    ChannelType? type,
    String? topic,
    int? position,
    List<String>? allowedViewRoleIds,
    List<String>? allowedSendRoleIds,
  }) async {
    try {
      final channelModel = await channelRemoteDatasource.updateChannel(
        serverId: serverId,
        channelId: channelId,
        name: name,
        type: type,
        topic: topic,
        position: position,
        allowedViewRoleIds: allowedViewRoleIds,
        allowedSendRoleIds: allowedSendRoleIds,
      );
      return channelModel.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> deleteChannel({
    required String serverId,
    required String channelId,
  }) async {
    try {
      await channelRemoteDatasource.deleteChannel(
        serverId: serverId,
        channelId: channelId,
      );
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Stream<List<ChannelEntity>> getServerChannelsStream({
    required String serverId,
  }) {
    return channelRemoteDatasource
        .getServerChannelsStream(serverId: serverId)
        .map((models) => models.map((model) => model.toEntity()).toList());
  }

  @override
  Future<ChannelEntity> getChannel({
    required String serverId,
    required String channelId,
  }) async {
    try {
      final channelModel = await channelRemoteDatasource.getChannel(
        serverId: serverId,
        channelId: channelId,
      );
      return channelModel.toEntity();
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message);
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }
}
