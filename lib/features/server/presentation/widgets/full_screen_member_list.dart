import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'server_member_list_panel.dart';

class FullScreenMemberList extends ConsumerWidget {
  final String serverId;

  const FullScreenMemberList({super.key, required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.interactiveNormal,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Thành viên', style: AppTextStyles.headerPrimary),
      ),
      body: ServerMemberListPanel(serverId: serverId, isMobile: true),
    );
  }
}
