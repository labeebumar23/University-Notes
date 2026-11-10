import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class UniBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const UniBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F004AAD),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(
            color: Color(0x0A000000),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.local_library_outlined,
                activeIcon: Icons.local_library,
                label: 'Semesters',
              ),
              _buildRecorderItem(),
              _buildNavItem(
                index: 2,
                icon: Icons.auto_awesome_motion_outlined,
                activeIcon: Icons.auto_awesome_motion,
                label: 'AI Notes',
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.tune,
                activeIcon: Icons.tune,
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.royalBlue : AppColors.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        splashColor: AppColors.lightBlue.withOpacity(0.2),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 23,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecorderItem() {
    final isSelected = currentIndex == 1;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(1),
        splashColor: AppColors.lightBlue.withOpacity(0.2),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: const Offset(0, -6),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.royalBlue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.tertiaryFixedDim.withOpacity(0.5),
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.royalBlue.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -4),
              child: Text(
                'Recorder',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.royalBlue : AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

