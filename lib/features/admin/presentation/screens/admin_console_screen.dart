import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../server/domain/entities/server_entity.dart';
import '../providers/admin_provider.dart';

class AdminConsoleScreen extends ConsumerWidget {
  const AdminConsoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdminAsync = ref.watch(isCurrentUserSuperAdminProvider);
    final actionState = ref.watch(adminActionNotifierProvider);

    ref.listen<AdminActionState>(adminActionNotifierProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.red,
          ),
        );
      }
    });

    return isAdminAsync.when(
      data: (isAdmin) {
        if (!isAdmin) {
          return _AccessDeniedScaffold(onBack: () => Navigator.pop(context));
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
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
              title: const Text(
                'Admin Console',
                style: AppTextStyles.headerPrimary,
              ),
              bottom: const TabBar(
                indicatorColor: AppColors.brand,
                labelColor: AppColors.white,
                unselectedLabelColor: AppColors.textMuted,
                tabs: [
                  Tab(text: 'Users'),
                  Tab(text: 'Servers'),
                ],
              ),
            ),
            body: Stack(
              children: [
                const TabBarView(
                  children: [_UsersAdminTab(), _ServersAdminTab()],
                ),
                if (actionState.isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.25),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.brand),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(child: CircularProgressIndicator(color: AppColors.brand)),
      ),
      error: (_, __) =>
          _AccessDeniedScaffold(onBack: () => Navigator.pop(context)),
    );
  }
}

class _UsersAdminTab extends ConsumerWidget {
  const _UsersAdminTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(filteredAdminUsersProvider);
    final filter = ref.watch(adminUserFilterProvider);

    return usersAsync.when(
      data: (users) {
        return Column(
          children: [
            _AdminSearchField(
              hintText: 'Tìm user theo tên, email hoặc ID',
              onChanged: (value) =>
                  ref.read(adminUserSearchQueryProvider.notifier).state = value,
            ),
            _UserFilterBar(selectedFilter: filter),
            Expanded(
              child: users.isEmpty
                  ? const Center(
                      child: Text(
                        'Không tìm thấy user phù hợp',
                        style: AppTextStyles.textMuted,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _UserAdminTile(user: users[index]),
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      ),
      error: (error, _) => Center(
        child: Text(
          'Không thể tải users: $error',
          style: AppTextStyles.textMuted,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _UserFilterBar extends ConsumerWidget {
  final AdminUserFilter selectedFilter;

  const _UserFilterBar({required this.selectedFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      color: AppColors.bgPrimary,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _FilterChipButton(
            label: 'Tất cả',
            selected: selectedFilter == AdminUserFilter.all,
            onTap: () => ref.read(adminUserFilterProvider.notifier).state =
                AdminUserFilter.all,
          ),
          _FilterChipButton(
            label: 'User thường',
            selected: selectedFilter == AdminUserFilter.regular,
            onTap: () => ref.read(adminUserFilterProvider.notifier).state =
                AdminUserFilter.regular,
          ),
          _FilterChipButton(
            label: 'Super admin',
            selected: selectedFilter == AdminUserFilter.superAdmin,
            onTap: () => ref.read(adminUserFilterProvider.notifier).state =
                AdminUserFilter.superAdmin,
          ),
          _FilterChipButton(
            label: 'Bị khóa',
            selected: selectedFilter == AdminUserFilter.disabled,
            onTap: () => ref.read(adminUserFilterProvider.notifier).state =
                AdminUserFilter.disabled,
          ),
        ],
      ),
    );
  }
}

class _UserAdminTile extends ConsumerWidget {
  final UserEntity user;

  const _UserAdminTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: user.isDisabled ? AppColors.red : AppColors.brand,
            backgroundImage: user.avatarUrl.isNotEmpty
                ? NetworkImage(user.avatarUrl)
                : null,
            child: user.avatarUrl.isEmpty
                ? Text(
                    user.username.isNotEmpty
                        ? user.username[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: AppColors.white),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.username,
                        style: AppTextStyles.bodySecondary.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.isSuperAdmin) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_user,
                        color: AppColors.green,
                        size: 16,
                      ),
                    ],
                    if (user.isDisabled) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.block, color: AppColors.red, size: 16),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(user.email, style: AppTextStyles.textMutedSmall),
                Text('ID: ${user.uid}', style: AppTextStyles.textMutedSmall),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: AppColors.bgFloating,
            icon: const Icon(
              Icons.more_vert,
              color: AppColors.interactiveNormal,
            ),
            onSelected: (value) => _handleUserAction(context, ref, value),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: user.isDisabled ? 'enable' : 'disable',
                child: Text(user.isDisabled ? 'Mở khóa user' : 'Khóa user'),
              ),
              PopupMenuItem(
                value: user.isSuperAdmin ? 'remove_admin' : 'make_admin',
                child: Text(
                  user.isSuperAdmin ? 'Gỡ super admin' : 'Cấp super admin',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleUserAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final notifier = ref.read(adminActionNotifierProvider.notifier);
    switch (action) {
      case 'enable':
        await notifier.setUserDisabled(userId: user.uid, isDisabled: false);
        break;
      case 'disable':
        await notifier.setUserDisabled(userId: user.uid, isDisabled: true);
        break;
      case 'make_admin':
        await notifier.setUserSuperAdmin(userId: user.uid, isSuperAdmin: true);
        break;
      case 'remove_admin':
        await notifier.setUserSuperAdmin(userId: user.uid, isSuperAdmin: false);
        break;
    }
  }
}

class _ServersAdminTab extends ConsumerWidget {
  const _ServersAdminTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serversAsync = ref.watch(filteredAdminServersProvider);

    return serversAsync.when(
      data: (servers) {
        return Column(
          children: [
            _AdminSearchField(
              hintText: 'Tìm server theo tên, ID, owner hoặc invite code',
              onChanged: (value) =>
                  ref.read(adminServerSearchQueryProvider.notifier).state =
                      value,
            ),
            Expanded(
              child: servers.isEmpty
                  ? const Center(
                      child: Text(
                        'Không tìm thấy server phù hợp',
                        style: AppTextStyles.textMuted,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: servers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _ServerAdminTile(server: servers[index]),
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      ),
      error: (error, _) => Center(
        child: Text(
          'Không thể tải servers: $error',
          style: AppTextStyles.textMuted,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _AdminSearchField extends ConsumerStatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;

  const _AdminSearchField({required this.hintText, required this.onChanged});

  @override
  ConsumerState<_AdminSearchField> createState() => _AdminSearchFieldState();
}

class _AdminSearchFieldState extends ConsumerState<_AdminSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      color: AppColors.bgPrimary,
      child: TextField(
        controller: _controller,
        style: const TextStyle(color: AppColors.textNormal),
        onChanged: (value) {
          widget.onChanged(value);
          setState(() {});
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.inputBackground,
          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                ),
          hintText: widget.hintText,
          hintStyle: AppTextStyles.textMuted,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      label: Text(label),
      selectedColor: AppColors.brand.withValues(alpha: 0.22),
      backgroundColor: AppColors.bgSecondary,
      checkmarkColor: AppColors.white,
      labelStyle: TextStyle(
        color: selected ? AppColors.white : AppColors.interactiveNormal,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: selected ? AppColors.brand : AppColors.inputBorder,
      ),
      onSelected: (_) => onTap(),
    );
  }
}

class _ServerAdminTile extends ConsumerWidget {
  final ServerEntity server;

  const _ServerAdminTile({required this.server});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: server.isSuspended
                ? AppColors.red
                : AppColors.brand,
            backgroundImage: server.iconUrl.isNotEmpty
                ? NetworkImage(server.iconUrl)
                : null,
            child: server.iconUrl.isEmpty
                ? Text(
                    server.name.isNotEmpty ? server.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppColors.white),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        server.name,
                        style: AppTextStyles.bodySecondary.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (server.isSuspended) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.pause_circle,
                        color: AppColors.red,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Owner: ${server.ownerId}',
                  style: AppTextStyles.textMutedSmall,
                ),
                Text(
                  'ID: ${server.serverId}',
                  style: AppTextStyles.textMutedSmall,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: AppColors.bgFloating,
            icon: const Icon(
              Icons.more_vert,
              color: AppColors.interactiveNormal,
            ),
            onSelected: (value) => _handleServerAction(context, ref, value),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: server.isSuspended ? 'unsuspend' : 'suspend',
                child: Text(
                  server.isSuspended ? 'Mở khóa server' : 'Tạm khóa server',
                ),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Xóa server')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleServerAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final notifier = ref.read(adminActionNotifierProvider.notifier);
    switch (action) {
      case 'suspend':
        await notifier.setServerSuspended(
          serverId: server.serverId,
          isSuspended: true,
        );
        break;
      case 'unsuspend':
        await notifier.setServerSuspended(
          serverId: server.serverId,
          isSuspended: false,
        );
        break;
      case 'delete':
        if (!context.mounted) return;
        final confirmed = await _confirmDeleteServer(context, server.name);
        if (confirmed == true) {
          await notifier.deleteServer(serverId: server.serverId);
        }
        break;
    }
  }
}

class _AccessDeniedScaffold extends StatelessWidget {
  final VoidCallback onBack;

  const _AccessDeniedScaffold({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgTertiary,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.interactiveNormal,
          ),
          onPressed: onBack,
        ),
      ),
      body: const Center(
        child: Text(
          'Bạn không có quyền truy cập Admin Console',
          style: AppTextStyles.textMuted,
        ),
      ),
    );
  }
}

Future<bool?> _confirmDeleteServer(BuildContext context, String serverName) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.bgFloating,
      title: const Text('Xóa server?', style: AppTextStyles.headerPrimary),
      content: Text(
        'Server "$serverName" sẽ bị xóa khỏi hệ thống. Hành động này không thể hoàn tác.',
        style: AppTextStyles.bodySecondary,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Xóa', style: TextStyle(color: AppColors.red)),
        ),
      ],
    ),
  );
}
