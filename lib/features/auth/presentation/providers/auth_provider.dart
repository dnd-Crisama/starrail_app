import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/logger.dart';

/// Provider truy cập FirebaseAuth instance.

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// StreamProvider lắng nghe trạng thái xác thực real-time.
///
/// Đây là single source of truth cho auth state toàn app.
/// GoRouter đọc provider này để quyết định redirect.
/// UI đọc provider này để hiện/ẩn nút login/logout.
///
/// Luồng dữ liệu:
/// FirebaseAuth.instance.authStateChanges() [Firebase side]
///   → Stream<User?> [Dart stream]
///   → StreamProvider<User?> [Riverpod state]
///   → GoRouter redirect / UI rebuild
final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  Logger.info('Listening to auth state changes...', tag: 'AuthProvider');
  return auth.authStateChanges();
});

/// Provider đọc user hiện tại (không null).
/// Chỉ dùng khi chắc chắn user đã đăng nhập (trong Home screen, v.v.).
/// Nếu dùng ở nơi chưa chắc chắn, hãy dùng authStateProvider và kiểm tra null.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// Provider kiểm tra user đã đăng nhập chưa.
/// Trả về true nếu authStateProvider có user (không null và không loading).
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.hasValue && authState.value != null;
});
