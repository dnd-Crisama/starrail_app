import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../server/domain/entities/permission.dart';
import '../../../server/presentation/providers/channel_provider.dart';
import '../../../server/domain/entities/channel_entity.dart';
import '../../../server/presentation/providers/role_provider.dart';
import '../../../server/presentation/providers/server_provider.dart';

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

/// ID của DM chat đang được chọn trong chế độ Direct Messages.
/// Null nghĩa là chưa chọn cuộc trò chuyện nào.
final selectedDmChatIdProvider = StateProvider<String?>((ref) => null);

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

final visibleServerChannelsProvider =
    FutureProvider.family<List<ChannelEntity>, String>((ref, serverId) async {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null || userId.isEmpty) return const <ChannelEntity>[];

      final channels = await ref.watch(
        serverChannelsStreamProvider(serverId).future,
      );
      final isOwner = ref.watch(isServerOwnerProvider(serverId));
      final isSuperAdminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final isSuperAdmin =
          isSuperAdminDoc.data()?['isSuperAdmin'] as bool? ?? false;
      final serverDoc = await FirebaseFirestore.instance
          .collection('servers')
          .doc(serverId)
          .get();
      final isSuspended = serverDoc.data()?['isSuspended'] as bool? ?? false;
      if (isSuspended && !isSuperAdmin) return const <ChannelEntity>[];
      if (isSuperAdmin) return channels;
      if (isOwner) return channels;

      final canViewServer = await ref.watch(
        hasPermissionProvider((
          serverId: serverId,
          userId: userId,
          permission: Permission.viewChannel,
        )).future,
      );
      if (!canViewServer) return const <ChannelEntity>[];

      final canManageChannels = await ref.watch(
        hasPermissionProvider((
          serverId: serverId,
          userId: userId,
          permission: Permission.manageChannel,
        )).future,
      );
      if (canManageChannels) return channels;

      final restrictedChannels = channels.where(
        (channel) => channel.allowedViewRoleIds.isNotEmpty,
      );
      if (restrictedChannels.isEmpty) return channels;

      final roleIds = await _currentMemberRoleIds(serverId, userId);
      return channels.where((channel) {
        if (channel.allowedViewRoleIds.isEmpty) return true;
        return roleIds.any(channel.allowedViewRoleIds.contains);
      }).toList();
    });

Future<List<String>> _currentMemberRoleIds(
  String serverId,
  String userId,
) async {
  final firestore = FirebaseFirestore.instance;
  final memberDoc = await firestore
      .collection('servers')
      .doc(serverId)
      .collection('members')
      .doc(userId)
      .get();
  final roleIds = <String>{
    ...List<String>.from(memberDoc.data()?['roleIds'] as List? ?? const []),
  };

  final defaultRole = await firestore
      .collection('servers')
      .doc(serverId)
      .collection('roles')
      .where('isDefault', isEqualTo: true)
      .limit(1)
      .get();
  if (defaultRole.docs.isNotEmpty) {
    roleIds.add(defaultRole.docs.first.id);
  }

  return roleIds.toList();
}
