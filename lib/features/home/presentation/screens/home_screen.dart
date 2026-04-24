import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/logger.dart';
import '../providers/home_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// App Shell — bố cục chính giống Discord.
///
/// Bố cục 3 cột:
/// ┌──────────┬───────────────┬────────────────────────┐
/// │  Server  │   Channel     │    Main Content Area    │
/// │  List    │   Sidebar     │    (Chat / Voice)       │
/// │  (72px)  │   (240px)     │    (Expanded)           │
/// └──────────┴───────────────┴────────────────────────┘
///
/// tất cả nội dung đều là placeholder.
/// Server icons, channel list, messages — đều static.

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppConstants.mobileBreakpoint;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: isMobile
            ? _buildMobileLayout(context, ref, user)
            : _buildDesktopLayout(context, ref, user),
      ),
    );
  }

  /// Layout desktop: 3 cột đầy đủ.
  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref, User? user) {
    return Row(
      children: [
        // ── Cột 1: Server List ─────────────────────────────
        _buildServerList(ref),

        // ── Cột 2: Channel Sidebar ────────────────────────
        _buildChannelSidebar(ref),

        // ── Cột 3: Main Content ───────────────────────────
        Expanded(child: _buildMainContent(ref, user)),
      ],
    );
  }

  /// Layout mobile: chỉ hiện main content với drawer cho sidebar.
  Widget _buildMobileLayout(BuildContext context, WidgetRef ref, User? user) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgTertiary,
        elevation: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: AppColors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Text(
          ref.watch(selectedServerNameProvider),
          style: AppTextStyles.serverName,
        ),
      ),
      drawer: Drawer(
        backgroundColor: AppColors.bgSecondary,
        child: Column(
          children: [
            // Server name header
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      ref.watch(selectedServerNameProvider),
                      style: AppTextStyles.serverName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.expand_more,
                    color: AppColors.interactiveNormal,
                    size: 18,
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.divider, height: 1),
            // Channel list placeholder
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildCategoryHeader('TEXT CHANNELS'),
                  _buildChannelItem(
                    name: 'general',
                    isSelected: true,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildChannelItem(
                    name: 'random',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _buildMainContent(ref, user),
    );
  }

  /// Server list — cột trái cùng, chứa icon các server.
  Widget _buildServerList(WidgetRef ref) {
    return Container(
      width: AppConstants.serverListWidth,
      color: AppColors.bgTertiary,
      child: Column(
        children: [
          const SizedBox(height: 12),

          // ── Home / DM button ────────────────────────────
          _buildServerIconButton(
            isSelected: true,
            tooltip: 'Direct Messages',
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: AppColors.white,
              size: 28,
            ),
            onTap: () {
              Logger.debug('Home/DM tapped', tag: 'HomeScreen');
            },
          ),

          const SizedBox(height: 8),

          // ── Separator ────────────────────────────────────
          Container(
            width: 32,
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(1),
            ),
          ),

          const SizedBox(height: 8),

          // ── Server icons (placeholder) ───────────────────
          _buildServerIconButton(
            tooltip: 'My Server',
            child: Text(
              'M',
              style: AppTextStyles.headerSecondary.copyWith(
                fontSize: 18,
                color: AppColors.white,
              ),
            ),
            isSelected: true,
            hasIndicator: true,
            onTap: () {
              ref.read(selectedServerNameProvider.notifier).state = 'My Server';
            },
          ),

          _buildServerIconButton(
            tooltip: 'Gaming Hub',
            child: Text(
              'G',
              style: AppTextStyles.headerSecondary.copyWith(
                fontSize: 18,
                color: AppColors.white,
              ),
            ),
            onTap: () {
              ref.read(selectedServerNameProvider.notifier).state =
                  'Gaming Hub';
            },
          ),

          _buildServerIconButton(
            tooltip: 'Study Group',
            child: Text(
              'S',
              style: AppTextStyles.headerSecondary.copyWith(
                fontSize: 18,
                color: AppColors.white,
              ),
            ),
            onTap: () {
              ref.read(selectedServerNameProvider.notifier).state =
                  'Study Group';
            },
          ),

          const Spacer(),

          // ── Add server button ────────────────────────────
          _buildServerIconButton(
            tooltip: 'Thêm server',
            child: const Icon(Icons.add, color: AppColors.green, size: 20),
            onTap: () {
              Logger.debug('Add server tapped', tag: 'HomeScreen');
              // Sẽ triển khai ở Part 4
            },
          ),

          // ── Explore button ───────────────────────────────
          _buildServerIconButton(
            tooltip: 'Khám phá',
            child: const Icon(
              Icons.compass_calibration_outlined,
              color: AppColors.green,
              size: 20,
            ),
            onTap: () {
              Logger.debug('Explore tapped', tag: 'HomeScreen');
            },
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// Widget tạo một server icon button tròn.
  Widget _buildServerIconButton({
    required Widget child,
    required VoidCallback onTap,
    String? tooltip,
    bool isSelected = false,
    bool hasIndicator = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Tooltip(
            message: tooltip ?? '',
            preferBelow: false,
            child: GestureDetector(
              onTap: onTap,
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

  /// Channel sidebar — cột thứ hai, chứa danh sách channel.
  Widget _buildChannelSidebar(WidgetRef ref) {
    final serverName = ref.watch(selectedServerNameProvider);

    return Container(
      width: AppConstants.channelSidebarWidth,
      color: AppColors.bgSecondary,
      child: Column(
        children: [
          // ── Server name header ───────────────────────────
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
                const Icon(
                  Icons.expand_more,
                  color: AppColors.interactiveNormal,
                  size: 18,
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.divider, height: 1),

          // ── Channel list ─────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              children: [
                // Text channels
                _buildCategoryHeader('TEXT CHANNELS'),
                _buildChannelItem(
                  name: 'general',
                  isSelected: true,
                  onTap: () {
                    ref.read(selectedChannelIdProvider.notifier).state =
                        'general';
                  },
                ),
                _buildChannelItem(
                  name: 'random',
                  onTap: () {
                    ref.read(selectedChannelIdProvider.notifier).state =
                        'random';
                  },
                ),
                _buildChannelItem(
                  name: 'music',
                  onTap: () {
                    ref.read(selectedChannelIdProvider.notifier).state =
                        'music';
                  },
                ),
                _buildChannelItem(
                  name: 'memes',
                  onTap: () {
                    ref.read(selectedChannelIdProvider.notifier).state =
                        'memes';
                  },
                ),

                const SizedBox(height: 16),

                // Voice channels
                _buildCategoryHeader('VOICE CHANNELS'),
                _buildChannelItem(
                  name: 'General Voice',
                  isVoice: true,
                  onTap: () {
                    Logger.debug('Voice channel tapped', tag: 'HomeScreen');
                  },
                ),
                _buildChannelItem(
                  name: 'Gaming',
                  isVoice: true,
                  onTap: () {
                    Logger.debug('Voice channel tapped', tag: 'HomeScreen');
                  },
                ),
              ],
            ),
          ),

          // ── User panel (bottom) ──────────────────────────
          _buildUserPanel(ref),
        ],
      ),
    );
  }

  /// Widget tạo category header (vd: "TEXT CHANNELS").
  Widget _buildCategoryHeader(String name) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8, top: 16, bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(name, style: AppTextStyles.categoryHeader)),
          const Icon(Icons.add, color: AppColors.channelDefault, size: 16),
        ],
      ),
    );
  }

  /// Widget tạo channel item trong sidebar.
  Widget _buildChannelItem({
    required String name,
    bool isSelected = false,
    bool isVoice = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: isSelected
            ? AppColors.bgModifierSelected
            : AppColors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Icon(
                  isVoice ? Icons.volume_up_outlined : Icons.tag,
                  color: isSelected
                      ? AppColors.channelDefault
                      : AppColors.channelDefault.withOpacity(0.6),
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    name,
                    style: isSelected
                        ? AppTextStyles.channelNameSelected
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

  /// User panel ở bottom của channel sidebar.
  Widget _buildUserPanel(WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final displayName = user?.displayName ?? user?.email ?? 'Unknown';
    final email = user?.email ?? '';

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
          // Avatar
          _buildUserAvatar(displayName: displayName, size: 32),
          const SizedBox(width: 8),

          // Username & status
          Expanded(
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
                const Text(
                  'Trực tuyến',
                  style: AppTextStyles.textMutedSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Action icons
          IconButton(
            icon: const Icon(
              Icons.mic_outlined,
              color: AppColors.interactiveNormal,
              size: 20,
            ),
            onPressed: () {
              Logger.debug('Mic toggle', tag: 'HomeScreen');
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: const Icon(
              Icons.headset_outlined,
              color: AppColors.interactiveNormal,
              size: 20,
            ),
            onPressed: () {
              Logger.debug('Headset toggle', tag: 'HomeScreen');
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: const Icon(
              Icons.settings_rounded,
              color: AppColors.interactiveNormal,
              size: 20,
            ),
            onPressed: () {
              Logger.debug('Settings tapped', tag: 'HomeScreen');
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  /// Widget tạo avatar tròn với chữ cái đầu.
  Widget _buildUserAvatar({
    required String displayName,
    double size = 32,
    Color? backgroundColor,
  }) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.brand,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.white,
          fontSize: size * 0.45,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Main content area — header bar + content.
  Widget _buildMainContent(WidgetRef ref, User? user) {
    final selectedChannel = ref.watch(selectedChannelIdProvider) ?? 'general';

    return Column(
      children: [
        // ── Channel header bar ────────────────────────────
        Container(
          height: AppConstants.channelHeaderHeight,
          color: AppColors.bgSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.tag, color: AppColors.channelDefault, size: 20),
              const SizedBox(width: 8),
              Text(selectedChannel, style: AppTextStyles.headerSecondary),
              const Spacer(),
              // Header actions (placeholder)
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_outlined,
                  color: AppColors.interactiveNormal,
                  size: 22,
                ),
                onPressed: () {
                  Logger.debug('Notifications tapped', tag: 'HomeScreen');
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const Icon(
                  Icons.push_pin_outlined,
                  color: AppColors.interactiveNormal,
                  size: 22,
                ),
                onPressed: () {
                  Logger.debug('Pinned messages tapped', tag: 'HomeScreen');
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const Icon(
                  Icons.people_alt_outlined,
                  color: AppColors.interactiveNormal,
                  size: 22,
                ),
                onPressed: () {
                  Logger.debug('Member list toggled', tag: 'HomeScreen');
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              const SizedBox(width: 4),
              // Search box placeholder
              Container(
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
                    Icon(Icons.search, color: AppColors.textMuted, size: 14),
                    SizedBox(width: 4),
                    Text('Tìm kiếm', style: AppTextStyles.textMutedSmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.inbox_outlined,
                  color: AppColors.interactiveNormal,
                  size: 22,
                ),
                onPressed: () {
                  Logger.debug('Inbox tapped', tag: 'HomeScreen');
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),

        const Divider(color: AppColors.divider, height: 1),

        // ── Content area ──────────────────────────────────
        Expanded(
          child: Row(
            children: [
              // Messages area
              Expanded(child: _buildEmptyChannelState(selectedChannel)),
            ],
          ),
        ),
      ],
    );
  }

  /// Empty state khi channel chưa có tin nhắn.
  Widget _buildEmptyChannelState(String channelName) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
              'Chào mừng đến với #$channelName!',
              style: AppTextStyles.welcomeTitle,
            ),
            const SizedBox(height: 8),
            Text(
              'Đây là nơi bắt đầu của kênh #$channelName.',
              style: AppTextStyles.welcomeSubtitle,
            ),
            const SizedBox(height: 48),

            // ── Placeholder messages ─────────────────────
            _buildPlaceholderMessage(
              avatarText: 'D',
              avatarColor: AppColors.green,
              username: 'StarRail Bot',
              time: 'Hôm nay lúc 00:00',
              content: 'Đây là kênh #$channelName. Bắt đầu trò chuyện nào!',
            ),
            const SizedBox(height: 16),
            _buildPlaceholderMessage(
              avatarText: 'D',
              avatarColor: AppColors.green,
              username: 'StarRail Bot',
              time: 'Hôm nay lúc 00:00',
              content:
                  'Mẹo: Bạn có thể @mention người khác, gửi emoji, upload file và nhiều hơn nữa trong các bản cập nhật tiếp theo.',
            ),
          ],
        ),
      ),
    );
  }

  /// Placeholder message bubble.
  Widget _buildPlaceholderMessage({
    required String avatarText,
    required Color avatarColor,
    required String username,
    required String time,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: avatarColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              avatarText,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Message content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      username,
                      style: AppTextStyles.bodySecondary.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.headerPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(time, style: AppTextStyles.textMutedSmall),
                  ],
                ),
                const SizedBox(height: 4),
                Text(content, style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
