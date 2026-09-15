import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/task.dart';

class FollowUpChip extends StatelessWidget {
  final Task task;
  final ValueChanged<String> onAction;

  const FollowUpChip({
    super.key,
    required this.task,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bannerBg = isDark ? AppColors.darkSurface : AppColors.paperGray;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.charcoal;
    final metaColor = isDark ? AppColors.darkTextSecondary : AppColors.warmGray;
    final pillBorderColor = isDark ? AppColors.darkBorder : AppColors.hairlineGray;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: pillBorderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💬 ',
                style: TextStyle(fontSize: 14),
              ),
              Expanded(
                child: Text(
                  '"${task.title}" kemarin gak dicentang — lupa atau emang skip?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: primaryTextColor,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPillButton(
                label: 'Udah, lupa centang',
                onTap: () => onAction('FORGOT'),
                isDark: isDark,
                borderColor: pillBorderColor,
                textColor: primaryTextColor,
              ),
              _buildPillButton(
                label: 'Emang skip',
                onTap: () => onAction('SKIPPED'),
                isDark: isDark,
                borderColor: pillBorderColor,
                textColor: metaColor,
              ),
              _buildPillButton(
                label: 'Pindah ke hari ini',
                onTap: () => onAction('RESCHEDULED'),
                isDark: isDark,
                borderColor: isDark ? AppColors.darkActiveAccent : AppColors.inkBlack,
                textColor: isDark ? AppColors.darkActiveAccent : AppColors.inkBlack,
                isHighlight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton({
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required Color borderColor,
    required Color textColor,
    bool isHighlight = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
          color: isHighlight
              ? (isDark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(10))
              : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
