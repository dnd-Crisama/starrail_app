import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/permission.dart';
import '../../domain/entities/role_entity.dart';

class RoleModel {
  final String roleId;
  final String serverId;
  final String name;
  final int color;
  final List<String> permissions;
  final int hierarchyLevel;
  final bool isDefault;
  final bool isManagedBySystem;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoleModel({
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

  factory RoleModel.fromFirestore(Map<String, dynamic> map, String docId) {
    return RoleModel(
      roleId: docId,
      serverId: map['serverId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      color: map['color'] as int? ?? 0xFF99AAB5,
      permissions: List<String>.from(map['permissions'] as List? ?? []),
      hierarchyLevel: map['hierarchyLevel'] as int? ?? 0,
      isDefault: map['isDefault'] as bool? ?? false,
      isManagedBySystem: map['isManagedBySystem'] as bool? ?? false,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'serverId': serverId,
      'name': name,
      'color': color,
      'permissions': permissions,
      'hierarchyLevel': hierarchyLevel,
      'isDefault': isDefault,
      'isManagedBySystem': isManagedBySystem,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  RoleEntity toEntity() {
    return RoleEntity(
      roleId: roleId,
      serverId: serverId,
      name: name,
      color: color,
      permissions: Permission.fromValues(permissions),
      hierarchyLevel: hierarchyLevel,
      isDefault: isDefault,
      isManagedBySystem: isManagedBySystem,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory RoleModel.fromEntity(RoleEntity entity) {
    return RoleModel(
      roleId: entity.roleId,
      serverId: entity.serverId,
      name: entity.name,
      color: entity.color,
      permissions: Permission.toValues(entity.permissions),
      hierarchyLevel: entity.hierarchyLevel,
      isDefault: entity.isDefault,
      isManagedBySystem: entity.isManagedBySystem,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
