import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/logger.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController(); // Thêm trường username
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authNotifierProvider.notifier)
        .register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: _usernameController.text.trim(),
        );

    if (mounted) {
      final authState = ref.read(authNotifierProvider);
      if (authState.errorMessage != null) {
        setState(() => _errorMessage = authState.errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (prev, next) {
      if (mounted) {
        setState(() {
          _isLoading = next.isLoading;
        });
      }
    });

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

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.1),
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

                  const Text('EMAIL', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
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
                      if (!RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                      ).hasMatch(value.trim())) {
                        return 'Định dạng email không hợp lệ.';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _usernameFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: 16),

                  const Text('TÊN NGƯỜI DÙNG', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _usernameController,
                    focusNode: _usernameFocusNode,
                    textInputAction: TextInputAction.next,
                    style: AppTextStyles.inputText,
                    decoration: const InputDecoration(
                      hintText: 'NguyenVanA',
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tên người dùng.';
                      }
                      if (value.trim().length < 2) {
                        return 'Tên phải dài ít nhất 2 ký tự.';
                      }
                      if (value.trim().length >
                          AppConstants.maxUsernameLength) {
                        return 'Tên quá dài.';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                        return 'Chỉ chứa chữ cái, số và dấu gạch dưới (_).';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: 16),

                  const Text('MẬT KHẨU', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    style: AppTextStyles.inputText,
                    decoration: InputDecoration(
                      hintText: 'Mật khẩu',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
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
                      return null;
                    },
                    onFieldSubmitted: (_) =>
                        _confirmPasswordFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: 16),

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
                    style: AppTextStyles.inputText,
                    decoration: InputDecoration(
                      hintText: 'Nhập lại mật khẩu',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
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

                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        disabledBackgroundColor: AppColors.brand.withValues(
                          alpha: 0.6,
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Đã có tài khoản?',
                        style: AppTextStyles.textMuted,
                      ),
                      TextButton(
                        onPressed: () => context.go(AppConstants.loginPath),
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
