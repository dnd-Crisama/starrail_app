// lib/features/server/domain/entities/server_member_entity.dart
import 'package:equatable/equatable.dart';

class ServerMemberEntity extends Equatable {
  final String userId;
  final String serverId;
  final DateTime joinedAt;
  final List<String> roleIds;
  final String? nickname;

  const ServerMemberEntity({
    required this.userId,
    required this.serverId,
    required this.joinedAt,
    this.roleIds = const [],
    this.nickname,
  });

  ServerMemberEntity copyWith({
    String? userId,
    String? serverId,
    DateTime? joinedAt,
    List<String>? roleIds,
    String? nickname,
  }) {
    return ServerMemberEntity(
      userId: userId ?? this.userId,
      serverId: serverId ?? this.serverId,
      joinedAt: joinedAt ?? this.joinedAt,
      roleIds: roleIds ?? this.roleIds,
      nickname: nickname ?? this.nickname,
    );
  }

  @override
  List<Object?> get props => [userId, serverId, joinedAt, roleIds, nickname];
}
