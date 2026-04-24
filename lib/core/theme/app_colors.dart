import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Background ───────────────────────────────────────────────
  static const Color bgPrimary = Color(0xFF313338);
  static const Color bgSecondary = Color(0xFF2B2D31);
  static const Color bgTertiary = Color(0xFF1E1F22);
  static const Color bgFloating = Color(0xFF2B2D31);
  static const Color bgModifierHover = Color(0xFF35373C);
  static const Color bgModifierSelected = Color(0xFF404249);
  static const Color bgModifierActive = Color(0xFF3F4147);
  static const Color bgAccent = Color(0xFF404249);

  // ── Brand ────────────────────────────────────────────────────
  static const Color brand = Color(0xFF5865F2);
  static const Color brandHover = Color(0xFF4752C4);
  static const Color brandActive = Color(0xFF3C45A5);

  // ── Status colors ────────────────────────────────────────────
  static const Color green = Color(0xFF23A559);
  static const Color yellow = Color(0xFFF0B232);
  static const Color red = Color(0xFFDA373C);
  static const Color blue = Color(0xFF00A8FC);

  // ── Text ─────────────────────────────────────────────────────
  static const Color textNormal = Color(0xFFDBDEE1);
  static const Color textMuted = Color(0xFF949BA4);
  static const Color textLink = Color(0xFF00A8FC);
  static const Color headerPrimary = Color(0xFFF2F3F5);
  static const Color headerSecondary = Color(0xFFB5BAC1);

  // ── Interactive ──────────────────────────────────────────────
  static const Color interactiveNormal = Color(0xFFB5BAC1);
  static const Color interactiveHover = Color(0xFFDBDEE1);
  static const Color interactiveActive = Color(0xFFFFFFFF);

  // ── Input ────────────────────────────────────────────────────
  static const Color inputBackground = Color(0xFF383A40);
  static const Color inputBorder = Color(0xFF4E5058);

  // ── Border / Divider ─────────────────────────────────────────
  static const Color border = Color(0xFF3F4147);
  static const Color divider = Color(0xFF3F4147);

  // ── Channel ──────────────────────────────────────────────────
  static const Color channelDefault = Color(0xFF80848E);

  // ── Monochrome ───────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // ── Overlay ──────────────────────────────────────────────────
  static const Color scrim = Color(0xB3000000); // 70% black

  // ── Presence status (chấm tròn nhỏ bên avatar) ──────────────
  static const Color statusOnline = Color(0xFF23A559);
  static const Color statusIdle = Color(0xFFF0B232);
  static const Color statusDnd = Color(0xFFDA373C);
  static const Color statusOffline = Color(0xFF80848E);
}
