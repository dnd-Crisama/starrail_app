import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthException;
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/logger.dart';

/// Màn hình đăng nhập.
///
///  gọi trực tiếp FirebaseAuth từ UI.
///
/// UI → AuthNotifier (Riverpod) → LoginUseCase → AuthRepository → AuthDatasource → FirebaseAuth.
///
/// Luồng hiện tại (Part 1):
/// User nhập email/password → bấm Login
///   → FirebaseAuth.signInWithEmailAndPassword()
///   → Thành công: auth state thay đổi → GoRouter redirect → /home
///   → Thất bại: hiển thị error message trong UI
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  /// Xử lý đăng nhập.
  /// Gọi trực tiếp FirebaseAuth
  Future<void> _handleLogin() async {
    // Ẩn error cũ
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Nếu thành công, auth state sẽ tự thay đổi.
      // GoRouter redirect sẽ xử lý navigation.
      // Không cần gọi context.go() thủ công.
      Logger.info('Login successful', tag: 'LoginScreen');
    } on FirebaseAuthException catch (e) {
      Logger.error(
        'Login failed: ${e.code} - ${e.message}',
        tag: 'LoginScreen',
      );
      setState(() {
        _errorMessage = _mapFirebaseAuthError(e.code);
      });
    } catch (e) {
      Logger.error('Unexpected login error: $e', tag: 'LoginScreen');
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

  /// Map Firebase Auth error code thành message tiếng Việt thân thiện.
  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
        return 'Mật khẩu không chính xác.';
      case 'invalid-email':
        return 'Định dạng email không hợp lệ.';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa.';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng thử lại sau.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không chính xác.';
      default:
        return 'Đăng nhập thất bại ($code). Vui lòng thử lại.';
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
                  // ── Logo ────────────────────────────────────
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: AppColors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Title ───────────────────────────────────
                  Text(
                    'Chào mừng trở lại!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headerPrimary.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chúng tôi rất vui được thấy bạn lại!',
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
                  const Text(
                    'EMAIL HOẶC SỐ ĐIỆN THOẠI',
                    style: AppTextStyles.inputLabel,
                  ),
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
                      // Basic email format check
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
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
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
                      return null;
                    },
                    onFieldSubmitted: (_) {
                      if (!_isLoading) _handleLogin();
                    },
                  ),
                  const SizedBox(height: 4),

                  // ── Forgot password link ────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Sẽ triển khai ở Part 2+
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tính năng sẽ được triển khai sau.'),
                          ),
                        );
                      },
                      child: const Text('Quên mật khẩu?'),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Login button ────────────────────────────
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
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
                          : const Text('Đăng nhập'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Register link ───────────────────────────
                  const Text(
                    'Cần một tài khoản?',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.textMuted,
                  ),
                  TextButton(
                    onPressed: () {
                      context.go(AppConstants.registerPath);
                    },
                    child: const Text('Đăng ký'),
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
