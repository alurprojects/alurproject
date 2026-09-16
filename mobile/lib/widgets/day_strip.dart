import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class DayStrip extends StatelessWidget {
  final String dayName;
  final int taskCount;
  final int shadeIndex;
  final VoidCallback onTap;

  const DayStrip({
    super.key,
    required this.dayName,
    required this.taskCount,
    this.shadeIndex = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shades = isDark ? AppColors.darkDayShades : AppColors.lightDayShades;
    final safeIndex = shadeIndex.clamp(0, shades.length - 1);
    final backgroundColor = shades[safeIndex];

    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final metaColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dayName.toUpperCase(),
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  color: textColor,
                  height: 1.05,
                ),
              ),
              if (taskCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$taskCount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: metaColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
