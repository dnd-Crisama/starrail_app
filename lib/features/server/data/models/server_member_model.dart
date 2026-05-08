// lib/features/server/data/models/server_member_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/server_member_entity.dart';

class ServerMemberModel {
  final String userId;
  final String serverId;
  final DateTime joinedAt;
  final List<String> roleIds;
  final String? nickname;

  const ServerMemberModel({
    required this.userId,
    required this.serverId,
    required this.joinedAt,
    this.roleIds = const [],
    this.nickname,
  });

  factory ServerMemberModel.fromFirestore(
    Map<String, dynamic> map,
    String docId,
    String serverId,
  ) {
    return ServerMemberModel(
      userId: docId,
      serverId: serverId,
      joinedAt: _parseTimestamp(map['joinedAt']),
      roleIds: List<String>.from(map['roleIds'] as List? ?? []),
      nickname: map['nickname'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'serverId': serverId,
      'joinedAt': FieldValue.serverTimestamp(),
      'roleIds': roleIds,
      if (nickname != null) 'nickname': nickname,
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  ServerMemberEntity toEntity() {
    return ServerMemberEntity(
      userId: userId,
      serverId: serverId,
      joinedAt: joinedAt,
      roleIds: roleIds,
      nickname: nickname,
    );
  }
}
