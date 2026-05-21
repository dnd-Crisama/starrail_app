import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'server_member_list_panel.dart';

class CollapsibleServerMemberList extends ConsumerStatefulWidget {
  final String serverId;
  final bool isMobile;

  const CollapsibleServerMemberList({
    super.key,
    required this.serverId,
    this.isMobile = false,
  });

  @override
  ConsumerState<CollapsibleServerMemberList> createState() =>
      _CollapsibleServerMemberListState();
}

class _CollapsibleServerMemberListState
    extends ConsumerState<CollapsibleServerMemberList>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded = !widget.isMobile; // Desktop mở mặc định, mobile đóng
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Nếu desktop thì mở luôn
    if (!widget.isMobile) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(CollapsibleServerMemberList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nếu chuyển từ desktop sang mobile hoặc ngược lại, cập nhật trạng thái
    if (oldWidget.isMobile != widget.isMobile) {
      if (widget.isMobile && _isExpanded) {
        // Chuyển sang mobile, mở panel nên di chuyển vào trạng thái mở
      } else if (!widget.isMobile && !_isExpanded) {
        // Chuyển sang desktop, đóng panel nên di chuyển vào trạng thái đóng
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nếu desktop, hiện trực tiếp panel mà không cần toggle
    if (!widget.isMobile) {
      return ServerMemberListPanel(serverId: widget.serverId, isMobile: false);
    }

    // Nếu mobile, hiện header + panel có thể đóng mở
    return Container(
      color: AppColors.bgSecondary,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header với nút toggle
          Material(
            color: AppColors.bgSecondary,
            child: InkWell(
              onTap: _toggleExpanded,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Thành viên',
                        style: AppTextStyles.textNormal.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle:
                              _expandAnimation.value *
                              3.14159 /
                              2, // 0 to 90 degrees
                          child: Icon(
                            Icons.expand_more,
                            color: AppColors.interactiveNormal,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Divider
          Container(height: 1, color: AppColors.bgTertiary),
          // Animated member list panel
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: _expandAnimation.value,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(context).size.height *
                      0.6, // Max 60% chiều cao màn hình
                ),
                child: ServerMemberListPanel(
                  serverId: widget.serverId,
                  isMobile: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
