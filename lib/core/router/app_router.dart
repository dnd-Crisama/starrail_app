import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';
import '../router/auth_refresh_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/logger.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/create_profile_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';

final _authRefreshNotifier = AuthRefreshNotifier();

final routerProvider = Provider<GoRouter>((ref) {
  ref.listen(authNotifierProvider, (previous, next) {
    Logger.info(
      'AuthNotifier changed -> HasUser: ${next.user != null}, NeedsProfile: ${next.needsProfileCreation}',
      tag: 'Router',
    );
    _authRefreshNotifier.notify();
  });

  return GoRouter(
    refreshListenable: _authRefreshNotifier,
    initialLocation: AppConstants.splashPath,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final currentPath = state.matchedLocation;

      // 1. Đang load dữ liệu ban đầu
      if (authState.isLoading) {
        return null; // Ở lại splash
      }

      // Dùng computed property 'isAuthenticated' để biết đã pass Auth chưa
      final isAuthenticated = authState.isAuthenticated;
      final needsProfile = authState.needsProfileCreation;

      final isAuthRoute =
          currentPath == AppConstants.loginPath ||
          currentPath == AppConstants.registerPath;
      final isProfileRoute = currentPath == AppConstants.createProfilePath;

      // 2. Đã xác thực + Cần tạo profile + Chưa ở trang tạo profile
      if (isAuthenticated && needsProfile && !isProfileRoute) {
        Logger.info('Redirecting to create profile', tag: 'Router');
        return AppConstants.createProfilePath;
      }

      // 3. Đã xác thực + Không cần tạo profile + Đang ở trang auth/profile
      if (isAuthenticated && !needsProfile && (isAuthRoute || isProfileRoute)) {
        Logger.info('Redirecting to home', tag: 'Router');
        return AppConstants.homePath;
      }

      // 4. Chưa xác thực + Đang ở trang được bảo vệ
      if (!isAuthenticated &&
          !isAuthRoute &&
          !isProfileRoute &&
          currentPath != AppConstants.splashPath) {
        Logger.info('Redirecting to login', tag: 'Router');
        return AppConstants.loginPath;
      }

      // 5. Chưa xác thực + Đang ở splash
      if (!isAuthenticated && currentPath == AppConstants.splashPath) {
        Logger.info('Redirecting to login from splash', tag: 'Router');
        return AppConstants.loginPath;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.splashPath,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.loginPath,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.registerPath,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppConstants.createProfilePath,
        builder: (_, __) => const CreateProfileScreen(),
      ),
      GoRoute(
        path: AppConstants.homePath,
        builder: (_, __) => const HomeScreen(),
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
              const Text('Page not found', style: AppTextStyles.headerPrimary),
              const SizedBox(height: 8),
              const Text(
                'The page you are looking for does not exist.',
                style: AppTextStyles.textMuted,
              ),
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
