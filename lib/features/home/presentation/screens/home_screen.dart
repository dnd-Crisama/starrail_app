import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppConstants.mobileBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: isMobile
            ? _buildMobileLayout(context, ref)
            : _buildDesktopLayout(context, ref),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // DESKTOP LAYOUT (3 cột)
  // ────────────────────────────────────────────────────────────
  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _buildServerList(ref),
        _buildChannelSidebar(ref),
        Expanded(child: _buildMainContent(ref)),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────
  // MOBILE LAYOUT (App Bar + Drawer)
  // ────────────────────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgTertiary,
        elevation: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: AppColors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: Text(
          ref.watch(selectedServerNameProvider),
          style: AppTextStyles.serverName,
        ),
      ),
      // DRAWER CHO MOBILE: Chứa Channel List VÀ User Panel (có Logout)
      drawer: Drawer(
        backgroundColor: AppColors.bgSecondary,
        child: Column(
          children: [
            // Header
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

            // Channel list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildCategoryHeader('TEXT CHANNELS'),
                  _buildChannelItem(
                    name: 'general',
                    isSelected: true,
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildChannelItem(
                    name: 'random',
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // USER PANEL CHO MOBILE (Nằm cố định ở cuối Drawer)
            _buildMobileUserPanel(ref),
          ],
        ),
      ),
      body: _buildMainContent(ref),
    );
  }

  // ────────────────────────────────────────────────────────────
  // USER PANEL CHO MOBILE (Rộng rãi, dễ bấm)
  // ────────────────────────────────────────────────────────────
  Widget _buildMobileUserPanel(WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final displayName = user?.username ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF232428),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
      child: Row(
        children: [
          _buildUserAvatar(displayName: displayName, size: 32),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayName,
              style: AppTextStyles.bodySecondary.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.headerPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Nút Logout rõ ràng trên Mobile
          TextButton.icon(
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
            icon: const Icon(Icons.logout, color: AppColors.red, size: 18),
            label: const Text(
              'Thoát',
              style: TextStyle(color: AppColors.red, fontSize: 14),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // SERVER LIST (Cột trái - desktop)
  // ────────────────────────────────────────────────────────────
  Widget _buildServerList(WidgetRef ref) {
    return Container(
      width: AppConstants.serverListWidth,
      color: AppColors.bgTertiary,
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildServerIconButton(
            isSelected: true,
            tooltip: 'Direct Messages',
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: AppColors.white,
              size: 28,
            ),
            onTap: () {},
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
            onTap: () => ref.read(selectedServerNameProvider.notifier).state =
                'My Server',
          ),
          const Spacer(),
          _buildServerIconButton(
            tooltip: 'Thêm server',
            child: const Icon(Icons.add, color: AppColors.green, size: 20),
            onTap: () {},
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

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
          // Dùng InkWell thay GestureDetector để có hiệu ứng splash chuẩn
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

  // ────────────────────────────────────────────────────────────
  // CHANNEL SIDEBAR (Cột giữa - desktop)
  // ────────────────────────────────────────────────────────────
  Widget _buildChannelSidebar(WidgetRef ref) {
    final serverName = ref.watch(selectedServerNameProvider);
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
                const Icon(
                  Icons.expand_more,
                  color: AppColors.interactiveNormal,
                  size: 18,
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              children: [
                _buildCategoryHeader('TEXT CHANNELS'),
                _buildChannelItem(
                  name: 'general',
                  isSelected: true,
                  onTap: () =>
                      ref.read(selectedChannelIdProvider.notifier).state =
                          'general',
                ),
                _buildChannelItem(
                  name: 'random',
                  onTap: () =>
                      ref.read(selectedChannelIdProvider.notifier).state =
                          'random',
                ),
                const SizedBox(height: 16),
                _buildCategoryHeader('VOICE CHANNELS'),
                _buildChannelItem(
                  name: 'General Voice',
                  isVoice: true,
                  onTap: () {},
                ),
              ],
            ),
          ),

          // USER PANEL CHO DESKTOP
          _buildDesktopUserPanel(ref),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  // USER PANEL CHO DESKTOP (Dùng PopupMenuButton thay Tooltip)
  // ────────────────────────────────────────────────────────────
  Widget _buildDesktopUserPanel(WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final displayName = user?.username ?? 'Unknown';
    final statusText = user?.status == UserStatus.online
        ? 'Trực tuyến'
        : 'Ngoại tuyến';

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
          _buildUserAvatar(displayName: displayName, size: 32),
          const SizedBox(width: 8),
          // Cho phép truncate text nếu sidebar bị co lại cực nhỏ
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
                Text(
                  statusText,
                  style: AppTextStyles.textMutedSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Dùng SizedBox cố định để vùng bấm không bị mất khi resize
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

          // THAY THẾ TOOLTIP BẰNG POPUP MENU CHO DESKTOP
          // Vừa đẹp, vừa không bị mất khi resize, vừa rõ ràng chức năng
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
            elevation: 2,
            position: PopupMenuPosition.over,
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authNotifierProvider.notifier).logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(
                      Icons.settings,
                      color: AppColors.interactiveNormal,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text('Cài đặt', style: AppTextStyles.bodySecondary),
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

  // ────────────────────────────────────────────────────────────
  // SHARED UI COMPONENTS
  // ────────────────────────────────────────────────────────────

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

  Widget _buildMainContent(WidgetRef ref) {
    final selectedChannel = ref.watch(selectedChannelIdProvider) ?? 'general';
    return Column(
      children: [
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
              // Search box ẩn trên mobile nếu quá nhỏ
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 400)
                    return const SizedBox.shrink();
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
        Expanded(
          child: Center(
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
                  'Chào mừng đến với #$selectedChannel!',
                  style: AppTextStyles.welcomeTitle,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Đây là nơi bắt đầu của kênh.',
                  style: AppTextStyles.welcomeSubtitle,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
