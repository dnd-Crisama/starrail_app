import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root widget của ứng dụng.
/// ConsumerWidget để có thể đọc Riverpod providers.
/// MaterialApp.router dùng GoRouter để quản lý navigation.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch routerProvider — GoRouter sẽ tự rebuild khi auth state thay đổi
    // thông qua AuthRefreshNotifier.
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      routerConfig: router,
      title: 'StarRail',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Disable default animations cho navigation mượt hơn
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
