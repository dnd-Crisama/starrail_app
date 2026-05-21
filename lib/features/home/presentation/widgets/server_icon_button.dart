import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

enum ServerIconIndicatorStyle { none, bottomDot, sidePill }

class ServerIconButton extends StatelessWidget {
  static const double defaultSize = 48;
  static const double defaultRadius = 14;

  final Widget child;
  final VoidCallback onTap;
  final bool isSelected;
  final bool hasUnread;
  final ServerIconIndicatorStyle indicatorStyle;
  final double bottomPadding;
  final double size;
  final double radius;

  const ServerIconButton({
    super.key,
    required this.child,
    required this.onTap,
    this.isSelected = false,
    this.hasUnread = false,
    this.indicatorStyle = ServerIconIndicatorStyle.none,
    this.bottomPadding = 8,
    this.size = defaultSize,
    this.radius = defaultRadius,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _buildIcon();
    final minWidth =
        indicatorStyle == ServerIconIndicatorStyle.sidePill ? size + 8 : size;
    final minHeight =
        indicatorStyle == ServerIconIndicatorStyle.bottomDot && hasUnread
            ? size + 12
            : size;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth,
          minHeight: minHeight,
        ),
        child: switch (indicatorStyle) {
          ServerIconIndicatorStyle.sidePill => _buildSidePill(icon),
          ServerIconIndicatorStyle.bottomDot => _buildBottomDot(icon),
          ServerIconIndicatorStyle.none => icon,
        },
      ),
    );
  }

  Widget _buildIcon() {
    return Material(
      color: isSelected ? AppColors.brand : AppColors.bgPrimary,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomDot(Widget icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        if (hasUnread) ...[
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
    );
  }

  Widget _buildSidePill(Widget icon) {
    final double pillHeight;
    if (isSelected) {
      pillHeight = 36;
    } else if (hasUnread) {
      pillHeight = 8;
    } else {
      pillHeight = 0;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: pillHeight > 0 ? 4 : 0,
          height: pillHeight > 0 ? pillHeight : 0,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: pillHeight > 0 ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        icon,
      ],
    );
  }
}

class ServerIconInitial extends StatelessWidget {
  final String name;
  final double fontSize;

  const ServerIconInitial({
    super.key,
    required this.name,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: AppTextStyles.headerSecondary.copyWith(
        fontSize: fontSize,
        color: AppColors.white,
      ),
    );
  }
}
