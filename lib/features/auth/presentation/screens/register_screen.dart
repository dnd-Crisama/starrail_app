import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthException;
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/logger.dart';

/// Màn hình đăng ký.
///
/// Tương tự LoginScreen, gọi trực tiếp FirebaseAuth trong Part 1.
/// Từ Part 2, sẽ refactor theo Clean Architecture.
///
/// Luồng hiện tại (Part 1):
/// User nhập email + password + confirm password → bấm Đăng ký
///   → Validate input (email format, password length, password match)
///   → FirebaseAuth.createUserWithEmailAndPassword()
///   → Thành công: auth state thay đổi → GoRouter redirect → /home
///   → Thất bại: hiển thị error message trong UI
///
/// Lưu ý: Part 1 chỉ tạo Firebase Auth user.
/// User profile document trong Firestore sẽ được tạo ở Part 2.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  /// Xử lý đăng ký.
  Future<void> _handleRegister() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Auth state tự thay đổi → GoRouter tự redirect.
      Logger.info('Registration successful', tag: 'RegisterScreen');
    } on FirebaseAuthException catch (e) {
      Logger.error(
        'Registration failed: ${e.code} - ${e.message}',
        tag: 'RegisterScreen',
      );
      setState(() {
        _errorMessage = _mapFirebaseAuthError(e.code);
      });
    } catch (e) {
      Logger.error('Unexpected register error: $e', tag: 'RegisterScreen');
      setState(() {
        _errorMessage = 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email này đã được đăng ký. Hãy dùng email khác hoặc đăng nhập.';
      case 'invalid-email':
        return 'Định dạng email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Cần ít nhất ${AppConstants.minPasswordLength} ký tự.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng thử lại sau.';
      case 'operation-not-allowed':
        return 'Phương thức đăng ký này không được bật. Liên hệ admin.';
      default:
        return 'Đăng ký thất bại ($code). Vui lòng thử lại.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: 480,
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.bgFloating,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Title ───────────────────────────────────
                  Text(
                    'Tạo một tài khoản',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headerPrimary.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hãy đăng ký để bắt đầu!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.textMuted,
                  ),
                  const SizedBox(height: 20),

                  // ── Error message ───────────────────────────
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.red),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.errorText,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Email field ─────────────────────────────
                  const Text('EMAIL', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    style: AppTextStyles.inputText,
                    decoration: const InputDecoration(
                      hintText: 'email@example.com',
                      prefixIcon: Icon(
                        Icons.mail_outline,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập email.';
                      }
                      final emailRegex = RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                      );
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Định dạng email không hợp lệ.';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) {
                      _passwordFocusNode.requestFocus();
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Password field ──────────────────────────
                  const Text('MẬT KHẨU', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    style: AppTextStyles.inputText,
                    decoration: InputDecoration(
                      hintText: 'Mật khẩu',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu.';
                      }
                      if (value.length < AppConstants.minPasswordLength) {
                        return 'Mật khẩu cần ít nhất ${AppConstants.minPasswordLength} ký tự.';
                      }
                      if (value.length > AppConstants.maxPasswordLength) {
                        return 'Mật khẩu không quá ${AppConstants.maxPasswordLength} ký tự.';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) {
                      _confirmPasswordFocusNode.requestFocus();
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Confirm Password field ──────────────────
                  const Text(
                    'XÁC NHẬN MẬT KHẨU',
                    style: AppTextStyles.inputLabel,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocusNode,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    style: AppTextStyles.inputText,
                    decoration: InputDecoration(
                      hintText: 'Nhập lại mật khẩu',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        child: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng xác nhận mật khẩu.';
                      }
                      if (value != _passwordController.text) {
                        return 'Mật khẩu xác nhận không khớp.';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) {
                      if (!_isLoading) _handleRegister();
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Register button ─────────────────────────
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        disabledBackgroundColor: AppColors.brand.withOpacity(
                          0.6,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white,
                                ),
                              ),
                            )
                          : const Text('Tiếp tục'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Login link ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Đã có tài khoản?',
                        style: AppTextStyles.textMuted,
                      ),
                      TextButton(
                        onPressed: () {
                          context.go(AppConstants.loginPath);
                        },
                        child: const Text('Đăng nhập'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
