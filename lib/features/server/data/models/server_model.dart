// lib/features/server/data/models/server_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/server_entity.dart';

class ServerModel {
  final String serverId;
  final String name;
  final String iconUrl;
  final String ownerId;
  final String inviteCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServerModel({
    required this.serverId,
    required this.name,
    this.iconUrl = '',
    required this.ownerId,
    required this.inviteCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServerModel.fromFirestore(Map<String, dynamic> map, String docId) {
    return ServerModel(
      serverId: docId,
      name: map['name'] as String? ?? '',
      iconUrl: map['iconUrl'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      inviteCode: map['inviteCode'] as String? ?? '',
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'iconUrl': iconUrl,
      'ownerId': ownerId,
      'inviteCode': inviteCode,
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

  ServerEntity toEntity() {
    return ServerEntity(
      serverId: serverId,
      name: name,
      iconUrl: iconUrl,
      ownerId: ownerId,
      inviteCode: inviteCode,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory ServerModel.fromEntity(ServerEntity entity) {
    return ServerModel(
      serverId: entity.serverId,
      name: entity.name,
      iconUrl: entity.iconUrl,
      ownerId: entity.ownerId,
      inviteCode: entity.inviteCode,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
