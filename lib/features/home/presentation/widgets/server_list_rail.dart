import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/logger.dart';
import '../../../message/presentation/providers/message_provider.dart';
import '../../../server/presentation/providers/server_provider.dart';
import '../providers/home_provider.dart';

class ServerListRail extends ConsumerWidget {
  final VoidCallback onAddServer;

  const ServerListRail({
    super.key,
    required this.onAddServer,
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
          _ServerIconButton(
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
                      child: _ServerIconButton(
                        isSelected: isSelected,
                        hasIndicator: ref.watch(
                          serverHasUnreadProvider(server.serverId),
                        ),
                        child: server.iconUrl.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  server.iconUrl,
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _ServerInitial(name: server.name),
                                ),
                              )
                            : _ServerInitial(name: server.name),
                        onTap: () {
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
            child: _ServerIconButton(
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

class _ServerIconButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isSelected;
  final bool hasIndicator;

  const _ServerIconButton({
    required this.child,
    required this.onTap,
    this.isSelected = false,
    this.hasIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brand : AppColors.bgPrimary,
                borderRadius: BorderRadius.circular(isSelected ? 16 : 24),
              ),
              alignment: Alignment.center,
              child: child,
            ),
          ),
          if (hasIndicator) ...[
            const SizedBox(height: 4),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ServerInitial extends StatelessWidget {
  final String name;

  const _ServerInitial({required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: AppTextStyles.headerSecondary.copyWith(
        fontSize: 18,
        color: AppColors.white,
      ),
    );
  }
}
