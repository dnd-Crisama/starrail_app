// lib/features/server/presentation/screens/create_server_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/server_provider.dart';

class CreateServerScreen extends ConsumerStatefulWidget {
  const CreateServerScreen({super.key});

  @override
  ConsumerState<CreateServerScreen> createState() => _CreateServerScreenState();
}

class _CreateServerScreenState extends ConsumerState<CreateServerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _serverNameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(createServerNotifierProvider.notifier)
        .createServer(name: _serverNameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createServerNotifierProvider);

    ref.listen(createServerNotifierProvider, (prev, next) {
      if (prev?.createdServer == null &&
          next.createdServer != null &&
          next.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server created successfully!'),
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
        title: const Text('Create Server'),
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
                    'Create a New Server',
                    style: AppTextStyles.headerPrimary.copyWith(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your server is where you and your friends hang out.',
                    style: AppTextStyles.textMuted,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const Text('SERVER NAME', style: AppTextStyles.inputLabel),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _serverNameController,
                    style: AppTextStyles.inputText,
                    decoration: const InputDecoration(
                      hintText: 'My Awesome Server',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Server name is required.';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: createState.isLoading ? null : _handleCreate,
                      child: createState.isLoading
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
                          : const Text('Create Server'),
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
