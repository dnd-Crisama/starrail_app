import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../friend/presentation/providers/friend_provider.dart';
import '../../domain/entities/role_entity.dart';
import '../../domain/entities/server_member_entity.dart';
import '../../domain/usecases/get_server_members_usecase.dart';
import 'role_provider.dart';
import 'server_provider.dart';

// Lắng nghe danh sách thành viên của một server
final serverMembersStreamProvider = StreamProvider.family<List<ServerMemberEntity>, String>((ref, serverId) async* {
  final useCase = ref.watch(getServerMembersUseCaseProvider);
  final result = await useCase(GetServerMembersParams(serverId: serverId));
  
  yield* result.fold(
    ifLeft: (failure) => throw failure.message,
    ifRight: (stream) => stream,
  );
});

// Class mô phỏng thành viên kèm theo trạng thái và thông tin cá nhân
class MemberWithProfile {
  final ServerMemberEntity member;
  final UserEntity profile;
  
  MemberWithProfile({required this.member, required this.profile});
}

// Class mô phỏng nhóm thành viên (có thể là tên Role hoặc tên trạng thái Trực tuyến/Ngoại tuyến)
class MemberGroup {
  final String title;
  final List<MemberWithProfile> members;
  final Color? color;
  final int order; // Dùng để sort (thứ tự role, rồi đến Online, rồi Offline)
  
  MemberGroup({
    required this.title,
    required this.members,
    this.color,
    required this.order,
  });
}

// Provider gom nhóm thành viên theo Role và Trạng thái
final groupedServerMembersProvider = Provider.family<AsyncValue<List<MemberGroup>>, String>((ref, serverId) {
  final membersAsync = ref.watch(serverMembersStreamProvider(serverId));
  final rolesAsync = ref.watch(serverRolesStreamProvider(serverId));
  
  // Trạng thái chung là loading nếu 1 trong 2 đang loading
  if (membersAsync.isLoading || rolesAsync.isLoading) {
    return const AsyncValue.loading();
  }
  
  if (membersAsync.hasError) {
    return AsyncValue.error(membersAsync.error!, membersAsync.stackTrace!);
  }
  
  final members = membersAsync.value ?? [];
  final roles = rolesAsync.value ?? [];
  
  // Tải profile (status) của tất cả thành viên
  final profiles = <String, UserEntity>{};
  for (final member in members) {
    final profileAsync = ref.watch(userProfileProvider(member.userId));
    if (profileAsync.value != null) {
      profiles[member.userId] = profileAsync.value!;
    }
  }
  
  // Gom nhóm
  final Map<String, MemberGroup> groupsMap = {};
  
  // Tạo nhóm mặc định: Online và Offline
  const onlineGroupId = 'online_group';
  const offlineGroupId = 'offline_group';
  
  groupsMap[onlineGroupId] = MemberGroup(
    title: 'TRỰC TUYẾN',
    members: [],
    order: 10000, // Order lớn để xếp dưới các roles
  );
  
  groupsMap[offlineGroupId] = MemberGroup(
    title: 'NGOẠI TUYẾN',
    members: [],
    order: 10001,
  );
  
  // Duyệt từng thành viên để đưa vào nhóm
  for (final member in members) {
    final profile = profiles[member.userId];
    if (profile == null) continue; // Chờ profile load xong
    
    final isOnline = profile.status == UserStatus.online || 
                     profile.status == UserStatus.idle || 
                     profile.status == UserStatus.dnd;
                     
    if (!isOnline) {
      // Ngoại tuyến luôn xếp vào nhóm Ngoại tuyến, không hiện riêng trên Role
      groupsMap[offlineGroupId]!.members.add(MemberWithProfile(member: member, profile: profile));
      continue;
    }
    
    // Nếu Online, tìm role cao nhất
    final memberRoles = roles.where((r) => member.roleIds.contains(r.roleId)).toList();
    final highestRole = getHighestRole(memberRoles);
    
    if (highestRole != null && highestRole.name != '@everyone') {
      // Hiển thị riêng theo Role (tương tự chức năng "Display role members separately from online members" của Discord)
      // Hiện tại ta auto hiển thị riêng theo role cho đơn giản
      final roleId = highestRole.roleId;
      if (!groupsMap.containsKey(roleId)) {
        groupsMap[roleId] = MemberGroup(
          title: highestRole.name.toUpperCase(),
          members: [],
          color: Color(highestRole.color),
          order: -highestRole.hierarchyLevel, // level càng cao -> order càng nhỏ -> lên đầu
        );
      }
      groupsMap[roleId]!.members.add(MemberWithProfile(member: member, profile: profile));
    } else {
      // Nếu không có role hoặc chỉ có @everyone thì đưa vào nhóm TRỰC TUYẾN
      groupsMap[onlineGroupId]!.members.add(MemberWithProfile(member: member, profile: profile));
    }
  }
  
  // Lọc bỏ các nhóm trống và sắp xếp
  final resultGroups = groupsMap.values.where((g) => g.members.isNotEmpty).toList();
  resultGroups.sort((a, b) => a.order.compareTo(b.order));
  
  return AsyncValue.data(resultGroups);
});
