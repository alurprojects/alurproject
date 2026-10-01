import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/daily_task.dart';

class DailyTaskRow extends StatelessWidget {
  final DailyTask task;
  final ValueChanged<String> onToggle;

  const DailyTaskRow({super.key, required this.task, required this.onToggle});

  bool get _checkable =>
      task.kind == DailyTaskKind.todo || task.kind == DailyTaskKind.subTodo;

  @override
  Widget build(BuildContext context) {
    final isSub = task.kind == DailyTaskKind.subTodo;

    return Container(
      padding: EdgeInsets.only(
        top: 13,
        bottom: 13,
        left: isSub ? 28 : 0,
        right: 0,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.hairlineGray.withValues(alpha: 0.35)),
        ),
      ),
      child: Row(
        children: [
          // Leading: checkbox atau icon badge
          if (_checkable)
            GestureDetector(
              onTap: () => onToggle(task.id),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: task.completed ? AppColors.inkBlack : Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: task.completed ? AppColors.inkBlack : AppColors.hairlineGray,
                    width: 1.2,
                  ),
                ),
                child: task.completed
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            )
          else
            _IconBadge(icon: task.icon, kind: task.kind),
          const SizedBox(width: 12),
          // Title
          Expanded(
            child: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: isSub ? 13 : 13.5,
                fontWeight: isSub ? FontWeight.w400 : FontWeight.w500,
                color: task.completed
                    ? AppColors.warmGray
                    : (isSub ? AppColors.warmGray : AppColors.charcoal),
                decoration: task.completed ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.warmGray,
                height: 1.0,
              ),
            ),
          ),
          if (task.time != null) ...[
            const SizedBox(width: 8),
            Text(
              task.time!,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
                color: AppColors.warmGray,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final DailyTaskIcon? icon;
  final DailyTaskKind kind;
  const _IconBadge({this.icon, required this.kind});

  @override
  Widget build(BuildContext context) {
    // event / scheduled / ritual
    String glyph;
    Color fg, bg, border;
    switch (icon) {
      case DailyTaskIcon.star:
        glyph = '✦';
        fg = const Color(0xFFE85D3F);
        bg = const Color(0xFFFFF1EE);
        border = const Color(0xFFF3D5CC);
        break;
      case DailyTaskIcon.moon:
        glyph = '☾';
        fg = const Color(0xFF6B5BFF);
        bg = const Color(0xFFF0EEFF);
        border = const Color(0xFFDDD8FF);
        break;
      default:
        glyph = '•';
        fg = AppColors.warmGray;
        bg = AppColors.paperGray;
        border = AppColors.hairlineGray;
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border),
      ),
      alignment: Alignment.center,
      child: Text(
        glyph,
        style: TextStyle(fontSize: 10, color: fg, height: 1),
      ),
    );
  }
}
