// lib/features/friend/domain/entities/dm_chat_entity.dart
import 'package:equatable/equatable.dart';

/// Loại chat DM.
enum DmChatType { dm, groupDm }

/// Entity đại diện cho một cuộc hội thoại DM (1-1 hoặc Group).
class DmChatEntity extends Equatable {
  final String chatId;
  final DmChatType type;

  /// Danh sách userId tham gia (bao gồm cả currentUser).
  final List<String> participants;

  /// Tên nhóm — bắt buộc với GROUP_DM.
  final String name;

  /// URL icon — optional cho GROUP_DM.
  final String? iconUrl;

  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String lastMessagePreview;

  const DmChatEntity({
    required this.chatId,
    required this.type,
    required this.participants,
    this.name = '',
    this.iconUrl,
    required this.createdAt,
    required this.lastMessageAt,
    this.lastMessagePreview = '',
  });

  bool get isGroupDm => type == DmChatType.groupDm;

  /// Lấy userId của người kia (chỉ dùng với DM 1-1).
  String otherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  DmChatEntity copyWith({
    String? chatId,
    DmChatType? type,
    List<String>? participants,
    String? name,
    String? iconUrl,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
  }) {
    return DmChatEntity(
      chatId: chatId ?? this.chatId,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    );
  }

  @override
  List<Object?> get props => [
    chatId,
    type,
    participants,
    name,
    iconUrl,
    lastMessageAt,
    lastMessagePreview,
  ];
}
