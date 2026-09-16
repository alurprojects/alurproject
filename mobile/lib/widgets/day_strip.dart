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
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    dayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      color: textColor,
                      height: 1.05,
                    ),
                  ),
                ),
              ),
              if (taskCount > 0)
                Text(
                  '$taskCount',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: metaColor.withValues(alpha: 0.45),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
