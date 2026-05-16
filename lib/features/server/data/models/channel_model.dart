import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/channel_entity.dart';

class ChannelModel {
  final String channelId;
  final String serverId;
  final String name;
  final ChannelType type;
  final String categoryId;
  final int position;
  final String topic;
  final List<String> allowedViewRoleIds;
  final List<String> allowedSendRoleIds;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChannelModel({
    required this.channelId,
    required this.serverId,
    required this.name,
    this.type = ChannelType.text,
    this.categoryId = '',
    this.position = 0,
    this.topic = '',
    this.allowedViewRoleIds = const [],
    this.allowedSendRoleIds = const [],
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChannelModel.fromFirestore(Map<String, dynamic> map, String docId) {
    return ChannelModel(
      channelId: docId,
      serverId: map['serverId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: _parseChannelType(map['type'] as String? ?? 'text'),
      categoryId: map['categoryId'] as String? ?? '',
      position: map['position'] as int? ?? 0,
      topic: map['topic'] as String? ?? '',
      allowedViewRoleIds: List<String>.from(
        map['allowedViewRoleIds'] as List? ?? [],
      ),
      allowedSendRoleIds: List<String>.from(
        map['allowedSendRoleIds'] as List? ?? [],
      ),
      isDefault: map['isDefault'] as bool? ?? false,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'serverId': serverId,
      'name': name,
      'type': type == ChannelType.text ? 'text' : 'voice',
      'categoryId': categoryId,
      'position': position,
      'topic': topic,
      'allowedViewRoleIds': allowedViewRoleIds,
      'allowedSendRoleIds': allowedSendRoleIds,
      'isDefault': isDefault,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static ChannelType _parseChannelType(String value) {
    switch (value.toLowerCase()) {
      case 'voice':
        return ChannelType.voice;
      case 'text':
      default:
        return ChannelType.text;
    }
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  ChannelEntity toEntity() {
    return ChannelEntity(
      channelId: channelId,
      serverId: serverId,
      name: name,
      type: type,
      categoryId: categoryId,
      position: position,
      topic: topic,
      allowedViewRoleIds: allowedViewRoleIds,
      allowedSendRoleIds: allowedSendRoleIds,
      isDefault: isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory ChannelModel.fromEntity(ChannelEntity entity) {
    return ChannelModel(
      channelId: entity.channelId,
      serverId: entity.serverId,
      name: entity.name,
      type: entity.type,
      categoryId: entity.categoryId,
      position: entity.position,
      topic: entity.topic,
      allowedViewRoleIds: entity.allowedViewRoleIds,
      allowedSendRoleIds: entity.allowedSendRoleIds,
      isDefault: entity.isDefault,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
