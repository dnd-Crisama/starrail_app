import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String _fontFamily = 'sans-serif';

  // ── Headers ──────────────────────────────────────────────────
  static const TextStyle headerPrimary = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.headerPrimary,
    height: 1.2,
  );

  static const TextStyle headerSecondary = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.headerSecondary,
    height: 1.2,
  );

  static const TextStyle header3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.headerPrimary,
    height: 1.2,
  );

  static const TextStyle header4 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.headerPrimary,
    height: 1.2,
    letterSpacing: 0.02,
  );

  // ── Body ─────────────────────────────────────────────────────
  static const TextStyle bodyPrimary = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textNormal,
    height: 1.375,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textNormal,
    height: 1.375,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textNormal,
    height: 1.375,
  );

  // ── Muted ────────────────────────────────────────────────────
  static const TextStyle textMuted = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.375,
  );

  static const TextStyle textMutedSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.375,
  );

  // ── Link ─────────────────────────────────────────────────────
  static const TextStyle textLink = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textLink,
    height: 1.375,
  );

  // ── Button ───────────────────────────────────────────────────
  static const TextStyle buttonText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
    height: 1.2,
  );

  static const TextStyle buttonTextSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
    height: 1.2,
  );

  // ── Channel name ─────────────────────────────────────────────
  static const TextStyle channelName = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.channelDefault,
    height: 1.2,
  );

  static const TextStyle channelNameSelected = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    height: 1.2,
  );

  // ── Category header ──────────────────────────────────────────
  static const TextStyle categoryHeader = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.channelDefault,
    height: 1.2,
    letterSpacing: 0.02,
  );

  // ── Server name ──────────────────────────────────────────────
  static const TextStyle serverName = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.headerPrimary,
    height: 1.2,
  );

  // ── Form ─────────────────────────────────────────────────────
  static const TextStyle inputText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textNormal,
    height: 1.375,
  );

  static const TextStyle inputHint = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.375,
  );

  static const TextStyle inputLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.headerSecondary,
    height: 1.2,
    letterSpacing: 0.01,
  );

  // ── Error ────────────────────────────────────────────────────
  static const TextStyle errorText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.red,
    height: 1.375,
  );

  // ── Welcome / Empty state ────────────────────────────────────
  static const TextStyle welcomeTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.headerPrimary,
    height: 1.2,
  );

  static const TextStyle welcomeSubtitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.375,
  );
}
