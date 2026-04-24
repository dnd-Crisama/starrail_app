import 'package:flutter/foundation.dart';

/// ChangeNotifier làm cầu nối giữa Riverpod (auth state) và GoRouter.
///
/// GoRouter không biết về Riverpod. Nó chỉ biết Listenable.
/// Khi auth state thay đổi → notifier này gọi notifyListeners()
/// → GoRouter nhận tín hiệu → re-evaluate redirect.
///
/// Luồng:
/// FirebaseAuth.authStateChanges() emit
///   → Riverpod StreamProvider cập nhật state
///   → ref.listen callback chạy
///   → AuthRefreshNotifier.notifyListeners()
///   → GoRouter.refreshListenable nhận tín hiệu
///   → GoRouter gọi redirect() lại
///   → redirect() đọc authStateProvider (đã có giá trị mới)
///   → trả về route mới hoặc null
class AuthRefreshNotifier extends ChangeNotifier {
  /// Gọi khi auth state thay đổi, báo cho GoRouter re-evaluate redirect.
  void notify() {
    notifyListeners();
  }
}
