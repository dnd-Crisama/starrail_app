import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ID của server đang được chọn trong server list.
/// Null nghĩa là chưa chọn server nào (hiển thị Home/Direct Messages).
/// Sẽ được dùng bởi HomeScreen để highlight server icon và load channels.
final selectedServerIdProvider = StateProvider<String?>((ref) => null);

/// ID của channel đang được chọn.
/// Null nghĩa là chưa chọn channel nào.
/// Sẽ được dùng bởi HomeScreen để highlight channel và load messages.
final selectedChannelIdProvider = StateProvider<String?>((ref) => null);

/// Tên của server đang chọn (hiển thị trong channel sidebar header).
/// Sẽ được thay bằng data thật từ Firestore trong Part 4.
final selectedServerNameProvider = StateProvider<String>(
  (ref) => 'StarRail Serverr',
);

/// Cờ điều khiển sidebar channel có bị collapse trên mobile không.
final isChannelSidebarOpenProvider = StateProvider<bool>((ref) => true);
