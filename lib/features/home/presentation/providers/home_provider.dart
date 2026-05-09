import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ID của server đang được chọn trong server list.
/// Null nghĩa là chưa chọn server nào (hiển thị Home/Direct Messages).
final selectedServerIdProvider = StateProvider<String?>((ref) => null);

/// ID của channel đang được chọn.
/// Null nghĩa là chưa chọn channel nào.
final selectedChannelIdProvider = StateProvider<String?>((ref) => null);

/// Tên của server đang chọn (hiển thị trong channel sidebar header).
final selectedServerNameProvider = StateProvider<String>(
  (ref) => 'StarRail Server',
);

/// Cờ điều khiển sidebar channel có bị collapse trên mobile không.
final isChannelSidebarOpenProvider = StateProvider<bool>((ref) => true);
