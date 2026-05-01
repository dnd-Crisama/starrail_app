import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel {
  final String uid;
  final String username;
  final String email;
  final String avatarUrl;
  final String bio;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastSeenAt;

  const UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.avatarUrl = '',
    this.bio = '',
    this.status = 'OFFLINE',
    required this.createdAt,
    required this.updatedAt,
    required this.lastSeenAt,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      username: map['username'] as String? ?? '',
      email: map['email'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      status: map['status'] as String? ?? 'OFFLINE',
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      lastSeenAt: _parseTimestamp(map['lastSeenAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username.toLowerCase().trim(),
      'email': email,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    };
  }

  // HÀM MỚI: Tạo map chỉ chứa những field cần cập nhật (tránh ghi đè null)
  Map<String, dynamic> toUpdateMap({
    String? username,
    String? bio,
    String? avatarUrl,
  }) {
    final Map<String, dynamic> data = {};
    if (username != null) data['username'] = username.toLowerCase().trim();
    if (bio != null) data['bio'] = bio;
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    return data;
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  UserEntity toEntity() {
    return UserEntity(
      uid: uid,
      username: username,
      email: email,
      avatarUrl: avatarUrl,
      bio: bio,
      status: _mapStatus(status),
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastSeenAt: lastSeenAt,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      username: entity.username,
      email: entity.email,
      avatarUrl: entity.avatarUrl,
      bio: entity.bio,
      status: entity.status.name.toUpperCase(),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      lastSeenAt: entity.lastSeenAt,
    );
  }

  UserStatus _mapStatus(String statusStr) {
    switch (statusStr.toUpperCase()) {
      case 'ONLINE':
        return UserStatus.online;
      case 'IDLE':
        return UserStatus.idle;
      case 'DND':
        return UserStatus.dnd;
      default:
        return UserStatus.offline;
    }
  }
}
