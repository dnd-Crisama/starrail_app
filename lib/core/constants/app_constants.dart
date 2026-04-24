/// Các hằng số dùng chung toàn ứng dụng.
class AppConstants {
  AppConstants._();

  static const String appName = 'StarRail';
  static const String appVersion = '1.0.0';

  // ── Route paths ──────────────────────────────────────────────
  static const String splashPath = '/';
  static const String loginPath = '/login';
  static const String registerPath = '/register';
  static const String homePath = '/home';

  // ── UI dimensions ────────────────────────────────────────────
  /// Chiều rộng server list (cột trái cùng)
  static const double serverListWidth = 72.0;

  /// Chiều rộng channel sidebar (cột thứ hai)
  static const double channelSidebarWidth = 240.0;

  /// Chiều cao header bar của channel
  static const double channelHeaderHeight = 48.0;

  /// Breakpoint để chuyển sang layout mobile
  static const double mobileBreakpoint = 768.0;

  // ── Validation ───────────────────────────────────────────────
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxUsernameLength = 32;

  // ── Firebase collection names  ──
  static const String usersCollection = 'users';
  static const String serversCollection = 'servers';
}
