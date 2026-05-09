enum Permission {
  viewChannel('VIEW_CHANNEL', 'Xem kênh'),
  sendMessages('SEND_MESSAGE', 'Gửi tin nhắn'),
  deleteMessages('DELETE_MESSAGE', 'Xóa tin nhắn'),
  editMessages('EDIT_MESSAGE', 'Sửa tin nhắn'),
  manageChannel('MANAGE_CHANNEL', 'Quản lý kênh'),
  manageServer('MANAGE_SERVER', 'Quản lý server'),
  manageRoles('MANAGE_ROLES', 'Quản lý vai trò'),
  mentionEveryone('MENTION_EVERYONE', 'Nhắc mọi người'),
  banMembers('BAN_MEMBERS', 'Cấm thành viên'),
  kickMembers('KICK_MEMBERS', 'Đá thành viên'),
  viewAuditLog('VIEW_AUDIT_LOG', 'Xem nhật ký kiểm duyệt'),
  pinMessages('PIN_MESSAGES', 'Ghim tin nhắn'),
  createInvite('CREATE_INVITE', 'Tạo lời mời'),
  muteMembers('MUTE_MEMBERS', 'Tắt tiếng thành viên'),
  connect('CONNECT', 'Kết nối voice'),
  speak('SPEAK', 'Nói trong voice'),
  deafenMembers('DEAFEN_MEMBERS', 'Tắt nghe thành viên'),
  moveMembers('MOVE_MEMBERS', 'Di chuyển thành viên');

  const Permission(this.value, this.displayName);

  final String value;
  final String displayName;

  static Permission fromValue(String value) {
    return Permission.values.firstWhere(
      (p) => p.value == value,
      orElse: () => Permission.sendMessages,
    );
  }

  static List<Permission> fromValues(List<String> values) {
    return values.map((v) => fromValue(v)).toList();
  }

  static List<String> toValues(List<Permission> permissions) {
    return permissions.map((p) => p.value).toList();
  }
}
