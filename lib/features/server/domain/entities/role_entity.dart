import 'package:equatable/equatable.dart';
import 'permission.dart';

class RoleEntity extends Equatable {
  final String roleId;
  final String serverId;
  final String name;
  final int color;
  final List<Permission> permissions;
  final int hierarchyLevel;
  final bool isDefault;
  final bool isManagedBySystem;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoleEntity({
    required this.roleId,
    required this.serverId,
    required this.name,
    this.color = 0xFF99AAB5,
    this.permissions = const [],
    this.hierarchyLevel = 0,
    this.isDefault = false,
    this.isManagedBySystem = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isEveryoneRole => isDefault;

  bool hasPermission(Permission permission) {
    if (permissions.contains(Permission.manageServer)) return true;
    return permissions.contains(permission);
  }

  bool hasAnyPermission(List<Permission> perms) {
    if (permissions.contains(Permission.manageServer)) return true;
    return perms.any((p) => permissions.contains(p));
  }

  bool hasAllPermissions(List<Permission> perms) {
    if (permissions.contains(Permission.manageServer)) return true;
    return perms.every((p) => permissions.contains(p));
  }

  RoleEntity copyWith({
    String? roleId,
    String? serverId,
    String? name,
    int? color,
    List<Permission>? permissions,
    int? hierarchyLevel,
    bool? isDefault,
    bool? isManagedBySystem,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoleEntity(
      roleId: roleId ?? this.roleId,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      color: color ?? this.color,
      permissions: permissions ?? this.permissions,
      hierarchyLevel: hierarchyLevel ?? this.hierarchyLevel,
      isDefault: isDefault ?? this.isDefault,
      isManagedBySystem: isManagedBySystem ?? this.isManagedBySystem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    roleId,
    serverId,
    name,
    color,
    permissions,
    hierarchyLevel,
    isDefault,
    isManagedBySystem,
  ];
}
