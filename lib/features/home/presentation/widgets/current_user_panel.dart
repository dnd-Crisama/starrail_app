import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/profile_provider.dart';
import '../../../auth/presentation/screens/profile_screen.dart';

class CurrentUserPanel extends ConsumerWidget {
  final bool isMobile;
  final VoidCallback? onBeforeNavigate;

  const CurrentUserPanel({
    super.key,
    this.isMobile = false,
    this.onBeforeNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileNotifierProvider);
    final user = profileState.user ?? ref.watch(authNotifierProvider).user;
    final displayName = user?.username ?? 'Unknown';
    final statusText = _mapStatusToString(user?.status);
    final statusColor = _getStatusColor(user?.status);
    final avatarUrl = user?.avatarUrl ?? '';

    return Container(
      height: isMobile ? null : 52,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: isMobile ? 6 : 0),
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
                onTap: () => _openProfile(context),
                child: _UserAvatar(
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
                    onTap: () =>
                        _showStatusPicker(dotContext, ref, user?.status),
                    child: _StatusDot(
                      color: statusColor,
                      status: user?.status,
                      isMobile: isMobile,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _openProfile(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
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
                      fontSize: isMobile ? 11 : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          _PanelIconButton(icon: Icons.mic_outlined, size: isMobile ? 32 : 28),
          _PanelIconButton(
            icon: Icons.headset_outlined,
            size: isMobile ? 32 : 28,
          ),
          SizedBox(
            width: isMobile ? 32 : 28,
            height: isMobile ? 32 : 28,
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.settings_rounded,
                color: AppColors.interactiveNormal,
                size: isMobile ? 18 : 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              color: AppColors.bgFloating,
              onSelected: (value) async {
                onBeforeNavigate?.call();
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
              itemBuilder: (context) => const [
                PopupMenuItem(
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
                PopupMenuDivider(),
                PopupMenuItem(
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

  void _openProfile(BuildContext context) {
    onBeforeNavigate?.call();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
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

  void _showStatusPicker(
    BuildContext dotContext,
    WidgetRef ref,
    UserStatus? currentStatus,
  ) {
    final dotBox = dotContext.findRenderObject() as RenderBox;
    final overlayBox =
        Overlay.of(dotContext).context.findRenderObject() as RenderBox;
    final dotPosition = dotBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final dotSize = dotBox.size;

    const estimatedPopupHeight = 180.0;
    const popupWidth = 220.0;

    var popupTop = dotPosition.dy - estimatedPopupHeight - 4;
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
        _statusMenuItem(
          status: UserStatus.online,
          label: 'Trực tuyến',
          color: AppColors.statusOnline,
          currentStatus: currentStatus,
        ),
        _statusMenuItem(
          status: UserStatus.idle,
          label: 'Chờ đợi',
          color: AppColors.statusIdle,
          currentStatus: currentStatus,
        ),
        _statusMenuItem(
          status: UserStatus.dnd,
          label: 'Không làm phiền',
          color: AppColors.statusDnd,
          currentStatus: currentStatus,
        ),
        _statusMenuItem(
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

  PopupMenuItem<UserStatus> _statusMenuItem({
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
}

class _PanelIconButton extends StatelessWidget {
  final IconData icon;
  final double size;

  const _PanelIconButton({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        icon: Icon(icon, color: AppColors.interactiveNormal, size: 18),
        onPressed: () {},
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String displayName;
  final double size;
  final String? backgroundImage;

  const _UserAvatar({
    required this.displayName,
    required this.size,
    this.backgroundImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.brand,
        shape: BoxShape.circle,
        image: backgroundImage != null && backgroundImage!.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(backgroundImage!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: backgroundImage == null || backgroundImage!.isEmpty
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
}

class _StatusDot extends StatelessWidget {
  final Color color;
  final UserStatus? status;
  final bool isMobile;

  const _StatusDot({
    required this.color,
    required this.status,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final isInvisible = status == UserStatus.invisible;

    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: isInvisible ? const Color(0xFF232428) : color,
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
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            )
          : null,
    );
  }
}
