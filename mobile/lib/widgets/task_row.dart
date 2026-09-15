import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/task.dart';
import 'follow_up_chip.dart';

class TaskRow extends StatefulWidget {
  final Task task;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int>? onClarify;
  final ValueChanged<String>? onFollowUpAction;
  final ValueChanged<String>? onRescheduleAction;

  const TaskRow({
    super.key,
    required this.task,
    required this.onToggle,
    this.onClarify,
    this.onFollowUpAction,
    this.onRescheduleAction,
  });

  @override
  State<TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends State<TaskRow> {
  bool _isClarifying = false;

  void _submitMinutes(int mins) {
    setState(() {
      _isClarifying = false;
    });
    widget.onClarify?.call(mins);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDone = widget.task.isDone;

    final titleColor = isDone
        ? (isDark ? AppColors.darkTextSecondary : AppColors.warmGray)
        : (isDark ? AppColors.darkTextPrimary : AppColors.charcoal);

    final metaColor =
        isDark ? AppColors.darkTextSecondary : AppColors.warmGray;
    final dividerColor =
        isDark ? AppColors.darkBorder : AppColors.hairlineGray;

    final checkFillColor =
        isDark ? AppColors.darkActiveAccent : AppColors.inkBlack;
    final checkIconColor = isDark ? Colors.black : Colors.white;
    final checkBorderColor =
        isDark ? AppColors.darkTextSecondary : AppColors.hairlineGray;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 20px Custom Circle Checkbox
              GestureDetector(
                onTap: () => widget.onToggle(!isDone),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(right: 14.0),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? checkFillColor : Colors.transparent,
                      border: Border.all(
                        color: isDone ? checkFillColor : checkBorderColor,
                        width: 1.5,
                      ),
                    ),
                    child: isDone
                        ? Center(
                            child: Icon(
                              Icons.check,
                              size: 14,
                              color: checkIconColor,
                            ),
                          )
                        : null,
                  ),
                ),
              ),

              // Task Title
              Expanded(
                child: Text(
                  widget.task.title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    decorationColor: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.warmGray,
                  ),
                ),
              ),

              // Duration tag if present
              if (widget.task.estimatedMinutes != null && !widget.task.isAmbiguous) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '${widget.task.estimatedMinutes}m',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: metaColor,
                    ),
                  ),
                ),
              ],

              // Ambiguous marker (?)
              if (widget.task.isAmbiguous) ...[
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isClarifying = !_isClarifying;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.paperGray,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '(?)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.warmGray,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Inline Clarification Row (Bukan modal, bukan chat)
        if (_isClarifying && widget.task.isAmbiguous) ...[
          Padding(
            padding: const EdgeInsets.only(left: 36.0, bottom: 12.0),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Text(
                  'Berapa lama?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: metaColor,
                  ),
                ),
                for (final mins in [15, 30, 45, 60])
                  GestureDetector(
                    onTap: () => _submitMinutes(mins),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.hairlineGray,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.paperGray,
                      ),
                      child: Text(
                        '${mins}m',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.charcoal,
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: metaColor,
                  onPressed: () {
                    setState(() {
                      _isClarifying = false;
                    });
                  },
                ),
              ],
            ),
          ),
        ],

        // Follow-Up Chip (Bila missed_follow_up == 'PENDING')
        if (widget.task.hasPendingFollowUp && widget.onFollowUpAction != null) ...[
          FollowUpChip(
            task: widget.task,
            onAction: widget.onFollowUpAction!,
          ),
        ],

        // Reschedule Suggestion Banner (Bila ada suggestion PENDING)
        if (widget.task.hasPendingSuggestion && widget.onRescheduleAction != null) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(left: 36, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.paperGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'AI sarankan pindah ke ${widget.task.suggestion!.suggestedDate}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.charcoal,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => widget.onRescheduleAction!('ACCEPT'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Terima',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkActiveAccent : AppColors.inkBlack,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text('·', style: TextStyle(color: metaColor)),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => widget.onRescheduleAction!('REJECT'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Abaikan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: metaColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // 1px Divider
        Divider(
          height: 1,
          thickness: 1,
          color: dividerColor,
        ),
      ],
    );
  }
}
