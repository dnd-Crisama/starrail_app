// lib/features/friend/presentation/widgets/edit_group_dm_dialog.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/profile_provider.dart'; // storageDatasourceProvider
import '../../domain/entities/dm_chat_entity.dart';
import '../providers/dm_provider.dart';

class EditGroupDmDialog extends ConsumerStatefulWidget {
  final DmChatEntity chat;

  const EditGroupDmDialog({super.key, required this.chat});

  @override
  ConsumerState<EditGroupDmDialog> createState() => _EditGroupDmDialogState();
}

class _EditGroupDmDialogState extends ConsumerState<EditGroupDmDialog> {
  late final TextEditingController _nameController;
  XFile? _pickedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.chat.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
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
        _pickedImage = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.all(20),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'Chỉnh Sửa Nhóm',
              style: AppTextStyles.headerPrimary,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.interactiveNormal),
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Group Avatar Picker
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.bgTertiary,
                      shape: BoxShape.circle,
                      image: _pickedImage != null
                          ? DecorationImage(
                              image: kIsWeb
                                  ? NetworkImage(_pickedImage!.path)
                                  : FileImage(File(_pickedImage!.path)) as ImageProvider,
                              fit: BoxFit.cover,
                            )
                          : (widget.chat.iconUrl != null && widget.chat.iconUrl!.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(widget.chat.iconUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    alignment: Alignment.center,
                    child: _pickedImage == null && (widget.chat.iconUrl == null || widget.chat.iconUrl!.isEmpty)
                        ? const Icon(
                            Icons.group,
                            color: AppColors.textMuted,
                            size: 32,
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bgSecondary, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Tên nhóm input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TÊN NHÓM',
                  style: AppTextStyles.inputLabel.copyWith(fontSize: 10, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: AppTextStyles.textNormal,
                  decoration: const InputDecoration(
                    hintText: 'Tên nhóm',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Hủy bỏ',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.brand.withOpacity(0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          onPressed: _isSaving
              ? null
              : () async {
                  final newName = _nameController.text.trim();
                  if (newName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tên nhóm không được để trống'),
                        backgroundColor: AppColors.red,
                      ),
                    );
                    return;
                  }

                  setState(() {
                    _isSaving = true;
                  });

                  try {
                    String? newIconUrl;
                    if (_pickedImage != null) {
                      final storage = ref.read(storageDatasourceProvider);
                      newIconUrl = await storage.uploadImage(_pickedImage!);
                    }

                    final notifier = ref.read(dmChatNotifierProvider.notifier);
                    final success = await notifier.updateGroupDm(
                      chatId: widget.chat.chatId,
                      name: newName,
                      iconUrl: newIconUrl,
                    );

                    if (success && context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cập nhật nhóm thành công'),
                          backgroundColor: AppColors.brand,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi cập nhật nhóm: $e'),
                          backgroundColor: AppColors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isSaving = false;
                      });
                    }
                  }
                },
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}
