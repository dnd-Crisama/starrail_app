import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../server/presentation/providers/channel_provider.dart';
import '../../../server/domain/entities/channel_entity.dart';

/// ID của server đang được chọn trong server list.
/// Null nghĩa là chưa chọn server nào (hiển thị Home/Direct Messages).
final selectedServerIdProvider = StateProvider<String?>((ref) => null);

/// ID của channel đang được chọn.
/// Null nghĩa là chưa chọn channel nào.
final selectedChannelIdProvider = StateProvider<String?>((ref) => null);

/// Tên của server đang chọn (hiển thị trong channel sidebar header).
final selectedServerNameProvider = StateProvider<String>(
  (ref) => 'StarRail Server',
);

/// Cờ điều khiển sidebar channel có bị collapse trên mobile không.
final isChannelSidebarOpenProvider = StateProvider<bool>((ref) => true);

/// Provider lấy thông tin kênh đang chọn (tên, loại, chủ đề)
final selectedChannelInfoProvider = Provider<ChannelEntity?>((ref) {
  final serverId = ref.watch(selectedServerIdProvider);
  final channelId = ref.watch(selectedChannelIdProvider);

  if (serverId == null || channelId == null) return null;

  final channelsState = ref.watch(serverChannelsStreamProvider(serverId));
  return channelsState.when(
    data: (channels) =>
        channels.where((c) => c.channelId == channelId).firstOrNull,
    loading: () => null,
    error: (_, __) => null,
  );
});
