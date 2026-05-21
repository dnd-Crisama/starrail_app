import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../message/presentation/providers/message_provider.dart';
import '../../../server/domain/entities/server_entity.dart';
import '../../../server/presentation/providers/server_provider.dart';
import '../providers/home_provider.dart';
import 'server_icon_button.dart';

class ServerListRail extends ConsumerWidget {
  final VoidCallback onAddServer;
  final Future<void> Function(ServerEntity server)? onServerSelected;

  const ServerListRail({
    super.key,
    required this.onAddServer,
    this.onServerSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverListState = ref.watch(userServersStreamProvider);
    final selectedServerId = ref.watch(selectedServerIdProvider);

    return Container(
      width: AppConstants.serverListWidth,
      color: AppColors.bgTertiary,
      child: Column(
        children: [
          const SizedBox(height: 12),
          ServerIconButton(
            isSelected: selectedServerId == null,
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: AppColors.white,
              size: 28,
            ),
            onTap: () {
              ref.read(selectedServerIdProvider.notifier).state = null;
              ref.read(selectedServerNameProvider.notifier).state =
                  'Direct Messages';
              ref.read(selectedChannelIdProvider.notifier).state = null;
            },
          ),
          const SizedBox(height: 8),
          Container(
            width: 32,
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: serverListState.when(
              data: (servers) {
                if (servers.isEmpty) return const SizedBox.shrink();

                return ListView.builder(
                  itemCount: servers.length,
                  itemBuilder: (context, index) {
                    final server = servers[index];
                    final isSelected = selectedServerId == server.serverId;

                    return Tooltip(
                      message: server.name,
                      child: ServerIconButton(
                        isSelected: isSelected,
                        indicatorStyle: ServerIconIndicatorStyle.bottomDot,
                        hasUnread: ref.watch(
                          serverHasUnreadProvider(server.serverId),
                        ),
                        child: server.iconUrl.isNotEmpty
                            ? Image.network(
                                server.iconUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    ServerIconInitial(name: server.name),
                              )
                            : ServerIconInitial(name: server.name),
                        onTap: () {
                          final selectServer = onServerSelected;
                          if (selectServer != null) {
                            selectServer(server);
                            return;
                          }
                          ref.read(selectedServerIdProvider.notifier).state =
                              server.serverId;
                          ref.read(selectedServerNameProvider.notifier).state =
                              server.name;
                          ref
                              .read(unreadStatusNotifierProvider.notifier)
                              .loadReadStatusForServer(server.serverId);
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.brand),
              ),
              error: (err, stack) {
                Logger.error(
                  'Firebase load servers error: $err',
                  tag: 'ServerListRail',
                );
                return Tooltip(
                  message: err.toString(),
                  child: const Icon(Icons.error_outline, color: AppColors.red),
                );
              },
            ),
          ),
          Tooltip(
            message: 'Thêm server',
            child: ServerIconButton(
              child: const Icon(Icons.add, color: AppColors.green, size: 20),
              onTap: onAddServer,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
