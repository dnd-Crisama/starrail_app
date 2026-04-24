import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/utils/logger.dart';

void main() async {
  // ── 1. Bind Flutter engine ──────────────────────────────────
  // Bắt buộc trước bất kỳ async operation nào.
  WidgetsFlutterBinding.ensureInitialized();

  // ── 2. Khởi tạo Firebase ────────────────────────────────────
  // firebase_options.dart được tạo bởi `flutterfire configure`.
  //  // Thay FirebaseOptions.currentPlatform bằng DefaultFirebaseOptions.currentPlatform
  // nếu dùng flutterfire_cli (file được generate tự động).
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Logger.info('Firebase initialized successfully', tag: 'Main');
  } catch (e, stackTrace) {
    Logger.error(
      'Failed to initialize Firebase: $e',
      error: e,
      stackTrace: stackTrace,
      tag: 'Main',
    );
    // Trong production có thể muốn exit app ở đây.
    // Nhưng trong dev, tiếp tục chạy để debug.
  }

  // ── 3. Chạy app ─────────────────────────────────────────────
  // ProviderScope bọc toàn app để Riverpod hoạt động.
  // observers: [] — có thể thêm Riverpod observer để log state changes khi debug.
  runApp(const ProviderScope(child: App()));
}
