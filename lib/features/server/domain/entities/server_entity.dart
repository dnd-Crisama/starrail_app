// lib/features/server/domain/entities/server_entity.dart
import 'package:equatable/equatable.dart';

class ServerEntity extends Equatable {
  final String serverId;
  final String name;
  final String iconUrl;
  final String ownerId;
  final String inviteCode;
  final bool isSuspended;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServerEntity({
    required this.serverId,
    required this.name,
    this.iconUrl = '',
    required this.ownerId,
    required this.inviteCode,
    this.isSuspended = false,
    required this.createdAt,
    required this.updatedAt,
  });

  ServerEntity copyWith({
    String? serverId,
    String? name,
    String? iconUrl,
    String? ownerId,
    String? inviteCode,
    bool? isSuspended,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServerEntity(
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      ownerId: ownerId ?? this.ownerId,
      inviteCode: inviteCode ?? this.inviteCode,
      isSuspended: isSuspended ?? this.isSuspended,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    serverId,
    name,
    iconUrl,
    ownerId,
    inviteCode,
    isSuspended,
  ];
}
