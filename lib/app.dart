import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/entities/user_entity.dart';
import 'features/auth/presentation/providers/profile_provider.dart';

/// Thêm WidgetsBindingObserver để lắng nghe App chuyển nền/thoát
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final WidgetRef ref;
  _AppLifecycleObserver(this.ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Chỉ cập nhật status nếu user đã đăng nhập
    final user = ref.read(profileNotifierProvider).user;
    if (user == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        // App mở lên -> Online
        ref
            .read(profileNotifierProvider.notifier)
            .updatePresenceStatus(UserStatus.online);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App xuống nền/tắt -> Idle
        ref
            .read(profileNotifierProvider.notifier)
            .updatePresenceStatus(UserStatus.idle);
        break;
    }
  }
}

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Đăng ký observer
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(ref));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_AppLifecycleObserver(ref));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      routerConfig: router,
      title: 'StarRail',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) => child ?? const SizedBox.shrink(),
    );
  }
}
