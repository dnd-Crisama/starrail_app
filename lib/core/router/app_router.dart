import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:starrail_app/core/constants/app_constants.dart';
import 'package:starrail_app/core/router/auth_refresh_notifier.dart';
import 'package:starrail_app/core/theme/app_colors.dart';
import 'package:starrail_app/core/theme/app_text_styles.dart';
import 'package:starrail_app/core/utils/logger.dart';

import 'package:starrail_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:starrail_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:starrail_app/features/auth/presentation/screens/login_screen.dart';
import 'package:starrail_app/features/auth/presentation/screens/register_screen.dart';
import 'package:starrail_app/features/home/presentation/screens/home_screen.dart';

/// Notifier instance dùng làm bridge cho GoRouter.
final _authRefreshNotifier = AuthRefreshNotifier();

/// Provider tạo và quản lý GoRouter instance.
final routerProvider = Provider<GoRouter>((ref) {
  ref.listen(authStateProvider, (previous, next) {
    Logger.info(
      'Auth state changed: ${previous?.value?.uid} -> ${next.value?.uid}',
      tag: 'Router',
    );
    _authRefreshNotifier.notify();
  });

  return GoRouter(
    refreshListenable: _authRefreshNotifier,
    initialLocation: AppConstants.splashPath,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);

      if (authAsync.isLoading) {
        Logger.debug(
          'Auth loading, staying on ${state.matchedLocation}',
          tag: 'Router',
        );
        return null;
      }

      final isLoggedIn = authAsync.hasValue && authAsync.value != null;
      final currentPath = state.matchedLocation;
      final isAuthRoute =
          currentPath == AppConstants.loginPath ||
          currentPath == AppConstants.registerPath;
      final isSplashRoute = currentPath == AppConstants.splashPath;

      Logger.debug(
        'Redirect check: path=$currentPath, isLoggedIn=$isLoggedIn, isAuthRoute=$isAuthRoute',
        tag: 'Router',
      );

      if (isLoggedIn && (isSplashRoute || isAuthRoute)) {
        Logger.info('Redirecting to home', tag: 'Router');
        return AppConstants.homePath;
      }

      if (!isLoggedIn && !isAuthRoute && !isSplashRoute) {
        Logger.info('Redirecting to login', tag: 'Router');
        return AppConstants.loginPath;
      }

      if (!isLoggedIn && isSplashRoute) {
        Logger.info('Redirecting to login from splash', tag: 'Router');
        return AppConstants.loginPath;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.splashPath,
        builder: (context, state) {
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: AppConstants.loginPath,
        builder: (context, state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: AppConstants.registerPath,
        builder: (context, state) {
          return const RegisterScreen();
        },
      ),
      GoRoute(
        path: AppConstants.homePath,
        builder: (context, state) {
          return const HomeScreen();
        },
      ),
    ],
    errorBuilder: (context, state) {
      Logger.error('Route not found: ${state.matchedLocation}', tag: 'Router');
      return Scaffold(
        backgroundColor: AppColors.bgTertiary,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.red, size: 48),
              const SizedBox(height: 16),
              Text('Page not found', style: AppTextStyles.headerPrimary),
              const SizedBox(height: 8),
              Text(state.matchedLocation, style: AppTextStyles.textMuted),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppConstants.homePath),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    },
  );
});
