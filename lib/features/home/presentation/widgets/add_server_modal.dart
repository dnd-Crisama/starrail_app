import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../server/presentation/screens/create_server_screen.dart';
import '../../../server/presentation/screens/join_server_screen.dart';

void showAddServerModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bgSecondary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.add_circle_outline,
                color: AppColors.white,
              ),
              title: const Text(
                'Tao Server moi',
                style: TextStyle(color: AppColors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateServerScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.group_add_outlined,
                color: AppColors.white,
              ),
              title: const Text(
                'Tham gia Server',
                style: TextStyle(color: AppColors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JoinServerScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}
