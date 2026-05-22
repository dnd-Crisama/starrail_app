import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/profile_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import '../../../admin/presentation/providers/admin_provider.dart';
import '../../../admin/presentation/screens/admin_console_screen.dart';
import '../../../message/presentation/providers/message_provider.dart';
import '../providers/home_provider.dart';
import '../../../server/presentation/screens/create_server_screen.dart';
import '../../../server/presentation/screens/join_server_screen.dart';
import '../../../server/presentation/screens/server_settings_screen.dart';
import '../../../server/presentation/screens/channel_management_screen.dart';
import '../../../server/presentation/providers/server_provider.dart';
import '../../../server/presentation/providers/channel_provider.dart';
import '../../../server/presentation/providers/role_provider.dart';
import '../../../server/domain/entities/channel_entity.dart';
import '../../../server/domain/entities/server_entity.dart';
import '../../../server/domain/entities/permission.dart';
import '../../../message/presentation/screens/chat_screen.dart';
import '../../../message/presentation/widgets/message_search_dialog.dart';
import '../../../friend/presentation/screens/dm_chat_screen.dart';
import '../../../server/presentation/widgets/collapsible_server_member_list.dart';
import '../../../server/presentation/widgets/full_screen_member_list.dart';
import '../../../../core/router/slide_from_right_route.dart';
import '../widgets/add_server_modal.dart';
import '../widgets/dm_sidebar_panel.dart';
import '../widgets/server_icon_button.dart';
import '../widgets/server_list_rail.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isDrawerOpen = false;
  bool _isSelectingInitialChannel = false;

  void _openDrawer() {
    setState(() => _isDrawerOpen = true);
  }

  void _closeDrawer() {
    setState(() => _isDrawerOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    _listenForSuspendedSelectedServer();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppConstants.mobileBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: isMobile
            ? _buildMobileLayout(context)
            : _buildDesktopLayout(context, ref),
      ),
    );
  }

  void _listenForSuspendedSelectedServer() {
    ref.listen(userServersStreamProvider, (previous, next) {
      next.whenData((servers) {
        final selectedServerId = ref.read(selectedServerIdProvider);
        if (selectedServerId == null) return;

        final isSuperAdmin = ref
            .read(isCurrentUserSuperAdminProvider)
            .maybeWhen(data: (value) => value, orElse: () => false);
        if (isSuperAdmin) return;

        final selectedServer = servers
            .where((server) => server.serverId == selectedServerId)
            .firstOrNull;
        if (selectedServer == null || !selectedServer.isSuspended) return;

        ref.read(selectedServerIdProvider.notifier).state = null;
        ref.read(selectedChannelIdProvider.notifier).state = null;
        ref.read(selectedServerNameProvider.notifier).state = 'Direct Messages';
        if (!mounted) return;
        _showSuspendedServerMessage();
      });
    });
  }

  void _showSuspendedServerMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Server này đang bị tạm khóa.')),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  MOBILE LAYOUT — Discord-style with custom left drawer
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMobileLayout(BuildContext context) {
    final selectedServerId = ref.watch(selectedServerIdProvider);
    final channelInfo = ref.watch(selectedChannelInfoProvider);

    // Trên mobile: hiện tên kênh nếu đã chọn, ngược lại hiện tên server
    final appBarTitle = channelInfo != null
        ? '# ${channelInfo.name}'
        : ref.watch(selectedServerNameProvider);

    return Stack(
      children: [
        // Main content
        Scaffold(
          backgroundColor: AppColors.bgPrimary,
          appBar: AppBar(
            backgroundColor: AppColors.bgTertiary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: AppColors.white),
              onPressed: _openDrawer,
            ),
            title: GestureDetector(
              onTap: _openDrawer,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    appBarTitle,
                    style: AppTextStyles.serverName,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.expand_more,
                    color: AppColors.interactiveNormal,
                    size: 18,
                  ),
                ],
              ),
            ),
            actions: [
              if (selectedServerId != null)
                IconButton(
                  icon: const Icon(
                    Icons.people_outline,
                    color: AppColors.interactiveNormal,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    SlideFromRightPageRoute(
                      builder: (_) =>
                          FullScreenMemberList(serverId: selectedServerId),
                      settings: const RouteSettings(name: 'member-list'),
                    ),
                  ),
                ),
              if (selectedServerId != null)
                IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: AppColors.interactiveNormal,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ServerSettingsScreen(),
                    ),
                  ),
                ),
            ],
          ),
          body: _buildMainContent(ref),
        ),

        // Custom Discord-style drawer overlay
        _buildDrawerOverlay(context),
      ],
    );
  }

  Widget _buildDrawerOverlay(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return IgnorePointer(
      ignoring: !_isDrawerOpen,
      child: Stack(
        children: [
          AnimatedOpacity(
            opacity: _isDrawerOpen ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: GestureDetector(
              onTap: _closeDrawer,
              child: Container(color: AppColors.scrim),
            ),
          ),
          AnimatedSlide(
            offset: _isDrawerOpen ? Offset.zero : const Offset(-1, 0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: screenWidth,
                  color: AppColors.bgTertiary,
                  child: _buildDrawerContent(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerContent(BuildContext context) {
    return Row(
      children: [
        // Left strip: server icons (Discord pill-style)
        _buildDrawerServerStrip(context),
        // Right panel: channel list + user bar
        Expanded(child: _buildDrawerChannelPanel(context)),
      ],
    );
  }

  // ── Server Strip (left column with pill indicators) ──────────

  Widget _buildDrawerServerStrip(BuildContext context) {
    final serverListState = ref.watch(userServersStreamProvider);
    final selectedServerId = ref.watch(selectedServerIdProvider);
    final isSuperAdmin = ref
        .watch(isCurrentUserSuperAdminProvider)
        .maybeWhen(data: (value) => value, orElse: () => false);

    return Container(
      width: 72,
      color: AppColors.bgTertiary,
      child: Column(
        children: [
          const SizedBox(height: 12),
          if (isSuperAdmin) ...[
            ServerIconButton(
              isSelected: false,
              indicatorStyle: ServerIconIndicatorStyle.sidePill,
              bottomPadding: 4,
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: AppColors.green,
                size: 24,
              ),
              onTap: () {
                _closeDrawer();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminConsoleScreen()),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                width: 32,
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ],
          // DM button
          ServerIconButton(
            isSelected: selectedServerId == null,
            indicatorStyle: ServerIconIndicatorStyle.sidePill,
            bottomPadding: 4,
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: AppColors.white,
              size: 24,
            ),
            onTap: () {
              setState(() => _isSelectingInitialChannel = false);
              ref.read(selectedServerIdProvider.notifier).state = null;
              ref.read(selectedServerNameProvider.notifier).state =
                  'Direct Messages';
              ref.read(selectedChannelIdProvider.notifier).state = null;
              _closeDrawer();
            },
          ),
          // Separator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              width: 32,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          // Server list
          Expanded(
            child: serverListState.when(
              data: (servers) {
                if (servers.isEmpty) {
                  return const SizedBox.shrink();
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 4),
                  itemCount: servers.length,
                  itemBuilder: (context, index) {
                    final server = servers[index];
                    final isSelected = selectedServerId == server.serverId;
                    final isLockedForUser = server.isSuspended && !isSuperAdmin;

                    return ServerIconButton(
                      isSelected: isSelected,
                      indicatorStyle: ServerIconIndicatorStyle.sidePill,
                      bottomPadding: 4,
                      hasUnread:
                          !isLockedForUser && _serverHasUnread(server.serverId),
                      child: _buildServerIconContent(
                        server,
                        isLocked: isLockedForUser,
                        fontSize: 16,
                      ),
                      onTap: () {
                        if (isLockedForUser) {
                          _showSuspendedServerMessage();
                          return;
                        }

                        _selectServerAndFirstVisibleChannel(server);
                        _closeDrawer();
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.brand,
                    strokeWidth: 2,
                  ),
                ),
              ),
              error: (err, _) => const Icon(
                Icons.error_outline,
                color: AppColors.red,
                size: 20,
              ),
            ),
          ),
          // Add server button
          ServerIconButton(
            isSelected: false,
            indicatorStyle: ServerIconIndicatorStyle.sidePill,
            bottomPadding: 4,
            child: const Icon(Icons.add, color: AppColors.green, size: 24),
            onTap: () {
              _closeDrawer();
              _showAddServerModal(context);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Channel Panel (right section of drawer) ──────────────────

  Widget _buildDrawerChannelPanel(BuildContext context) {
    final serverName = ref.watch(selectedServerNameProvider);
    final selectedServerId = ref.watch(selectedServerIdProvider);

    return Container(
      color: AppColors.bgSecondary,
      child: Column(
        children: [
          // Server header bar
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    serverName,
                    style: AppTextStyles.serverName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selectedServerId != null)
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.interactiveNormal,
                      size: 18,
                    ),
                    onPressed: () {
                      _closeDrawer();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ServerSettingsScreen(),
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.expand_more,
                  color: AppColors.interactiveNormal,
                  size: 18,
                ),
              ],
            ),
          ),
          // Channel list
          Expanded(
            child: _buildChannelList(
              selectedServerId,
              onChannelSelected: _closeDrawer,
            ),
          ),
          // User panel at bottom (Discord-style)
          _buildDrawerUserPanel(context),
        ],
      ),
    );
  }

  /// Discord-style user panel at bottom of drawer
  Widget _buildDrawerUserPanel(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final user = profileState.user ?? ref.watch(authNotifierProvider).user;

    final displayName = user?.username ?? 'Unknown';
    final statusText = _mapStatusToString(user?.status);
    final statusColor = _getStatusColor(user?.status);
    final avatarUrl = user?.avatarUrl ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(color: Color(0xFF232428)),
      child: Row(
        children: [
          // Avatar with status indicator
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () {
                  _closeDrawer();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                child: _buildUserAvatar(
                  displayName: displayName,
                  size: 32,
                  backgroundImage: avatarUrl,
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Builder(
                  builder: (dotContext) => GestureDetector(
                    onTap: () => _showStatusPicker(dotContext, user?.status),
                    child: _buildStatusDot(
                      statusColor,
                      user?.status,
                      isMobile: true,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Username + status
          Expanded(
            child: GestureDetector(
              onTap: () {
                _closeDrawer();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.headerPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    statusText,
                    style: AppTextStyles.textMutedSmall.copyWith(
                      color: statusColor,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // Mic icon
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              icon: const Icon(
                Icons.mic_outlined,
                color: AppColors.interactiveNormal,
                size: 18,
              ),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          // Headset icon
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              icon: const Icon(
                Icons.headset_outlined,
                color: AppColors.interactiveNormal,
                size: 18,
              ),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          // Settings gear icon
          SizedBox(
            width: 32,
            height: 32,
            child: PopupMenuButton<String>(
              icon: const Icon(
                Icons.settings_rounded,
                color: AppColors.interactiveNormal,
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              color: AppColors.bgFloating,
              onSelected: (value) async {
                _closeDrawer();
                if (value == 'logout') {
                  // Cập nhật status thành OFFLINE trước khi logout
                  // Chờ 500ms để đảm bảo status được lưu trước logout
                  await ref.read(authNotifierProvider.notifier).logout();
                  return;
                } else if (value == 'profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: AppColors.interactiveNormal,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text('Hồ sơ của tôi', style: AppTextStyles.bodySecondary),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: AppColors.red, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Đăng xuất',
                        style: TextStyle(
                          color: AppColors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  DESKTOP LAYOUT
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref) {
    final selectedServerId = ref.watch(selectedServerIdProvider);

    return Row(
      children: [
        ServerListRail(
          onAddServer: () => showAddServerModal(context),
          onServerSelected: _selectServerAndFirstVisibleChannel,
        ),
        _buildChannelSidebar(context, ref),
        Expanded(child: _buildMainContent(ref)),
        if (selectedServerId != null)
          CollapsibleServerMemberList(
            serverId: selectedServerId,
            isMobile: false,
          ),
      ],
    );
  }

  // ── Channel visibility helpers ───────────────────────────────
  bool _serverHasUnread(String serverId) {
    return ref.watch(serverHasUnreadProvider(serverId));
  }

  Widget _buildServerIconContent(
    ServerEntity server, {
    required bool isLocked,
    double fontSize = 18,
  }) {
    final icon = server.iconUrl.isNotEmpty
        ? Image.network(
            server.iconUrl,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                ServerIconInitial(name: server.name, fontSize: fontSize),
          )
        : ServerIconInitial(name: server.name, fontSize: fontSize);

    if (!isLocked) return icon;

    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(opacity: 0.45, child: icon),
        Container(color: Colors.black.withValues(alpha: 0.35)),
        const Center(
          child: Icon(Icons.lock_rounded, color: AppColors.white, size: 20),
        ),
      ],
    );
  }

  Future<List<ChannelEntity>> _filterVisibleChannels(
    String serverId,
    List<ChannelEntity> channels,
  ) async {
    return ref.read(visibleServerChannelsProvider(serverId).future);
  }

  Future<void> _selectServerAndFirstVisibleChannel(ServerEntity server) async {
    ref.read(selectedServerIdProvider.notifier).state = server.serverId;
    ref.read(selectedServerNameProvider.notifier).state = server.name;
    ref.read(selectedDmChatIdProvider.notifier).state = null;
    ref.read(selectedChannelIdProvider.notifier).state = null;
    if (mounted) {
      setState(() => _isSelectingInitialChannel = true);
    }

    ref
        .read(unreadStatusNotifierProvider.notifier)
        .loadReadStatusForServer(server.serverId);

    ChannelEntity? firstChannel;
    try {
      final channels = await ref.read(
        serverChannelsStreamProvider(server.serverId).future,
      );
      final visibleChannels = await _filterVisibleChannels(
        server.serverId,
        channels,
      );
      firstChannel = _firstVisibleChannelInSidebarOrder(visibleChannels);
    } catch (_) {
      firstChannel = null;
    }

    if (!mounted) return;
    if (ref.read(selectedServerIdProvider) != server.serverId) return;
    ref.read(selectedChannelIdProvider.notifier).state =
        firstChannel?.channelId;
    setState(() => _isSelectingInitialChannel = false);
  }

  ChannelEntity? _firstVisibleChannelInSidebarOrder(
    List<ChannelEntity> channels,
  ) {
    final textChannels = channels.where((c) => c.type == ChannelType.text);
    if (textChannels.isNotEmpty) return textChannels.first;
    return channels.isEmpty ? null : channels.first;
  }

  // ── CHANNEL SIDEBAR (Desktop) ────────────────────────────────
  Widget _buildChannelSidebar(BuildContext context, WidgetRef ref) {
    final serverName = ref.watch(selectedServerNameProvider);
    final selectedServerId = ref.watch(selectedServerIdProvider);

    return Container(
      width: AppConstants.channelSidebarWidth,
      color: AppColors.bgSecondary,
      child: Column(
        children: [
          Container(
            height: AppConstants.channelHeaderHeight + 8,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    serverName,
                    style: AppTextStyles.serverName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selectedServerId != null)
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.interactiveNormal,
                      size: 18,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ServerSettingsScreen(),
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.expand_more,
                  color: AppColors.interactiveNormal,
                  size: 18,
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          Expanded(child: _buildChannelList(selectedServerId)),
          _buildDesktopUserPanel(context, ref),
        ],
      ),
    );
  }

  // ── DESKTOP USER PANEL ─────────────────────────────────────
  Widget _buildDesktopUserPanel(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileNotifierProvider);
    final user = profileState.user ?? ref.watch(authNotifierProvider).user;

    final displayName = user?.username ?? 'Unknown';
    final statusText = _mapStatusToString(user?.status);
    final statusColor = _getStatusColor(user?.status);
    final avatarUrl = user?.avatarUrl ?? '';

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF232428),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                child: _buildUserAvatar(
                  displayName: displayName,
                  size: 32,
                  backgroundImage: avatarUrl,
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Builder(
                  builder: (dotContext) => GestureDetector(
                    onTap: () => _showStatusPicker(dotContext, user?.status),
                    child: _buildStatusDot(statusColor, user?.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.headerPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    statusText,
                    style: AppTextStyles.textMutedSmall.copyWith(
                      color: statusColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 28,
            height: 28,
            child: IconButton(
              icon: const Icon(
                Icons.mic_outlined,
                color: AppColors.interactiveNormal,
                size: 18,
              ),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          SizedBox(
            width: 28,
            height: 28,
            child: IconButton(
              icon: const Icon(
                Icons.headset_outlined,
                color: AppColors.interactiveNormal,
                size: 18,
              ),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),

          PopupMenuButton<String>(
            icon: const Icon(
              Icons.settings_rounded,
              color: AppColors.interactiveNormal,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            color: AppColors.bgFloating,
            onSelected: (value) async {
              if (value == 'logout') {
                // Cập nhật status thành OFFLINE trước khi logout
                // Chờ 500ms để đảm bảo status được lưu trước logout
                await ref.read(authNotifierProvider.notifier).logout();
                return;
              } else if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: AppColors.interactiveNormal,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text('Hồ sơ của tôi', style: AppTextStyles.bodySecondary),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.red, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Đăng xuất',
                      style: TextStyle(
                        color: AppColors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SHARED UI COMPONENTS
  // ═══════════════════════════════════════════════════════════════

  /// Xây dựng danh sách kênh real-time từ Firestore
  /// [onChannelSelected] gọi sau khi chọn kênh — dùng để đóng drawer trên mobile
  Widget _buildChannelList(
    String? selectedServerId, {
    VoidCallback? onChannelSelected,
  }) {
    if (selectedServerId == null) {
      // Direct Messages mode — hiển thị DmListScreen thực
      final selectedDmChatId = ref.watch(selectedDmChatIdProvider);
      return DmSidebarPanel(
        selectedChatId: selectedDmChatId,
        onChatSelected: (chatId) {
          ref.read(selectedDmChatIdProvider.notifier).state = chatId;
          onChannelSelected?.call();
        },
      );
    }

    final channelsState = ref.watch(
      visibleServerChannelsProvider(selectedServerId),
    );
    final selectedChannelId = ref.watch(selectedChannelIdProvider);
    final currentUserId =
        ref.watch(authNotifierProvider.select((state) => state.user?.uid)) ??
        '';
    final isOwner = ref.watch(isServerOwnerProvider(selectedServerId));
    final canManageChannels = currentUserId.isNotEmpty
        ? ref.watch(
            hasPermissionProvider((
              serverId: selectedServerId,
              userId: currentUserId,
              permission: Permission.manageChannel,
            )),
          )
        : const AsyncValue<bool>.data(false);
    final canCreateChannel =
        isOwner ||
        canManageChannels.maybeWhen(
          data: (value) => value,
          orElse: () => false,
        );

    return channelsState.when(
      data: (channels) {
        if (channels.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tag_outlined,
                  size: 36,
                  color: AppColors.channelDefault.withOpacity(0.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Chưa có kênh nào',
                  style: AppTextStyles.textMutedSmall,
                ),
              ],
            ),
          );
        }

        // Tách kênh text và voice
        final textChannels = channels
            .where((c) => c.type == ChannelType.text)
            .toList();
        final voiceChannels = channels
            .where((c) => c.type == ChannelType.voice)
            .toList();

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // Kênh văn bản — luôn hiện header để tạo nhanh
            _buildCategoryHeader(
              'KÊNH VĂN BẢN',
              onAdd: canCreateChannel
                  ? () => _showQuickCreateChannel(
                      serverId: selectedServerId,
                      type: ChannelType.text,
                    )
                  : null,
            ),
            if (textChannels.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Text(
                  'Chưa có kênh văn bản',
                  style: AppTextStyles.textMutedSmall,
                ),
              )
            else
              ...textChannels.map(
                (channel) => _buildChannelItem(
                  name: channel.name,
                  isVoice: false,
                  isSelected: selectedChannelId == channel.channelId,
                  serverId: selectedServerId,
                  channelId: channel.channelId,
                  onTap: () {
                    ref.read(selectedChannelIdProvider.notifier).state =
                        channel.channelId;
                    onChannelSelected?.call();
                  },
                ),
              ),
            const SizedBox(height: 8),
            // Kênh thoại — luôn hiện header để tạo nhanh
            _buildCategoryHeader(
              'KÊNH THOẠI',
              onAdd: canCreateChannel
                  ? () => _showQuickCreateChannel(
                      serverId: selectedServerId,
                      type: ChannelType.voice,
                    )
                  : null,
            ),
            if (voiceChannels.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Text(
                  'Chưa có kênh thoại',
                  style: AppTextStyles.textMutedSmall,
                ),
              )
            else
              ...voiceChannels.map(
                (channel) => _buildChannelItem(
                  name: channel.name,
                  isVoice: true,
                  isSelected: selectedChannelId == channel.channelId,
                  serverId: selectedServerId,
                  channelId: channel.channelId,
                  onTap: () {
                    ref.read(selectedChannelIdProvider.notifier).state =
                        channel.channelId;
                    onChannelSelected?.call();
                  },
                ),
              ),
          ],
        );
      },
      loading: () => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: AppColors.brand,
            strokeWidth: 2,
          ),
        ),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.red, size: 20),
            const SizedBox(height: 4),
            Text('Không thể tải kênh', style: AppTextStyles.textMutedSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String name, {VoidCallback? onAdd}) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8, top: 16, bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(name, style: AppTextStyles.categoryHeader)),
          if (onAdd != null)
            SizedBox(
              width: 20,
              height: 20,
              child: InkWell(
                onTap: onAdd,
                customBorder: const CircleBorder(),
                child: const Icon(
                  Icons.add,
                  color: AppColors.channelDefault,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChannelItem({
    required String name,
    bool isSelected = false,
    bool isVoice = false,
    bool isMuted = false,
    String? serverId,
    String? channelId,
    VoidCallback? onTap,
  }) {
    // Discord-style: Kiểm tra unread status cho channel
    bool isUnread = false;
    if (serverId != null && channelId != null) {
      isUnread = ref.watch(
        channelUnreadProvider((serverId: serverId, channelId: channelId)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: isSelected
            ? AppColors.bgModifierSelected
            : isUnread
            ? AppColors.bgModifierHover.withValues(alpha: 0.5)
            : AppColors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                // Discord-style: White indicator dot cho unread channel
                if (isUnread && !isSelected)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                Icon(
                  isVoice ? Icons.volume_up_outlined : Icons.tag,
                  color: isSelected
                      ? AppColors.channelDefault
                      : isUnread
                      ? AppColors.white
                      : AppColors.channelDefault.withOpacity(0.6),
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    name,
                    style: isSelected
                        ? AppTextStyles.channelNameSelected
                        : isUnread
                        ? AppTextStyles.channelNameUnread
                        : AppTextStyles.channelName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openChannelSettingsFromSidebar(ChannelEntity channel) async {
    final currentUser = ref.read(authNotifierProvider).user;
    if (currentUser == null) return;

    final isOwner = ref.read(isServerOwnerProvider(channel.serverId));
    final canManageChannel =
        isOwner ||
        await ref.read(
          hasPermissionProvider((
            serverId: channel.serverId,
            userId: currentUser.uid,
            permission: Permission.manageChannel,
          )).future,
        ) ||
        await ref.read(
          hasPermissionProvider((
            serverId: channel.serverId,
            userId: currentUser.uid,
            permission: Permission.manageServer,
          )).future,
        );

    if (!mounted) return;
    if (!canManageChannel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn không có quyền chỉnh sửa kênh này.'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChannelEditorScreen(
          serverId: channel.serverId,
          editingChannel: channel,
        ),
      ),
    );
  }

  Widget _buildUserAvatar({
    required String displayName,
    double size = 32,
    Color? backgroundColor,
    String? backgroundImage,
  }) {
    return AppAvatar(
      imageUrl: backgroundImage ?? '',
      displayName: displayName,
      size: size,
      backgroundColor: backgroundColor ?? AppColors.brand,
      textStyle: TextStyle(
        color: AppColors.white,
        fontSize: size * 0.45,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildMainContent(WidgetRef ref) {
    final channelInfo = ref.watch(selectedChannelInfoProvider);
    final selectedServerId = ref.watch(selectedServerIdProvider);
    final selectedChannelId = ref.watch(selectedChannelIdProvider);
    final selectedDmChatId = ref.watch(selectedDmChatIdProvider);

    // Lấy tên kênh từ provider nếu có
    String channelDisplayName = 'general';
    ChannelType channelType = ChannelType.text;
    String channelTopic = '';

    if (channelInfo != null) {
      channelDisplayName = channelInfo.name;
      channelType = channelInfo.type;
      channelTopic = channelInfo.topic;
    }

    // Chế độ DM — không cần header kênh, ẩn hẳn
    if (selectedServerId == null) {
      return _buildMainContentBody(
        ref,
        selectedServerId: selectedServerId,
        selectedChannelId: selectedChannelId,
        channelInfo: channelInfo,
        channelDisplayName: channelDisplayName,
        channelTopic: channelTopic,
        selectedDmChatId: selectedDmChatId,
      );
    }

    return Column(
      children: [
        // Channel header bar (chỉ hiện khi ở chế độ server)
        Container(
          height: AppConstants.channelHeaderHeight,
          color: AppColors.bgSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                channelType == ChannelType.voice
                    ? Icons.volume_up_outlined
                    : Icons.tag,
                color: AppColors.channelDefault,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(channelDisplayName, style: AppTextStyles.headerSecondary),
              const Spacer(),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 400) {
                    return const SizedBox.shrink();
                  }
                  return InkWell(
                    onTap: selectedChannelId == null || channelInfo == null
                        ? null
                        : () => showMessageSearchDialog(
                            context: context,
                            serverId: selectedServerId,
                            channelId: selectedChannelId,
                            channelName: channelDisplayName,
                          ),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 160,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.centerLeft,
                      child: const Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: AppColors.textMuted,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text('Tìm kiếm', style: AppTextStyles.textMutedSmall),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const Divider(color: AppColors.divider, height: 1),
        // Nội dung chính: ChatScreen nếu đã chọn kênh text, ngược lại placeholder
        Expanded(
          child: _buildMainContentBody(
            ref,
            selectedServerId: selectedServerId,
            selectedChannelId: selectedChannelId,
            channelInfo: channelInfo,
            channelDisplayName: channelDisplayName,
            channelTopic: channelTopic,
            selectedDmChatId: selectedDmChatId,
          ),
        ),
      ],
    );
  }

  /// Hiển thị chat screen hoặc placeholder tùy trạng thái chọn kênh
  Widget _buildMainContentBody(
    WidgetRef ref, {
    required String? selectedServerId,
    required String? selectedChannelId,
    required ChannelEntity? channelInfo,
    required String channelDisplayName,
    required String channelTopic,
    String? selectedDmChatId,
  }) {
    // Chưa chọn server → chế độ Direct Messages
    if (selectedServerId == null) {
      // Đã chọn một DM chat → hiển thị DmChatScreen nhúng
      if (selectedDmChatId != null && selectedDmChatId.isNotEmpty) {
        return DmChatScreen(
          key: ValueKey('dm_$selectedDmChatId'),
          chatId: selectedDmChatId,
        );
      }
      return DmSidebarPanel(
        selectedChatId: selectedDmChatId,
        onChatSelected: (chatId) {
          ref.read(selectedDmChatIdProvider.notifier).state = chatId;
        },
      );
    }

    if (selectedChannelId == null || channelInfo == null) {
      if (_isSelectingInitialChannel || selectedChannelId != null) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppColors.brand,
            strokeWidth: 2,
          ),
        );
      }

      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.bgModifierHover,
                borderRadius: BorderRadius.circular(34),
              ),
              child: const Icon(
                Icons.tag,
                color: AppColors.channelDefault,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Không có kênh có thể truy cập',
              style: AppTextStyles.welcomeTitle,
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn chưa có quyền xem kênh nào trong server này.',
              style: AppTextStyles.welcomeSubtitle,
            ),
          ],
        ),
      );
    }

    // Đã chọn kênh text → hiển thị ChatScreen
    // ValueKey(channelId) đảm bảo Flutter tạo state MỚI khi chuyển kênh,
    // tránh lỗi _olderMessages / _previousMessageCount / _lastReadMessageId
    // của kênh cũ bị mang sang kênh mới.
    if (channelInfo.type == ChannelType.text) {
      return ChatScreen(
        key: ValueKey('${selectedServerId}_$selectedChannelId'),
        serverId: selectedServerId,
        channelId: selectedChannelId,
      );
    }

    // Đã chọn kênh voice → placeholder (sẽ implement ở PART 16)
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.bgModifierHover,
              borderRadius: BorderRadius.circular(34),
            ),
            child: const Icon(
              Icons.volume_up_outlined,
              color: AppColors.channelDefault,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Kênh thoại: $channelDisplayName',
            style: AppTextStyles.welcomeTitle,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tính năng thoại sẽ được thêm sau.',
            style: AppTextStyles.welcomeSubtitle,
          ),
        ],
      ),
    );
  }

  String _mapStatusToString(UserStatus? status) {
    switch (status) {
      case UserStatus.online:
        return 'Trực tuyến';
      case UserStatus.idle:
        return 'Chờ đợi';
      case UserStatus.dnd:
        return 'Không làm phiền';
      case UserStatus.invisible:
        return 'Vô hình';
      default:
        return 'Ngoại tuyến';
    }
  }

  Color _getStatusColor(UserStatus? status) {
    switch (status) {
      case UserStatus.online:
        return AppColors.statusOnline;
      case UserStatus.idle:
        return AppColors.statusIdle;
      case UserStatus.dnd:
        return AppColors.statusDnd;
      case UserStatus.invisible:
        return AppColors.statusInvisible;
      default:
        return AppColors.statusOffline;
    }
  }

  /// Hiển thị dot trạng thái trên avatar (có hollow circle cho invisible)
  Widget _buildStatusDot(
    Color statusColor,
    UserStatus? status, {
    bool isMobile = false,
  }) {
    final isInvisible = status == UserStatus.invisible;

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: isInvisible ? const Color(0xFF232428) : statusColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF232428),
          width: isMobile ? 2.5 : 2,
        ),
      ),
      child: isInvisible
          ? Padding(
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }

  /// Hiển thị popup chọn trạng thái (Discord-style) — xuất hiện gần status dot
  void _showStatusPicker(BuildContext dotContext, UserStatus? currentStatus) {
    // Lấy vị trí của status dot so với overlay
    final RenderBox dotBox = dotContext.findRenderObject() as RenderBox;
    final RenderBox overlayBox =
        Overlay.of(dotContext).context.findRenderObject() as RenderBox;
    final Offset dotPosition = dotBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final Size dotSize = dotBox.size;

    // 4 items × 40px height + padding ≈ 180px; dùng 180 làm ước lượng chiều cao popup
    const double estimatedPopupHeight = 180;
    const double popupWidth = 220;

    // Popup hiện bên trên status dot, căn lề trái với dot
    // Nếu không đủ chỗ phía trên thì hiện bên dưới dot
    double popupTop = dotPosition.dy - estimatedPopupHeight - 4;
    if (popupTop < 0) {
      popupTop = dotPosition.dy + dotSize.height + 4;
    }

    final popupPosition = RelativeRect.fromSize(
      Rect.fromLTWH(
        dotPosition.dx - 4,
        popupTop,
        popupWidth,
        estimatedPopupHeight,
      ),
      overlayBox.size,
    );

    showMenu<UserStatus>(
      context: dotContext,
      position: popupPosition,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: AppColors.bgFloating,
      elevation: 8,
      items: [
        _buildStatusMenuItem(
          status: UserStatus.online,
          label: 'Trực tuyến',
          color: AppColors.statusOnline,
          currentStatus: currentStatus,
        ),
        _buildStatusMenuItem(
          status: UserStatus.idle,
          label: 'Chờ đợi',
          color: AppColors.statusIdle,
          currentStatus: currentStatus,
        ),
        _buildStatusMenuItem(
          status: UserStatus.dnd,
          label: 'Không làm phiền',
          color: AppColors.statusDnd,
          currentStatus: currentStatus,
        ),
        _buildStatusMenuItem(
          status: UserStatus.invisible,
          label: 'Vô hình',
          color: AppColors.statusInvisible,
          isHollow: true,
          currentStatus: currentStatus,
        ),
      ],
    ).then((selectedStatus) {
      if (selectedStatus != null) {
        ref
            .read(profileNotifierProvider.notifier)
            .updatePresenceStatus(selectedStatus);
      }
    });
  }

  /// Xây dựng mỗi item trong menu chọn trạng thái
  PopupMenuItem<UserStatus> _buildStatusMenuItem({
    required UserStatus status,
    required String label,
    required Color color,
    required UserStatus? currentStatus,
    bool isHollow = false,
  }) {
    final isSelected = currentStatus == status;

    return PopupMenuItem<UserStatus>(
      value: status,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Status dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isHollow ? AppColors.bgFloating : color,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: isHollow ? 2 : 0),
            ),
            child: isHollow
                ? Padding(
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          // Label
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.textNormal,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          // Check mark if selected
          if (isSelected)
            const Icon(
              Icons.check_rounded,
              color: AppColors.textNormal,
              size: 18,
            ),
        ],
      ),
    );
  }

  /// Hiển thị dialog tạo kênh nhanh (Discord-style)
  void _showQuickCreateChannel({
    required String serverId,
    required ChannelType type,
  }) {
    final nameController = TextEditingController();
    final isText = type == ChannelType.text;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.bgFloating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            title: Row(
              children: [
                Icon(
                  isText ? Icons.tag : Icons.volume_up_outlined,
                  color: AppColors.brand,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  isText ? 'Tạo kênh văn bản' : 'Tạo kênh thoại',
                  style: AppTextStyles.headerPrimary.copyWith(fontSize: 18),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tên kênh',
                  style: AppTextStyles.bodySecondary.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: const TextStyle(
                    color: AppColors.textNormal,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(
                        color: AppColors.inputBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(
                        color: AppColors.inputBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: AppColors.brand),
                    ),
                    prefixText: isText ? '# ' : '',
                    prefixStyle: AppTextStyles.textMuted,
                    hintText: isText ? 'kênh-mới' : 'kênh-thoại-mới',
                    hintStyle: AppTextStyles.textMuted,
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 8),
                Text(
                  isText
                      ? 'Tên kênh chỉ được chứa chữ thường, số và dấu gạch ngang.'
                      : 'Kênh thoại cho phép tham gia gọi âm thanh/video.',
                  style: AppTextStyles.textMutedSmall,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Hủy',
                  style: TextStyle(color: AppColors.interactiveNormal),
                ),
              ),
              TextButton(
                onPressed: nameController.text.trim().isEmpty
                    ? null
                    : () async {
                        final name = nameController.text
                            .trim()
                            .toLowerCase()
                            .replaceAll(' ', '-');
                        Navigator.pop(context);
                        await ref
                            .read(channelManagementNotifierProvider.notifier)
                            .createChannel(
                              serverId: serverId,
                              name: name,
                              type: type,
                            );
                        if (mounted) {
                          final error = ref
                              .read(channelManagementNotifierProvider)
                              .errorMessage;
                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                backgroundColor: AppColors.red,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isText
                                      ? 'Đã tạo kênh văn bản #$name'
                                      : 'Đã tạo kênh thoại $name',
                                ),
                                backgroundColor: AppColors.green,
                              ),
                            );
                          }
                        }
                      },
                child: Text(
                  'Tạo',
                  style: TextStyle(
                    color: nameController.text.trim().isEmpty
                        ? AppColors.textMuted
                        : AppColors.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

void _showAddServerModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bgSecondary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.add_circle_outline,
                color: AppColors.white,
              ),
              title: const Text(
                'Tạo Server mới',
                style: TextStyle(color: AppColors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateServerScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.group_add_outlined,
                color: AppColors.white,
              ),
              title: const Text(
                'Tham gia Server',
                style: TextStyle(color: AppColors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JoinServerScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}
