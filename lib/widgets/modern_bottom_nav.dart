import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/modern_theme.dart';

class ModernBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<ModernNavigationItem> items;

  const ModernBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: ModernTheme.backgroundCard,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(ModernTheme.radiusXL),
          topRight: Radius.circular(ModernTheme.radiusXL),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items.asMap().entries.map((entry) {
              final int index = entry.key;
              final ModernNavigationItem item = entry.value;
              final bool isSelected = index == currentIndex;
              
              return _buildNavItem(
                item: item,
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTap(index);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required ModernNavigationItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? item.activeColor.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(isSelected ? 25 : 25),
          border: isSelected 
              ? Border.all(
                  color: item.activeColor.withOpacity(0.3),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Container
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              width: isSelected ? 28 : 28,
              height: isSelected ? 28 : 28,
              decoration: BoxDecoration(
                color: isSelected 
                    ? item.activeColor
                    : ModernTheme.backgroundElevated,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: item.activeColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Icon(
                item.icon,
                size: 16,
                color: isSelected 
                    ? Colors.white
                    : ModernTheme.textMuted,
              ),
            ),
            
            // Label (only shown when selected)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              child: isSelected ? Container(
                margin: const EdgeInsets.only(left: 6),
                child: Text(
                  item.label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: ModernTheme.bodyMedium.copyWith(
                    color: item.activeColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ) : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class ModernNavigationItem {
  final IconData icon;
  final String label;
  final Color activeColor;

  const ModernNavigationItem({
    required this.icon,
    required this.label,
    required this.activeColor,
  });
}