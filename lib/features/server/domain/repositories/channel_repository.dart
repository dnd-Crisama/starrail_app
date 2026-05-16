import '../entities/channel_entity.dart';

abstract class ChannelRepository {
  /// Tạo kênh mới trong server
  Future<ChannelEntity> createChannel({
    required String serverId,
    required String name,
    required ChannelType type,
    String? categoryId,
    int? position,
    String? topic,
    List<String>? allowedViewRoleIds,
    List<String>? allowedSendRoleIds,
  });

  /// Cập nhật kênh
  Future<ChannelEntity> updateChannel({
    required String serverId,
    required String channelId,
    String? name,
    ChannelType? type,
    String? topic,
    int? position,
    List<String>? allowedViewRoleIds,
    List<String>? allowedSendRoleIds,
  });

  /// Xóa kênh
  Future<void> deleteChannel({
    required String serverId,
    required String channelId,
  });

  /// Lắng nghe danh sách kênh của server theo thời gian thực
  Stream<List<ChannelEntity>> getServerChannelsStream({
    required String serverId,
  });

  /// Lấy thông tin một kênh
  Future<ChannelEntity> getChannel({
    required String serverId,
    required String channelId,
  });
}
