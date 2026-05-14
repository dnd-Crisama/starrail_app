// lib/features/friend/data/models/dm_chat_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/dm_chat_entity.dart';

class DmChatModel {
  final String chatId;
  final String type; // DM, GROUP_DM
  final List<String> participants;
  final String name;
  final String? iconUrl;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String lastMessagePreview;

  const DmChatModel({
    required this.chatId,
    required this.type,
    required this.participants,
    this.name = '',
    this.iconUrl,
    required this.createdAt,
    required this.lastMessageAt,
    this.lastMessagePreview = '',
  });

  factory DmChatModel.fromFirestore(Map<String, dynamic> map, String docId) {
    return DmChatModel(
      chatId: docId,
      type: map['type'] as String? ?? 'DM',
      participants: List<String>.from(map['participants'] as List? ?? []),
      name: map['name'] as String? ?? '',
      iconUrl: map['iconUrl'] as String?,
      createdAt: _parseTimestamp(map['createdAt']),
      lastMessageAt: _parseTimestamp(map['lastMessageAt']),
      lastMessagePreview: map['lastMessagePreview'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'participants': participants,
      'name': name,
      if (iconUrl != null) 'iconUrl': iconUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessagePreview': lastMessagePreview,
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  DmChatEntity toEntity() {
    return DmChatEntity(
      chatId: chatId,
      type: type == 'GROUP_DM' ? DmChatType.groupDm : DmChatType.dm,
      participants: participants,
      name: name,
      iconUrl: iconUrl,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt,
      lastMessagePreview: lastMessagePreview,
    );
  }
}
