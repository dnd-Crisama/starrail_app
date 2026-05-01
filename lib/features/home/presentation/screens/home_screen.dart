import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/profile_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
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

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _buildServerList(ref),
        _buildChannelSidebar(context, ref),
        Expanded(child: _buildMainContent(ref)),
      ],
    );
  }

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
      drawer: Drawer(
        backgroundColor: AppColors.bgSecondary,
        child: Column(
          children: [
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
            // TRUYỀN CONTEXT VÀO ĐÂY
            _buildMobileUserPanel(context, ref),
          ],
        ),
      ),
      body: _buildMainContent(ref),
    );
  }

  // ── MOBILE USER PANEL ──────────────────────────────────────
  Widget _buildMobileUserPanel(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final displayName = user?.username ?? 'Unknown';
    final avatarUrl = user?.avatarUrl ?? '';

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
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            // SỬA Ở ĐÂY: Thêm backgroundImage: avatarUrl
            child: _buildUserAvatar(
              displayName: displayName,
              size: 32,
              backgroundImage: avatarUrl,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: Text(
                displayName,
                style: AppTextStyles.bodySecondary.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.headerPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
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

  // ── SERVER LIST ────────────────────────────────────────────
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

  // ── CHANNEL SIDEBAR ────────────────────────────────────────
  Widget _buildChannelSidebar(BuildContext context, WidgetRef ref) {
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
          // TRUYỀN CONTEXT VÀO ĐÂY
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
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildUserAvatar(
                  displayName: displayName,
                  size: 32,
                  backgroundImage: avatarUrl,
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF232428),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authNotifierProvider.notifier).logout();
              }
              if (value == 'profile') {
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

  // ── SHARED UI COMPONENTS ───────────────────────────────────
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
    String? backgroundImage,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.brand,
        shape: BoxShape.circle,
        image: backgroundImage != null && backgroundImage.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(backgroundImage),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: backgroundImage == null || backgroundImage.isEmpty
          ? Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
              style: TextStyle(
                color: AppColors.white,
                fontSize: size * 0.45,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
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

  String _mapStatusToString(UserStatus? status) {
    switch (status) {
      case UserStatus.online:
        return 'Trực tuyến';
      case UserStatus.idle:
        return 'Chờ đợi';
      case UserStatus.dnd:
        return 'Không làm phiền';
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
      default:
        return AppColors.statusOffline;
    }
  }
}
