import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../message/presentation/providers/message_provider.dart';
import '../providers/home_provider.dart';
import '../../../server/presentation/screens/server_settings_screen.dart';
import '../../../server/presentation/screens/channel_management_screen.dart';
import '../../../server/presentation/providers/server_provider.dart';
import '../../../server/presentation/providers/channel_provider.dart';
import '../../../server/presentation/providers/role_provider.dart';
import '../../../server/domain/entities/channel_entity.dart';
import '../../../server/domain/entities/permission.dart';
import '../../../message/presentation/screens/chat_screen.dart';
import '../../../friend/presentation/screens/dm_chat_screen.dart';
import '../widgets/add_server_modal.dart';
import '../widgets/current_user_panel.dart';
import '../widgets/dm_sidebar_panel.dart';
import '../widgets/server_list_rail.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isDrawerOpen = false;

  void _openDrawer() {
    setState(() => _isDrawerOpen = true);
  }

  void _closeDrawer() {
    setState(() => _isDrawerOpen = false);
  }

  @override
  Widget build(BuildContext context) {
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
        if (_isDrawerOpen) _buildDrawerOverlay(context),
      ],
    );
  }

  Widget _buildDrawerOverlay(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: _closeDrawer,
      child: Container(
        color: AppColors.scrim,
        child: GestureDetector(
          onTap: () {}, // Prevent tap from closing when inside drawer
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: screenWidth,
              color: AppColors.bgTertiary,
              child: _buildDrawerContent(context),
            ),
          ),
        ),
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

    return Container(
      width: 72,
      color: AppColors.bgTertiary,
      child: Column(
        children: [
          const SizedBox(height: 12),
          // DM button
          _buildDiscordServerIcon(
            isSelected: selectedServerId == null,
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: AppColors.white,
              size: 24,
            ),
            onTap: () {
              ref.read(selectedServerIdProvider.notifier).state = null;
              ref.read(selectedServerNameProvider.notifier).state =
                  'Direct Messages';
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
                    return _buildDiscordServerIcon(
                      isSelected: isSelected,
                      hasUnread: _serverHasUnread(server.serverId),
                      child: server.iconUrl.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                server.iconUrl,
                                width: 28,
                                height: 28,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Text(
                                  server.name.isNotEmpty
                                      ? server.name[0].toUpperCase()
                                      : '?',
                                  style: AppTextStyles.headerSecondary.copyWith(
                                    fontSize: 16,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              server.name.isNotEmpty
                                  ? server.name[0].toUpperCase()
                                  : '?',
                              style: AppTextStyles.headerSecondary.copyWith(
                                fontSize: 16,
                                color: AppColors.white,
                              ),
                            ),
                      onTap: () {
                        ref.read(selectedServerIdProvider.notifier).state =
                            server.serverId;
                        ref.read(selectedServerNameProvider.notifier).state =
                            server.name;
                        // Load read status cho server khi chọn
                        ref
                            .read(unreadStatusNotifierProvider.notifier)
                            .loadReadStatusForServer(server.serverId);
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
          _buildDiscordServerIcon(
            isSelected: false,
            child: const Icon(Icons.add, color: AppColors.green, size: 24),
            onTap: () {
              _closeDrawer();
              showAddServerModal(context);
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// Discord-style server icon with left pill indicator
  Widget _buildDiscordServerIcon({
    required Widget child,
    required bool isSelected,
    required VoidCallback onTap,
    bool hasUnread = false,
  }) {
    // Discord-style: pill indicator height dựa trên selected/unread
    final double pillHeight;
    final Color pillColor;
    if (isSelected) {
      pillHeight = 36;
      pillColor = AppColors.white;
    } else if (hasUnread) {
      pillHeight = 8;
      pillColor = AppColors.white;
    } else {
      pillHeight = 0;
      pillColor = Colors.transparent;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Row(
          children: [
            // Left pill indicator (Discord style)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: pillHeight > 0 ? 4 : 0,
              height: pillHeight > 0 ? pillHeight : 0,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: pillColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Server icon circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brand : AppColors.bgPrimary,
                borderRadius: BorderRadius.circular(isSelected ? 16 : 24),
              ),
              alignment: Alignment.center,
              child: child,
            ),
          ],
        ),
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
          CurrentUserPanel(isMobile: true, onBeforeNavigate: _closeDrawer),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  DESKTOP LAYOUT
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        ServerListRail(onAddServer: () => showAddServerModal(context)),
        _buildChannelSidebar(context, ref),
        Expanded(child: _buildMainContent(ref)),
      ],
    );
  }

  /// Kiểm tra server có channel nào chưa đọc — cho server icon indicator
  /// Sử dụng reactive provider để tự cập nhật khi read status thay đổi
  bool _serverHasUnread(String serverId) {
    return ref.watch(serverHasUnreadProvider(serverId));
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
          const CurrentUserPanel(),
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
      serverChannelsStreamProvider(selectedServerId),
    );
    final selectedChannelId = ref.watch(selectedChannelIdProvider);

    return channelsState.when(
      data: (channels) {
        return FutureBuilder<List<ChannelEntity>>(
          future: _filterVisibleChannels(selectedServerId, channels),
          builder: (context, snapshot) {
            final visibleChannels = snapshot.data ?? channels;
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.brand,
                  strokeWidth: 2,
                ),
              );
            }
            if (visibleChannels.isEmpty) {
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
            final textChannels = visibleChannels
                .where((c) => c.type == ChannelType.text)
                .toList();
            final voiceChannels = visibleChannels
                .where((c) => c.type == ChannelType.voice)
                .toList();

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Kênh văn bản — luôn hiện header để tạo nhanh
                _buildCategoryHeader(
                  'KÊNH VĂN BẢN',
                  onAdd: () => _showQuickCreateChannel(
                    serverId: selectedServerId,
                    type: ChannelType.text,
                  ),
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
                      channel: channel,
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
                  onAdd: () => _showQuickCreateChannel(
                    serverId: selectedServerId,
                    type: ChannelType.voice,
                  ),
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
                      channel: channel,
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

  Future<List<ChannelEntity>> _filterVisibleChannels(
    String serverId,
    List<ChannelEntity> channels,
  ) async {
    final currentUser = ref.read(authNotifierProvider).user;
    if (currentUser == null) return [];

    final isOwner = ref.read(isServerOwnerProvider(serverId));
    if (isOwner) return channels;

    final memberDoc = await FirebaseFirestore.instance
        .collection('servers')
        .doc(serverId)
        .collection('members')
        .doc(currentUser.uid)
        .get();
    final roleIds = Set<String>.from(
      List<String>.from(memberDoc.data()?['roleIds'] as List? ?? []),
    );

    return channels.where((channel) {
      if (channel.allowedViewRoleIds.isEmpty) return true;
      return channel.allowedViewRoleIds.any(roleIds.contains);
    }).toList();
  }

  Widget _buildCategoryHeader(String name, {VoidCallback? onAdd}) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8, top: 16, bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(name, style: AppTextStyles.categoryHeader)),
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
    ChannelEntity? channel,
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
          onLongPress: channel == null
              ? null
              : () => _openChannelSettingsFromSidebar(channel),
          onSecondaryTap: channel == null
              ? null
              : () => _openChannelSettingsFromSidebar(channel),
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
          content: Text('Ban khong co quyen quan ly kenh nay'),
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
                  return Container(
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
      // Chưa chọn chat → hiện placeholder gợi ý
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 80),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.bgModifierHover,
                borderRadius: BorderRadius.circular(34),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: AppColors.channelDefault,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Tin nhắn trực tiếp', style: AppTextStyles.welcomeTitle),
            const SizedBox(height: 8),
            const Text(
              'Chọn một cuộc trò chuyện để bắt đầu.',
              style: AppTextStyles.welcomeSubtitle,
            ),
          ],
        ),
      );
    }

    // Chưa chọn kênh → welcome placeholder
    if (selectedChannelId == null || channelInfo == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 80),
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
            Text(
              'Chào mừng đến với $channelDisplayName!',
              style: AppTextStyles.welcomeTitle,
            ),
            const SizedBox(height: 8),
            Text(
              channelTopic.isNotEmpty
                  ? channelTopic
                  : 'Chọn một kênh để bắt đầu trò chuyện.',
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
