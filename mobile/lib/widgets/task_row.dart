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

    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final metaColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final checkboxBorderColor =
        isDark ? AppColors.darkCheckboxBorder : AppColors.lightCheckboxBorder;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Checkbox (fills solid pure black on completion, white check icon)
              GestureDetector(
                onTap: () => widget.onToggle(!isDone),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? (isDark ? AppColors.pureWhite : AppColors.pureBlack)
                          : Colors.transparent,
                      border: Border.all(
                        color: isDone
                            ? (isDark ? AppColors.pureWhite : AppColors.pureBlack)
                            : checkboxBorderColor,
                        width: 1.5,
                      ),
                    ),
                    child: isDone
                        ? Center(
                            child: Icon(
                              Icons.check,
                              size: 13,
                              color: isDark ? AppColors.pureBlack : AppColors.pureWhite,
                              weight: 900,
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
                    color: isDone ? metaColor : primaryTextColor,
                    fontSize: 15.5,
                    fontWeight: isDone ? FontWeight.w400 : FontWeight.w500,
                    letterSpacing: -0.1,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    decorationColor: metaColor,
                    decorationThickness: 1.5,
                  ),
                ),
              ),

              // Duration tag if present and not ambiguous
              if (widget.task.estimatedMinutes != null && !widget.task.isAmbiguous) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Text(
                    '${widget.task.estimatedMinutes}m',
                    style: TextStyle(
                      fontSize: 12.5,
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      '(?)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: metaColor,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Inline Clarification Row
          if (_isClarifying && widget.task.isAmbiguous) ...[
            Padding(
              padding: const EdgeInsets.only(left: 30.0, top: 6.0, bottom: 4.0),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'Berapa lama?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: metaColor,
                    ),
                  ),
                  for (final mins in [15, 30, 45, 60])
                    GestureDetector(
                      onTap: () => _submitMinutes(mins),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: checkboxBorderColor.withValues(alpha: 0.5),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.transparent,
                        ),
                        child: Text(
                          '${mins}m',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 14),
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

          // Follow-Up Chip (When missed_follow_up == 'PENDING')
          if (widget.task.hasPendingFollowUp && widget.onFollowUpAction != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 30.0, top: 4.0),
              child: FollowUpChip(
                task: widget.task,
                onAction: widget.onFollowUpAction!,
              ),
            ),
          ],

          // Reschedule Suggestion Banner
          if (widget.task.hasPendingSuggestion && widget.onRescheduleAction != null) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(left: 30, top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkDayShades[0] : AppColors.lightDayShades[0],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'AI sarankan pindah ke ${widget.task.suggestion!.suggestedDate}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: primaryTextColor,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => widget.onRescheduleAction!('ACCEPT'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'Terima',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                    ),
                  ),
                  Text(' · ', style: TextStyle(color: metaColor)),
                  GestureDetector(
                    onTap: () => widget.onRescheduleAction!('REJECT'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'Abaikan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: metaColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
