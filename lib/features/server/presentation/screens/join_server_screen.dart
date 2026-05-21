// lib/features/server/presentation/screens/join_server_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/server_provider.dart';

class JoinServerScreen extends ConsumerStatefulWidget {
  const JoinServerScreen({super.key});

  @override
  ConsumerState<JoinServerScreen> createState() => _JoinServerScreenState();
}

class _JoinServerScreenState extends ConsumerState<JoinServerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inviteCodeController = TextEditingController();

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(joinServerNotifierProvider.notifier)
        .joinServer(
          inviteCode: _inviteCodeController.text.trim().toUpperCase(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final joinState = ref.watch(joinServerNotifierProvider);

    ref.listen(joinServerNotifierProvider, (prev, next) {
      if (prev?.joinedServer == null &&
          next.joinedServer != null &&
          next.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tham gia Server thành công!'),
            backgroundColor: AppColors.green,
          ),
        );
        context.pop();
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.red,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        title: const Text('Tham gia Server'),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 480,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tham gia Server',
                    style: AppTextStyles.headerPrimary.copyWith(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nhập mã mời để tham gia một server.',
                    style: AppTextStyles.textMuted,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const Text('MÃ MỜI', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _inviteCodeController,
                    style: AppTextStyles.inputText,
                    decoration: const InputDecoration(hintText: 'ABC123'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Invite code is required.';
                      }
                      if (value.trim().length != 6) {
                        return 'Invite code must be 6 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: joinState.isLoading ? null : _handleJoin,
                      child: joinState.isLoading
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
                          : const Text('Join Server'),
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
