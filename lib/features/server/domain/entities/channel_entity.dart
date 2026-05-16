import 'package:equatable/equatable.dart';

enum ChannelType { text, voice }

class ChannelEntity extends Equatable {
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

  const ChannelEntity({
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

  ChannelEntity copyWith({
    String? channelId,
    String? serverId,
    String? name,
    ChannelType? type,
    String? categoryId,
    int? position,
    String? topic,
    List<String>? allowedViewRoleIds,
    List<String>? allowedSendRoleIds,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChannelEntity(
      channelId: channelId ?? this.channelId,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      position: position ?? this.position,
      topic: topic ?? this.topic,
      allowedViewRoleIds: allowedViewRoleIds ?? this.allowedViewRoleIds,
      allowedSendRoleIds: allowedSendRoleIds ?? this.allowedSendRoleIds,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    channelId,
    serverId,
    name,
    type,
    categoryId,
    position,
    topic,
    allowedViewRoleIds,
    allowedSendRoleIds,
    isDefault,
    createdAt,
    updatedAt,
  ];
}
