import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class DayStrip extends StatelessWidget {
  final String dayName;
  final int taskCount;
  final VoidCallback onTap;

  const DayStrip({
    super.key,
    required this.dayName,
    required this.taskCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor =
        isDark ? AppColors.darkSurface : AppColors.paperGray;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.charcoal;
    final metaColor =
        isDark ? AppColors.darkTextSecondary : AppColors.warmGray;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dayName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: textColor,
                  ),
                ),
                if (taskCount > 0)
                  Text(
                    '$taskCount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: metaColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
