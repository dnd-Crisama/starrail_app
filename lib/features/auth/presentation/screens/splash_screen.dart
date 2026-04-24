import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Màn hình splash hiển thị khi app khởi động và đang chờ auth state.
/// Thời gian hiển thị rất ngắn (< 1 giây), chỉ đủ để Firebase Auth
/// emit giá trị đầu tiên từ authStateChanges().
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTertiary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo placeholder
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(44),
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                color: AppColors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(AppConstants.appName, style: AppTextStyles.welcomeTitle),
            const SizedBox(height: 32),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.brand),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
