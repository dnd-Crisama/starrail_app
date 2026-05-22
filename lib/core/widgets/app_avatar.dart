import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final String imageUrl;
  final String displayName;
  final double size;
  final Color backgroundColor;
  final TextStyle? textStyle;
  final Widget? fallbackIcon;
  final VoidCallback? onTap;
  final Border? border;

  const AppAvatar({
    super.key,
    required this.imageUrl,
    required this.displayName,
    this.size = 32,
    this.backgroundColor = AppColors.brand,
    this.textStyle,
    this.fallbackIcon,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final borderInset = border == null
        ? 0.0
        : border!.dimensions.horizontal / 2;
    final contentSize = math.max(0.0, size - borderInset * 2);
    final content = ClipOval(
      child: SizedBox(
        width: contentSize,
        height: contentSize,
        child: ColoredBox(
          color: backgroundColor,
          child: imageUrl.isNotEmpty
              ? _networkImage(context, contentSize)
              : _fallback(),
        ),
      ),
    );

    final avatar = border == null
        ? content
        : Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, border: border),
            padding: EdgeInsets.all(borderInset),
            child: content,
          );

    if (onTap == null) return avatar;

    return GestureDetector(onTap: onTap, child: avatar);
  }

  Widget _networkImage(BuildContext context, double displaySize) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final targetPixels = math.max(128, (displaySize * pixelRatio * 2).ceil());

    return Image.network(
      _cloudinaryAvatarUrl(imageUrl, targetPixels),
      width: displaySize,
      height: displaySize,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      gaplessPlayback: true,
      cacheWidth: targetPixels,
      cacheHeight: targetPixels,
      errorBuilder: (_, __, ___) => _fallback(),
      loadingBuilder: (_, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _loading();
      },
    );
  }

  Widget _fallback() {
    if (fallbackIcon != null) {
      return Center(child: fallbackIcon);
    }

    final initial = displayName.trim().isNotEmpty
        ? displayName.trim()[0].toUpperCase()
        : '?';

    return Center(
      child: Text(
        initial,
        style:
            textStyle ??
            TextStyle(
              color: AppColors.white,
              fontSize: size * 0.45,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _loading() {
    return Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: SizedBox(
        width: size * 0.38,
        height: size * 0.38,
        child: const CircularProgressIndicator(
          color: AppColors.white,
          strokeWidth: 1.5,
        ),
      ),
    );
  }

  static String _cloudinaryAvatarUrl(String url, int targetPixels) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.host.contains('cloudinary.com')) return url;

    const marker = '/upload/';
    if (!url.contains(marker)) return url;

    final width = math.max(128, math.min(512, targetPixels));
    final transform = 'f_auto,q_auto:best,c_fill,g_auto,w_$width,h_$width';
    return url.replaceFirst(marker, '$marker$transform/');
  }
}
