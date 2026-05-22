import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/domain/entities/user_entity.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/providers/profile_provider.dart';
import 'features/home/presentation/providers/home_provider.dart';
import 'features/message/presentation/providers/message_provider.dart';
import 'features/server/presentation/providers/server_provider.dart';

/// Thêm WidgetsBindingObserver để lắng nghe App chuyển nền/thoát
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final WidgetRef ref;
  _AppLifecycleObserver(this.ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Chỉ cập nhật status nếu user đã đăng nhập
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    // Không ghi đè trạng thái nếu người dùng đã chọn Vô hình hoặc Không làm phiền
    if (user.status == UserStatus.invisible || user.status == UserStatus.dnd) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        // App mở lên/focus -> Online
        ref
            .read(profileNotifierProvider.notifier)
            .updatePresenceStatus(UserStatus.online);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // Tab ra ngoài/mở app khác/bấm qua cửa sổ khác -> Idle
        ref
            .read(profileNotifierProvider.notifier)
            .updatePresenceStatus(UserStatus.idle);
        break;
      case AppLifecycleState.detached:
        // Đóng app hoàn toàn -> Offline
        ref
            .read(profileNotifierProvider.notifier)
            .updatePresenceStatus(UserStatus.offline);
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
  late final _AppLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    // Đăng ký observer
    _lifecycleObserver = _AppLifecycleObserver(ref);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      authNotifierProvider.select((state) => state.user?.uid),
      (previousUserId, nextUserId) {
        if (previousUserId == nextUserId) return;

        ref.read(selectedServerIdProvider.notifier).state = null;
        ref.read(selectedChannelIdProvider.notifier).state = null;
        ref.read(selectedServerNameProvider.notifier).state = 'Direct Messages';
        ref.read(selectedDmChatIdProvider.notifier).state = null;
        ref.read(isChannelSidebarOpenProvider.notifier).state = true;

        ref.invalidate(profileNotifierProvider);
        ref.invalidate(userServersStreamProvider);
        ref.invalidate(unreadStatusNotifierProvider);
      },
    );

    ref.listen(userServersStreamProvider, (previous, next) {
      next.whenData((servers) {
        final selectedServerId = ref.read(selectedServerIdProvider);
        if (selectedServerId == null) return;

        final canAccessSelectedServer = servers.any(
          (server) => server.serverId == selectedServerId,
        );
        if (canAccessSelectedServer) return;

        ref.read(selectedServerIdProvider.notifier).state = null;
        ref.read(selectedChannelIdProvider.notifier).state = null;
        ref.read(selectedServerNameProvider.notifier).state = 'Direct Messages';
      });
    });

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
