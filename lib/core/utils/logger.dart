import 'dart:developer' as developer;

/// Logger đơn giản cho toàn app.
/// Trong debug mode in ra console. Trong production có thể gửi lên Crashlytics.
class Logger {
  Logger._();

  static bool _isDebugMode() {
    bool inDebug = false;
    assert(inDebug = true);
    return inDebug;
  }

  /// Log mức info.
  static void info(String message, {String? tag}) {
    if (!_isDebugMode()) return;
    developer.log(
      'ℹ️ $message',
      name: tag ?? 'App',
      level: 800, // Level.INFO
    );
  }

  /// Log mức warning.
  static void warning(String message, {String? tag}) {
    if (!_isDebugMode()) return;
    developer.log(
      '⚠️ $message',
      name: tag ?? 'App',
      level: 900, // Level.WARNING
    );
  }

  /// Log mức error.
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    developer.log(
      '❌ $message',
      name: tag ?? 'App',
      level: 1000, // Level.SEVERE
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log mức debug (chỉ trong debug mode).
  static void debug(String message, {String? tag}) {
    if (!_isDebugMode()) return;
    developer.log(
      '🐛 $message',
      name: tag ?? 'App',
      level: 700, // Level.FINE
    );
  }
}
