import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/daily_task.dart';

/// Strip 7 hari — replikasi 1:1 dari gambar.
/// Active = Ink Black, inactive = warmOffWhite.
class DailyDayStrip extends StatelessWidget {
  final List<DailyDay> days;
  final ValueChanged<int> onSelect;

  const DailyDayStrip({super.key, required this.days, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.hairlineGray.withValues(alpha: 0.5)),
          bottom: BorderSide(color: AppColors.hairlineGray.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: days.map((d) {
          final active = d.isActive;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(d.date),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: active ? AppColors.inkBlack : AppColors.warmOffWhite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${d.date}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: active ? Colors.white : AppColors.warmGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d.label,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: active ? const Color(0xFFFF6B6B) : AppColors.warmGray,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
