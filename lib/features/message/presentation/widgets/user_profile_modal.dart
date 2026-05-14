import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/entities/user_entity.dart';

/// Discord-style profile popup khi click vào avatar hoặc tên user khác
class UserServerRoleBadge {
  final String roleId;
  final String name;
  final int color;
  final int hierarchyLevel;
  final bool isDefault;

  const UserServerRoleBadge({
    required this.roleId,
    required this.name,
    required this.color,
    required this.hierarchyLevel,
    required this.isDefault,
  });
}

class UserProfileModal extends StatelessWidget {
  final UserEntity user;
  final List<UserServerRoleBadge> serverRoles;
  final int mutualServers;
  final int mutualFriends;

  const UserProfileModal({
    super.key,
    required this.user,
    this.serverRoles = const [],
    this.mutualServers = 0,
    this.mutualFriends = 0,
  });

  /// Hiển thị modal dạng dialog
  static Future<void> show(
    BuildContext context, {
    required UserEntity user,
    List<UserServerRoleBadge> serverRoles = const [],
    int mutualServers = 0,
    int mutualFriends = 0,
  }) {
    return showDialog(
      context: context,
      barrierColor: AppColors.scrim,
      builder: (_) => UserProfileModal(
        user: user,
        serverRoles: serverRoles,
        mutualServers: mutualServers,
        mutualFriends: mutualFriends,
      ),
    );
  }

  /// Fetch user data từ Firestore rồi hiển thị modal
  static Future<void> showFromUid(
    BuildContext context, {
    required String uid,
    String? serverId,
  }) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final user = UserEntity(
        uid: uid,
        username: data['username'] as String? ?? 'Người dùng',
        email: data['email'] as String? ?? '',
        avatarUrl: data['avatarUrl'] as String? ?? '',
        bio: data['bio'] as String? ?? '',
        status: _parseStatus(data['status'] as String?),
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt:
            (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastSeenAt:
            (data['lastSeenAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
      final serverRoles = serverId == null
          ? <UserServerRoleBadge>[]
          : await _loadServerRoles(serverId: serverId, uid: uid);

      if (context.mounted) {
        show(context, user: user, serverRoles: serverRoles);
      }
    } catch (_) {
      // Silent fail — không hiển thị gì nếu không lấy được data
    }
  }

  static UserStatus _parseStatus(String? statusStr) {
    switch (statusStr?.toUpperCase()) {
      case 'ONLINE':
        return UserStatus.online;
      case 'IDLE':
        return UserStatus.idle;
      case 'DND':
        return UserStatus.dnd;
      case 'INVISIBLE':
        return UserStatus.invisible;
      default:
        return UserStatus.offline;
    }
  }

  static Future<List<UserServerRoleBadge>> _loadServerRoles({
    required String serverId,
    required String uid,
  }) async {
    final memberDoc = await FirebaseFirestore.instance
        .collection('servers')
        .doc(serverId)
        .collection('members')
        .doc(uid)
        .get();
    if (!memberDoc.exists) return [];

    final roleIds = <String>{
      ...List<String>.from(memberDoc.data()?['roleIds'] as List? ?? []),
    };

    final defaultRoleQuery = await FirebaseFirestore.instance
        .collection('servers')
        .doc(serverId)
        .collection('roles')
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();
    if (defaultRoleQuery.docs.isNotEmpty) {
      roleIds.add(defaultRoleQuery.docs.first.id);
    }

    final roles = <UserServerRoleBadge>[];
    for (final roleId in roleIds) {
      final roleDoc = await FirebaseFirestore.instance
          .collection('servers')
          .doc(serverId)
          .collection('roles')
          .doc(roleId)
          .get();
      if (!roleDoc.exists) continue;

      final roleData = roleDoc.data()!;
      roles.add(
        UserServerRoleBadge(
          roleId: roleDoc.id,
          name: roleData['name'] as String? ?? 'role',
          color: roleData['color'] as int? ?? 0xFF99AAB5,
          hierarchyLevel: roleData['hierarchyLevel'] as int? ?? 0,
          isDefault: roleData['isDefault'] as bool? ?? false,
        ),
      );
    }

    roles.sort((a, b) {
      final levelCompare = b.hierarchyLevel.compareTo(a.hierarchyLevel);
      if (levelCompare != 0) return levelCompare;
      if (a.isDefault != b.isDefault) return a.isDefault ? 1 : -1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return roles;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 340,
        constraints: const BoxConstraints(maxHeight: 480),
        decoration: BoxDecoration(
          color: AppColors.bgFloating,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Banner + Avatar section
            _buildBannerWithAvatar(),
            // User info section
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 44, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username
                    Text(
                      user.username,
                      style: AppTextStyles.headerPrimary.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 2),
                    // Username + status
                    Row(
                      children: [
                        Text(
                          user.username,
                          style: AppTextStyles.textMutedSmall.copyWith(
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildStatusDot(size: 8),
                        const SizedBox(width: 4),
                        Text(
                          _statusLabel,
                          style: AppTextStyles.textMutedSmall.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    // Mutual info
                    if (mutualFriends > 0 || mutualServers > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '$mutualFriends Bạn chung • $mutualServers Máy chủ chung',
                        style: AppTextStyles.textMutedSmall.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (serverRoles.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Vai trò',
                        style: AppTextStyles.header4.copyWith(
                          fontSize: 10,
                          color: AppColors.textNormal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: serverRoles
                            .map((role) => _buildRoleChip(role))
                            .toList(),
                      ),
                    ],
                    // Bio
                    if (user.bio.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.bgModifierHover,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VỀ BẢN THÂN',
                              style: AppTextStyles.header4.copyWith(
                                fontSize: 10,
                                color: AppColors.textNormal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.bio,
                              style: AppTextStyles.bodySecondary.copyWith(
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Created at
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tham gia ngày ${_formatDate(user.createdAt)}',
                          style: AppTextStyles.textMutedSmall.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(UserServerRoleBadge role) {
    final roleColor = Color(role.color);
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgModifierHover,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: roleColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              role.name,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.textMutedSmall.copyWith(
                color: AppColors.textNormal,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerWithAvatar() {
    return SizedBox(
      height: 100,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Banner background — gradient pattern (Discord-style)
          Container(
            height: 80,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.brand,
                  AppColors.brandActive,
                  Color(0xFF5865F2),
                ],
              ),
            ),
          ),
          // Avatar — positioned overlapping banner
          Positioned(
            left: 16,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bgTertiary,
                border: Border.all(color: AppColors.bgFloating, width: 4),
              ),
              child: ClipOval(
                child: user.avatarUrl.isNotEmpty
                    ? Image.network(
                        user.avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildInitialAvatar(80),
                        loadingBuilder: (_, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                      )
                    : _buildInitialAvatar(80),
              ),
            ),
          ),
          // Status dot on avatar
          Positioned(
            left: 72,
            bottom: -16,
            child: _buildStatusDot(size: 18, hasBorder: true),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.brand,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
        style: TextStyle(
          color: AppColors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusDot({double size = 8, bool hasBorder = false}) {
    final color = _statusColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: hasBorder
            ? Border.all(color: AppColors.bgFloating, width: 3)
            : null,
      ),
    );
  }

  Color get _statusColor {
    switch (user.status) {
      case UserStatus.online:
        return AppColors.statusOnline;
      case UserStatus.idle:
        return AppColors.statusIdle;
      case UserStatus.dnd:
        return AppColors.statusDnd;
      case UserStatus.invisible:
      case UserStatus.offline:
        return AppColors.statusOffline;
    }
  }

  String get _statusLabel {
    switch (user.status) {
      case UserStatus.online:
        return 'Trực tuyến';
      case UserStatus.idle:
        return 'Chờ đợi';
      case UserStatus.dnd:
        return 'Không làm phiền';
      case UserStatus.invisible:
        return 'Vô hình';
      case UserStatus.offline:
        return 'Ngoại tuyến';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      '',
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];
    return '${date.day} ${months[date.month]}, ${date.year}';
  }
}
