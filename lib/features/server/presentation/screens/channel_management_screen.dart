import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/channel_entity.dart';
import '../providers/channel_provider.dart';
import '../../../home/presentation/providers/home_provider.dart';

class ChannelManagementScreen extends ConsumerStatefulWidget {
  const ChannelManagementScreen({super.key});

  @override
  ConsumerState<ChannelManagementScreen> createState() =>
      _ChannelManagementScreenState();
}

class _ChannelManagementScreenState
    extends ConsumerState<ChannelManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final serverId = ref.watch(selectedServerIdProvider);
    if (serverId == null) {
      return const Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: Text('Chưa chọn server', style: AppTextStyles.textMuted),
        ),
      );
    }

    final channelsState = ref.watch(serverChannelsStreamProvider(serverId));
    final managementState = ref.watch(channelManagementNotifierProvider);

    // Lắng nghe lỗi
    ref.listen<ChannelManagementState>(channelManagementNotifierProvider, (
      prev,
      next,
    ) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
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
        backgroundColor: AppColors.bgTertiary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.interactiveNormal,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Quản lý kênh', style: AppTextStyles.headerPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.green),
            onPressed: () =>
                _navigateToChannelEditor(context, serverId: serverId),
          ),
        ],
      ),
      body: managementState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brand),
            )
          : channelsState.when(
              data: (channels) => _buildChannelList(channels, serverId),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.brand),
              ),
              error: (err, _) => _buildStreamError(err, serverId),
            ),
    );
  }

  void _navigateToChannelEditor(
    BuildContext context, {
    required String serverId,
    ChannelEntity? editingChannel,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChannelEditorScreen(
          serverId: serverId,
          editingChannel: editingChannel,
        ),
      ),
    );
  }

  Widget _buildChannelList(List<ChannelEntity> channels, String serverId) {
    final managementState = ref.watch(channelManagementNotifierProvider);

    // Tách kênh text và voice
    final textChannels = channels
        .where((c) => c.type == ChannelType.text)
        .toList();
    final voiceChannels = channels
        .where((c) => c.type == ChannelType.voice)
        .toList();

    return Column(
      children: [
        if (managementState.errorMessage != null)
          _buildErrorBanner(managementState.errorMessage!),
        Expanded(
          child: channels.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tag_outlined,
                        size: 48,
                        color: AppColors.channelDefault.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Chưa có kênh nào',
                        style: AppTextStyles.textMuted,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nhấn + để tạo kênh mới',
                        style: AppTextStyles.textMutedSmall,
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (textChannels.isNotEmpty) ...[
                      _buildSectionHeader('Kênh văn bản'),
                      ...textChannels.map(
                        (channel) => _ChannelCard(
                          channel: channel,
                          onEdit: () => _navigateToChannelEditor(
                            context,
                            serverId: serverId,
                            editingChannel: channel,
                          ),
                          onDelete: channel.isDefault
                              ? null
                              : () =>
                                    _confirmDelete(context, channel, serverId),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (voiceChannels.isNotEmpty) ...[
                      _buildSectionHeader('Kênh thoại'),
                      ...voiceChannels.map(
                        (channel) => _ChannelCard(
                          channel: channel,
                          onEdit: () => _navigateToChannelEditor(
                            context,
                            serverId: serverId,
                            editingChannel: channel,
                          ),
                          onDelete: channel.isDefault
                              ? null
                              : () =>
                                    _confirmDelete(context, channel, serverId),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: AppTextStyles.categoryHeader.copyWith(
          fontSize: 13,
          color: AppColors.interactiveNormal,
        ),
      ),
    );
  }

  Widget _buildStreamError(Object err, String serverId) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 40),
          const SizedBox(height: 12),
          Text('Không thể tải kênh', style: AppTextStyles.headerSecondary),
          const SizedBox(height: 4),
          Text(
            '$err',
            style: AppTextStyles.textMutedSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ref.invalidate(serverChannelsStreamProvider(serverId)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: AppColors.red.withOpacity(0.2),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(color: AppColors.red)),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.red, size: 18),
            onPressed: () => ref
                .read(channelManagementNotifierProvider.notifier)
                .clearError(),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ChannelEntity channel,
    String serverId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgFloating,
        title: Text(
          'Xóa kênh "${channel.name}"?',
          style: AppTextStyles.headerPrimary,
        ),
        content: Text(
          'Hành động này sẽ xóa kênh và toàn bộ tin nhắn trong đó. Không thể hoàn tác.',
          style: AppTextStyles.bodySecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.interactiveNormal),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(channelManagementNotifierProvider.notifier)
                  .deleteChannel(
                    serverId: serverId,
                    channelId: channel.channelId,
                  );
            },
            child: const Text('Xóa', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CHANNEL CARD
// ═══════════════════════════════════════════════════════════════

class _ChannelCard extends StatelessWidget {
  final ChannelEntity channel;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _ChannelCard({
    required this.channel,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.bgModifierHover,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(
            channel.type == ChannelType.voice
                ? Icons.volume_up_outlined
                : Icons.tag,
            color: AppColors.interactiveNormal,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                channel.name,
                style: AppTextStyles.bodySecondary.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (channel.isDefault) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.bgModifierHover,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'Mặc định',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: channel.topic.isNotEmpty
            ? Text(
                channel.topic,
                style: AppTextStyles.textMutedSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: AppColors.interactiveNormal,
                size: 20,
              ),
              onPressed: onEdit,
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(
                  Icons.delete_outlined,
                  color: AppColors.red,
                  size: 20,
                ),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CHANNEL EDITOR SCREEN
// ═══════════════════════════════════════════════════════════════

class ChannelEditorScreen extends ConsumerStatefulWidget {
  final String serverId;
  final ChannelEntity? editingChannel;

  const ChannelEditorScreen({
    super.key,
    required this.serverId,
    this.editingChannel,
  });

  @override
  ConsumerState<ChannelEditorScreen> createState() =>
      _ChannelEditorScreenState();
}

class _ChannelEditorScreenState extends ConsumerState<ChannelEditorScreen> {
  late TextEditingController _nameController;
  late TextEditingController _topicController;
  ChannelType _selectedType = ChannelType.text;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.editingChannel?.name ?? '',
    );
    _topicController = TextEditingController(
      text: widget.editingChannel?.topic ?? '',
    );
    _selectedType = widget.editingChannel?.type ?? ChannelType.text;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingChannel != null;
    final isDefaultChannel = widget.editingChannel?.isDefault ?? false;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgTertiary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.interactiveNormal,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Chỉnh sửa kênh' : 'Tạo kênh mới',
          style: AppTextStyles.headerPrimary,
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: AppColors.brand,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    isEditing ? 'Lưu' : 'Tạo',
                    style: const TextStyle(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Channel type selector ────────────────────────────
            Text('Loại kênh', style: AppTextStyles.bodySecondary),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: isDefaultChannel
                        ? null
                        : () =>
                              setState(() => _selectedType = ChannelType.text),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedType == ChannelType.text
                            ? AppColors.brand.withOpacity(0.2)
                            : AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedType == ChannelType.text
                              ? AppColors.brand
                              : AppColors.inputBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tag,
                            color: _selectedType == ChannelType.text
                                ? AppColors.brand
                                : AppColors.interactiveNormal,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Văn bản',
                                  style: AppTextStyles.bodySecondary.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: _selectedType == ChannelType.text
                                        ? AppColors.brand
                                        : AppColors.interactiveNormal,
                                  ),
                                ),
                                Text(
                                  'Gửi tin nhắn, hình ảnh, liên kết',
                                  style: AppTextStyles.textMutedSmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: isDefaultChannel
                        ? null
                        : () =>
                              setState(() => _selectedType = ChannelType.voice),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedType == ChannelType.voice
                            ? AppColors.brand.withOpacity(0.2)
                            : AppColors.bgSecondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedType == ChannelType.voice
                              ? AppColors.brand
                              : AppColors.inputBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.volume_up_outlined,
                            color: _selectedType == ChannelType.voice
                                ? AppColors.brand
                                : AppColors.interactiveNormal,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Thoại',
                                  style: AppTextStyles.bodySecondary.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: _selectedType == ChannelType.voice
                                        ? AppColors.brand
                                        : AppColors.interactiveNormal,
                                  ),
                                ),
                                Text(
                                  'Tham gia kênh thoại, gọi video',
                                  style: AppTextStyles.textMutedSmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Name field ───────────────────────────────────────
            Text('Tên kênh', style: AppTextStyles.bodySecondary),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: AppColors.textNormal),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.brand),
                ),
                prefixText: _selectedType == ChannelType.text ? '# ' : '🔊 ',
                prefixStyle: AppTextStyles.textMuted,
                hintText: 'kênh-mới',
                hintStyle: AppTextStyles.textMuted,
              ),
              enabled: !isDefaultChannel,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 4),
            Text(
              'Tên kênh chỉ được chứa chữ thường, số và dấu gạch ngang.',
              style: AppTextStyles.textMutedSmall,
            ),
            const SizedBox(height: 20),

            // ── Topic field (text channels only) ──────────────────
            if (_selectedType == ChannelType.text) ...[
              Text('Chủ đề', style: AppTextStyles.bodySecondary),
              const SizedBox(height: 6),
              TextField(
                controller: _topicController,
                style: const TextStyle(color: AppColors.textNormal),
                maxLines: 2,
                maxLength: 1024,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppColors.brand),
                  ),
                  hintText: 'Mô tả kênh này dùng để làm gì...',
                  hintStyle: AppTextStyles.textMuted,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Cancel button ────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.interactiveNormal,
                  side: const BorderSide(color: AppColors.inputBorder),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text('Hủy'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty && !(widget.editingChannel?.isDefault ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên kênh'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final isEditing = widget.editingChannel != null;

    if (isEditing) {
      await ref
          .read(channelManagementNotifierProvider.notifier)
          .updateChannel(
            serverId: widget.serverId,
            channelId: widget.editingChannel!.channelId,
            name: name.isEmpty ? widget.editingChannel!.name : name,
            type: _selectedType,
            topic: _topicController.text.trim(),
          );
    } else {
      await ref
          .read(channelManagementNotifierProvider.notifier)
          .createChannel(
            serverId: widget.serverId,
            name: name,
            type: _selectedType,
            topic: _topicController.text.trim(),
          );
    }

    if (mounted) {
      final error = ref.read(channelManagementNotifierProvider).errorMessage;
      if (error != null) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thao tác thành công'),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }
}
