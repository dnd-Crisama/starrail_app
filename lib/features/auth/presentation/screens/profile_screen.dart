import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  String? _initialUsername;

  // Biến lưu ảnh tạm thời để preview trước khi upload
  XFile? _pendingImage;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).user;
    _usernameController = TextEditingController(text: user?.username ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _initialUsername = user?.username;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _pendingImage = pickedFile;
      });
    }
  }

  Future<void> _handleSave() async {
    // 1. Nếu có ảnh đang chờ upload -> Upload ảnh trước
    if (_pendingImage != null) {
      await ref
          .read(profileNotifierProvider.notifier)
          .updateAvatar(_pendingImage!);
      setState(() {
        _pendingImage = null; // Xóa ảnh tạm sau khi bắt đầu upload
      });
      return; // Hàm listen ở dưới sẽ tự động pop về khi upload xong
    }

    // 2. Nếu không có ảnh, chỉ cập nhật text
    if (!_formKey.currentState!.validate()) return;

    final newUsername = _usernameController.text.trim();
    final newBio = _bioController.text.trim();

    if (newUsername != _initialUsername ||
        newBio != (ref.read(authNotifierProvider).user?.bio ?? '')) {
      await ref
          .read(profileNotifierProvider.notifier)
          .updateInfo(username: newUsername, bio: newBio);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final profileState = ref.watch(profileNotifierProvider);
    final user = profileState.user ?? authState.user;

    // Ảnh hiển thị: Ưu tiên ảnh tạm (pending) -> Rồi đến ảnh trên Firestore
    final displayAvatarUrl = _pendingImage != null
        ? _pendingImage!.path
        : (user?.avatarUrl ?? '');

    ref.listen(profileNotifierProvider, (prev, next) {
      if (prev?.isUpdating == true &&
          next.isUpdating == false &&
          next.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thành công!'),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.pop(context);
      }
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
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
        elevation: 0,
        title: Text('Hồ sơ của tôi', style: AppTextStyles.headerSecondary),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: profileState.isUpdating ? null : _handleSave,
              child: profileState.isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Lưu',
                      style: TextStyle(
                        color: AppColors.brand,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Avatar Section ──────────────────────────
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brand,
                        image:
                            displayAvatarUrl.isNotEmpty && _pendingImage == null
                            ? DecorationImage(
                                image: NetworkImage(displayAvatarUrl),
                                fit: BoxFit.cover,
                              )
                            : displayAvatarUrl.isNotEmpty &&
                                  _pendingImage != null
                            ? DecorationImage(
                                image: NetworkImage(displayAvatarUrl),
                                fit: BoxFit.cover,
                              ) // Web trả về URI
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: displayAvatarUrl.isEmpty
                          ? Text(
                              (user?.username ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                    // Loading indicator
                    if (profileState.isUpdating)
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    // Nút chọn ảnh
                    if (!profileState.isUpdating)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.brand,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.bgPrimary,
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: AppColors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Nút xóa ảnh tạm nếu có chọn nhầm
              if (_pendingImage != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _pendingImage = null),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.red,
                      size: 16,
                    ),
                    label: const Text(
                      'Hủy ảnh đã chọn',
                      style: TextStyle(color: AppColors.red, fontSize: 12),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ── Username Field ──────────────────────────
              Text('TÊN NGƯỜI DÙNG', style: AppTextStyles.inputLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                style: AppTextStyles.inputText,
                decoration: InputDecoration(
                  suffixText: '#0000',
                  suffixStyle: AppTextStyles.textMuted,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return 'Vui lòng nhập tên.';
                  if (value.trim().length < 2) return 'Tối thiểu 2 ký tự.';
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim()))
                    return 'Chỉ chứa chữ, số, dấu gạch dưới.';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ── Email Field (Read-only) ────────────────
              Text('EMAIL', style: AppTextStyles.inputLabel),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: user?.email ?? '',
                readOnly: true,
                style: AppTextStyles.textMuted,
                decoration: const InputDecoration(
                  suffixIcon: Icon(
                    Icons.lock_outline,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Bio Field ───────────────────────────────
              Text('GIỚI THIỆU', style: AppTextStyles.inputLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                style: AppTextStyles.inputText,
                maxLines: 3,
                maxLength: 190,
                decoration: const InputDecoration(
                  hintText: 'Hãy nói gì đó về bản thân bạn...',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
