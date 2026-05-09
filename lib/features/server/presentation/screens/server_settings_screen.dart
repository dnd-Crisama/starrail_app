import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../providers/server_provider.dart';
import 'role_management_screen.dart';

class ServerSettingsScreen extends ConsumerWidget {
  const ServerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverId = ref.watch(selectedServerIdProvider);
    if (serverId == null) {
      return const Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: Text('Chưa chọn server', style: AppTextStyles.textMuted),
        ),
      );
    }

    final isOwner = ref.watch(isServerOwnerProvider(serverId));
    final settingsState = ref.watch(serverSettingsNotifierProvider);

    ref.listen<ServerSettingsState>(serverSettingsNotifierProvider, (
      prev,
      next,
    ) {
      if (next.actionCompleted && !(prev?.actionCompleted ?? false)) {
        Navigator.of(context).pop();
        ref.read(selectedServerIdProvider.notifier).state = null;
        ref.read(selectedServerNameProvider.notifier).state = 'StarRail Server';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thao tác thành công'),
            backgroundColor: AppColors.green,
          ),
        );
      }
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.red,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgTertiary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.interactiveNormal,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Cài đặt Server', style: AppTextStyles.headerPrimary),
      ),
      body: settingsState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brand),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildServerInfoSection(context, ref, serverId),
                  const SizedBox(height: 24),
                  _buildInviteCodeSection(context, ref, serverId),
                  const SizedBox(height: 24),
                  _buildNavigationSection(context, ref, serverId),
                  const SizedBox(height: 32),
                  _buildDangerZone(context, ref, serverId, isOwner),
                ],
              ),
            ),
    );
  }

  Widget _buildServerInfoSection(
    BuildContext context,
    WidgetRef ref,
    String serverId,
  ) {
    final serverName = ref.watch(selectedServerNameProvider);
    final serversAsync = ref.watch(userServersStreamProvider);
    final server = serversAsync.maybeWhen(
      data: (servers) =>
          servers.where((s) => s.serverId == serverId).firstOrNull,
      orElse: () => null,
    );

    final ownerId = server?.ownerId ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thông tin Server', style: AppTextStyles.header3),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      serverName.isNotEmpty ? serverName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serverName,
                          style: AppTextStyles.headerPrimary,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${serverId.substring(0, 8)}...',
                          style: AppTextStyles.textMutedSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (server != null) ...[
          const SizedBox(height: 12),
          _buildOwnerRow(ref, ownerId),
          _buildInfoRow(
            'Ngày tạo',
            '${server.createdAt.day}/${server.createdAt.month}/${server.createdAt.year}',
          ),
        ],
      ],
    );
  }

  Widget _buildOwnerRow(WidgetRef ref, String ownerId) {
    if (ownerId.isEmpty) {
      return _buildInfoRow('Chủ sở hữu', 'Không xác định');
    }

    final ownerAsync = ref.watch(ownerUserProfileProvider(ownerId));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text('Chủ sở hữu', style: AppTextStyles.textMuted),
          ),
          Expanded(
            child: ownerAsync.when(
              data: (owner) {
                if (owner == null) {
                  return Text(
                    ownerId.substring(0, 8) + '...',
                    style: AppTextStyles.bodySecondary,
                  );
                }
                return Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                        image: owner.avatarUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(owner.avatarUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: owner.avatarUrl.isEmpty
                          ? Text(
                              owner.username.isNotEmpty
                                  ? owner.username[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        owner.username.isNotEmpty
                            ? owner.username
                            : ownerId.substring(0, 8) + '...',
                        style: AppTextStyles.bodySecondary.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
              loading: () => Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.bgModifierHover,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        color: AppColors.brand,
                        strokeWidth: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Đang tải...', style: AppTextStyles.textMutedSmall),
                ],
              ),
              error: (_, __) => Text(
                ownerId.substring(0, 8) + '...',
                style: AppTextStyles.bodySecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTextStyles.textMuted),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodySecondary)),
        ],
      ),
    );
  }

  Widget _buildInviteCodeSection(
    BuildContext context,
    WidgetRef ref,
    String serverId,
  ) {
    final serversAsync = ref.watch(userServersStreamProvider);
    final inviteCode = serversAsync.maybeWhen(
      data: (servers) {
        final server = servers.where((s) => s.serverId == serverId).firstOrNull;
        return server?.inviteCode ?? '';
      },
      orElse: () => '',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mã lời mời', style: AppTextStyles.header3),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  inviteCode.isNotEmpty ? inviteCode : 'Đang tải...',
                  style: AppTextStyles.bodySecondary.copyWith(
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.copy,
                  color: AppColors.interactiveNormal,
                  size: 20,
                ),
                onPressed: inviteCode.isNotEmpty
                    ? () {
                        Clipboard.setData(ClipboardData(text: inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã sao chép mã lời mời'),
                            backgroundColor: AppColors.green,
                          ),
                        );
                      }
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Chia sẻ mã này để người khác tham gia server',
          style: AppTextStyles.textMutedSmall,
        ),
      ],
    );
  }

  Widget _buildNavigationSection(
    BuildContext context,
    WidgetRef ref,
    String serverId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quản lý', style: AppTextStyles.header3),
        const SizedBox(height: 8),
        _buildNavigationItem(
          icon: Icons.security_outlined,
          title: 'Quản lý vai trò',
          subtitle: 'Tạo, sửa, xóa vai trò và phân quyền',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RoleManagementScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.interactiveNormal, size: 22),
        title: Text(
          title,
          style: AppTextStyles.bodySecondary.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(subtitle, style: AppTextStyles.textMutedSmall),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.interactiveNormal,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildDangerZone(
    BuildContext context,
    WidgetRef ref,
    String serverId,
    bool isOwner,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vùng nguy hiểm',
          style: AppTextStyles.header3.copyWith(color: AppColors.red),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.red.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isOwner) ...[
                Text(
                  'Bạn là chủ sở hữu server này.',
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: 4),
                Text(
                  'Xóa server sẽ xóa toàn bộ dữ liệu bao gồm kênh, tin nhắn, vai trò và thành viên. Không thể hoàn tác.',
                  style: AppTextStyles.textMutedSmall,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        _confirmDeleteServer(context, ref, serverId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Xóa Server',
                      style: AppTextStyles.buttonText,
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  'Bạn sẽ rời khỏi server này và mất quyền truy cập vào tất cả kênh.',
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () =>
                        _confirmLeaveServer(context, ref, serverId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Rời Server',
                      style: AppTextStyles.buttonText,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _confirmLeaveServer(
    BuildContext context,
    WidgetRef ref,
    String serverId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgFloating,
        title: Text('Rời Server?', style: AppTextStyles.headerPrimary),
        content: Text(
          'Bạn có chắc muốn rời khỏi server này? Bạn sẽ cần mã lời mời để tham gia lại.',
          style: AppTextStyles.bodySecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.interactiveNormal),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(serverSettingsNotifierProvider.notifier)
                  .leaveServer(serverId: serverId);
            },
            child: const Text('Rời', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteServer(
    BuildContext context,
    WidgetRef ref,
    String serverId,
  ) {
    final serverName = ref.read(selectedServerNameProvider);
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgFloating,
        title: Text('Xóa Server?', style: AppTextStyles.headerPrimary),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hành động này không thể hoàn tác. Tất cả kênh, tin nhắn, vai trò và thành viên sẽ bị xóa vĩnh viễn.',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Nhập tên server "$serverName" để xác nhận:',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              style: const TextStyle(color: AppColors.textNormal),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.red),
                ),
                hintText: 'Tên server',
                hintStyle: AppTextStyles.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              confirmController.dispose();
              Navigator.pop(ctx);
            },
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.interactiveNormal),
            ),
          ),
          TextButton(
            onPressed: () {
              final input = confirmController.text.trim();
              confirmController.dispose();
              if (input != serverName) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tên server không khớp'),
                    backgroundColor: AppColors.red,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              ref
                  .read(serverSettingsNotifierProvider.notifier)
                  .deleteServer(serverId: serverId);
            },
            child: const Text('Xóa', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}
