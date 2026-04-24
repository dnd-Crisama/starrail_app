import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';

class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  ConsumerState<CreateProfileScreen> createState() =>
      _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authNotifierProvider.notifier)
        .createProfile(username: _usernameController.text.trim());

    if (mounted) {
      final authState = ref.read(authNotifierProvider);
      if (authState.errorMessage != null) {
        setState(() => _errorMessage = authState.errorMessage);
      }
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
                children: [
                  Text(
                    'Tạo hồ sơ của bạn',
                    style: AppTextStyles.headerPrimary.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Hãy chọn một tên người dùng duy nhất.',
                    style: AppTextStyles.textMuted,
                  ),
                  const SizedBox(height: 24),

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

                  const Text('TÊN NGƯỜI DÙNG', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _usernameController,
                    style: AppTextStyles.inputText,
                    decoration: const InputDecoration(
                      hintText: 'NguyenVanA',
                      prefixText: '#', // Gợi ý Discord style
                      prefixStyle: AppTextStyles.textMuted,
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
                      // Regex chỉ cho phép chữ cái, số, underscore
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                        return 'Chỉ chứa chữ cái, số và dấu gạch dưới (_).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            )
                          : const Text('Tiếp tục'),
                    ),
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
