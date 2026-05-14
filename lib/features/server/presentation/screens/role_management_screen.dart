import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/permission.dart';
import '../../domain/entities/role_entity.dart';
import '../providers/role_provider.dart';
import '../../../home/presentation/providers/home_provider.dart';

class RoleManagementScreen extends ConsumerStatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  ConsumerState<RoleManagementScreen> createState() =>
      _RoleManagementScreenState();
}

class _RoleManagementScreenState extends ConsumerState<RoleManagementScreen> {
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

    final rolesState = ref.watch(serverRolesStreamProvider(serverId));
    final managementState = ref.watch(roleManagementNotifierProvider);

    // Listen for error messages
    ref.listen<RoleManagementState>(roleManagementNotifierProvider, (
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          title: const Text(
            'Quản lý vai trò',
            style: AppTextStyles.headerPrimary,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.green),
              onPressed: () => _navigateToRoleEditor(
                context,
                serverId: serverId,
                existingRoles: rolesState.maybeWhen(
                  data: (roles) => roles,
                  orElse: () => [],
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.brand,
            labelColor: AppColors.white,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [
              Tab(text: 'Vai trò'),
              Tab(text: 'Thành viên'),
            ],
          ),
        ),
        body: managementState.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.brand),
              )
            : rolesState.when(
                data: (roles) => TabBarView(
                  children: [
                    _buildRoleList(roles, serverId),
                    _buildMemberRoleList(roles, serverId),
                  ],
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.brand),
                ),
                error: (err, _) => _buildStreamError(err, serverId),
              ),
      ),
    );
  }

  void _navigateToRoleEditor(
    BuildContext context, {
    required String serverId,
    required List<RoleEntity> existingRoles,
    RoleEntity? editingRole,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoleEditorScreen(
          serverId: serverId,
          existingRoles: existingRoles,
          editingRole: editingRole,
        ),
      ),
    );
  }

  Widget _buildRoleList(List<RoleEntity> roles, String serverId) {
    final managementState = ref.watch(roleManagementNotifierProvider);

    return Column(
      children: [
        if (managementState.errorMessage != null)
          _buildErrorBanner(managementState.errorMessage!),
        Expanded(
          child: roles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.security_outlined,
                        size: 48,
                        color: AppColors.channelDefault.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Chưa có vai trò nào',
                        style: AppTextStyles.textMuted,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nhấn + để tạo vai trò mới',
                        style: AppTextStyles.textMutedSmall,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: roles.length,
                  itemBuilder: (context, index) {
                    final role = roles[index];
                    return _RoleCard(
                      role: role,
                      onEdit: () => _navigateToRoleEditor(
                        context,
                        serverId: serverId,
                        existingRoles: roles,
                        editingRole: role,
                      ),
                      onDelete: role.isDefault
                          ? null
                          : () => _confirmDelete(context, role, serverId),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMemberRoleList(List<RoleEntity> roles, String serverId) {
    final membersState = ref.watch(
      serverMembersWithUsersStreamProvider(serverId),
    );
    final editableRoles = roles
        .where((role) => !role.isDefault && !role.isManagedBySystem)
        .toList();

    return membersState.when(
      data: (members) {
        if (members.isEmpty) {
          return const Center(
            child: Text('Chưa có thành viên', style: AppTextStyles.textMuted),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final item = members[index];
            final displayName =
                item.member.nickname ??
                item.user?.username ??
                item.member.userId;
            final avatarUrl = item.user?.avatarUrl ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.brand,
                        backgroundImage: avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl.isEmpty
                            ? Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(color: AppColors.white),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: AppTextStyles.bodySecondary.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${item.member.roleIds.length} vai trò',
                              style: AppTextStyles.textMutedSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (editableRoles.isEmpty)
                    const Text(
                      'Chưa có vai trò có thể gán',
                      style: AppTextStyles.textMutedSmall,
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: editableRoles.map((role) {
                        final selected = item.member.roleIds.contains(
                          role.roleId,
                        );
                        return FilterChip(
                          selected: selected,
                          label: Text(role.name),
                          avatar: CircleAvatar(
                            radius: 6,
                            backgroundColor: Color(role.color),
                          ),
                          selectedColor: Color(role.color).withOpacity(0.22),
                          backgroundColor: AppColors.bgModifierHover,
                          checkmarkColor: AppColors.white,
                          labelStyle: TextStyle(
                            color: selected
                                ? AppColors.white
                                : AppColors.interactiveNormal,
                          ),
                          onSelected: (value) async {
                            final notifier = ref.read(
                              roleManagementNotifierProvider.notifier,
                            );
                            if (value) {
                              await notifier.assignRoleToMember(
                                serverId: serverId,
                                userId: item.member.userId,
                                roleId: role.roleId,
                              );
                            } else {
                              await notifier.removeRoleFromMember(
                                serverId: serverId,
                                userId: item.member.userId,
                                roleId: role.roleId,
                              );
                            }
                          },
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.brand),
      ),
      error: (err, _) => Center(
        child: Text(
          'Không thể tải thành viên: $err',
          style: AppTextStyles.textMuted,
          textAlign: TextAlign.center,
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
          Text('Không thể tải vai trò', style: AppTextStyles.headerSecondary),
          const SizedBox(height: 4),
          Text(
            '$err',
            style: AppTextStyles.textMutedSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ref.invalidate(serverRolesStreamProvider(serverId)),
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
            onPressed: () =>
                ref.read(roleManagementNotifierProvider.notifier).clearError(),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, RoleEntity role, String serverId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgFloating,
        title: Text(
          'Xóa vai trò "${role.name}"?',
          style: AppTextStyles.headerPrimary,
        ),
        content: Text(
          'Hành động này sẽ xóa vai trò và gỡ khỏi tất cả thành viên. Không thể hoàn tác.',
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
                  .read(roleManagementNotifierProvider.notifier)
                  .deleteRole(serverId: serverId, roleId: role.roleId);
            },
            child: const Text('Xóa', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ROLE CARD
// ═══════════════════════════════════════════════════════════════

class _RoleCard extends StatelessWidget {
  final RoleEntity role;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _RoleCard({required this.role, required this.onEdit, this.onDelete});

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
            color: Color(role.color),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            role.name[0].toUpperCase(),
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                role.name,
                style: TextStyle(
                  color: Color(role.color),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (role.isDefault) ...[
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
        subtitle: Text(
          '${role.permissions.length} quyền  ·  Cấp ${role.hierarchyLevel}',
          style: AppTextStyles.textMutedSmall,
        ),
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
//  ROLE EDITOR SCREEN (Separate screen for create/edit)
// ═══════════════════════════════════════════════════════════════

class RoleEditorScreen extends ConsumerStatefulWidget {
  final String serverId;
  final List<RoleEntity> existingRoles;
  final RoleEntity? editingRole;

  const RoleEditorScreen({
    super.key,
    required this.serverId,
    required this.existingRoles,
    this.editingRole,
  });

  @override
  ConsumerState<RoleEditorScreen> createState() => _RoleEditorScreenState();
}

class _RoleEditorScreenState extends ConsumerState<RoleEditorScreen> {
  late TextEditingController _nameController;
  int _selectedColor = 0xFF99AAB5;
  int _hierarchyLevel = 1;
  final Set<Permission> _selectedPermissions = {};
  bool _isSaving = false;

  static const List<int> _presetColors = [
    0xFF99AAB5,
    0xFFE74C3C,
    0xFFE67E22,
    0xFFF1C40F,
    0xFF2ECC71,
    0xFF1ABC9C,
    0xFF3498DB,
    0xFF9B59B6,
    0xFFE91E63,
    0xFF00BCD4,
    0xFF8BC34A,
    0xFFFF9809,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.editingRole?.name ?? '',
    );
    _selectedColor = widget.editingRole?.color ?? 0xFF99AAB5;
    _hierarchyLevel = widget.editingRole?.hierarchyLevel ?? 1;
    if (widget.editingRole != null) {
      _selectedPermissions.addAll(widget.editingRole!.permissions);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingRole != null;
    final isDefaultRole = widget.editingRole?.isDefault ?? false;

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
          isEditing ? 'Chỉnh sửa vai trò' : 'Tạo vai trò mới',
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
            // ── Role preview ─────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Color(_selectedColor),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _nameController.text.isNotEmpty
                          ? _nameController.text[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _nameController.text.isNotEmpty
                        ? _nameController.text
                        : 'Tên vai trò',
                    style: TextStyle(
                      color: Color(_selectedColor),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Name field ───────────────────────────────────────
            Text('Tên vai trò', style: AppTextStyles.bodySecondary),
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
                hintText: isDefaultRole ? '@everyone' : 'Nhập tên vai trò...',
                hintStyle: AppTextStyles.textMuted,
              ),
              enabled: !isDefaultRole,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            // ── Color picker ─────────────────────────────────────
            Text('Màu sắc', style: AppTextStyles.bodySecondary),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetColors.map((colorValue) {
                final isSelected = _selectedColor == colorValue;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = colorValue),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(colorValue),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: AppColors.white, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: AppColors.white,
                            size: 18,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Hierarchy level ──────────────────────────────────
            Text(
              'Cấp phân cấp ($_hierarchyLevel)',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 4),
            Text(
              'Cấp cao hơn có thể quản lý cấp thấp hơn',
              style: AppTextStyles.textMutedSmall,
            ),
            Slider(
              value: _hierarchyLevel.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              activeColor: AppColors.brand,
              onChanged: (val) => setState(() => _hierarchyLevel = val.round()),
            ),
            const SizedBox(height: 12),

            // ── Permissions ──────────────────────────────────────
            Text('Quyền hạn', style: AppTextStyles.bodySecondary),
            const SizedBox(height: 8),
            _buildPermissionGroup('Chung', [
              Permission.viewChannel,
              Permission.manageServer,
              Permission.manageRoles,
              Permission.manageChannel,
              Permission.viewAuditLog,
            ]),
            _buildPermissionGroup('Thành viên', [
              Permission.kickMembers,
              Permission.banMembers,
              Permission.muteMembers,
              Permission.deafenMembers,
              Permission.moveMembers,
            ]),
            _buildPermissionGroup('Tin nhắn', [
              Permission.sendMessages,
              Permission.editMessages,
              Permission.deleteMessages,
              Permission.pinMessages,
              Permission.mentionEveryone,
            ]),
            _buildPermissionGroup('Kênh & Lời mời', [
              Permission.createInvite,
              Permission.connect,
              Permission.speak,
            ]),
            const SizedBox(height: 24),

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

  Widget _buildPermissionGroup(String groupName, List<Permission> perms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            groupName,
            style: AppTextStyles.textMutedSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.interactiveNormal,
            ),
          ),
        ),
        ...perms.map((perm) => _buildPermissionToggle(perm)),
      ],
    );
  }

  Widget _buildPermissionToggle(Permission permission) {
    final isSelected = _selectedPermissions.contains(permission);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedPermissions.remove(permission);
            } else {
              _selectedPermissions.add(permission);
            }
          });
        },
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedPermissions.add(permission);
                      } else {
                        _selectedPermissions.remove(permission);
                      }
                    });
                  },
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.brand;
                    }
                    return AppColors.inputBorder;
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  permission.displayName,
                  style: isSelected
                      ? AppTextStyles.bodySecondary.copyWith(
                          color: AppColors.textNormal,
                        )
                      : AppTextStyles.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty && !(widget.editingRole?.isDefault ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên vai trò'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final isEditing = widget.editingRole != null;

    if (isEditing) {
      await ref
          .read(roleManagementNotifierProvider.notifier)
          .updateRole(
            serverId: widget.serverId,
            roleId: widget.editingRole!.roleId,
            name: name.isEmpty ? '@everyone' : name,
            color: _selectedColor,
            permissions: Permission.toValues(_selectedPermissions.toList()),
            hierarchyLevel: _hierarchyLevel,
          );
    } else {
      await ref
          .read(roleManagementNotifierProvider.notifier)
          .createRole(
            serverId: widget.serverId,
            name: name.isEmpty ? '@everyone' : name,
            color: _selectedColor,
            permissions: Permission.toValues(_selectedPermissions.toList()),
            hierarchyLevel: _hierarchyLevel,
          );
    }

    if (mounted) {
      final error = ref.read(roleManagementNotifierProvider).errorMessage;
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
