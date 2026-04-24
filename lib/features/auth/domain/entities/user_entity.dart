import 'package:equatable/equatable.dart';

enum UserStatus { offline, online, idle, dnd }

class UserEntity extends Equatable {
  final String uid;
  final String username;
  final String email;
  final String avatarUrl;
  final String bio;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastSeenAt;

  const UserEntity({
    required this.uid,
    required this.username,
    required this.email,
    this.avatarUrl = '',
    this.bio = '',
    this.status = UserStatus.offline,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSeenAt,
  });

  UserEntity copyWith({
    String? uid,
    String? username,
    String? email,
    String? avatarUrl,
    String? bio,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSeenAt,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  @override
  List<Object?> get props => [uid, username, email, avatarUrl, bio, status];
}
