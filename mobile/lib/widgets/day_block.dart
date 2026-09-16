import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/task.dart';
import 'task_row.dart';

class DayBlock extends StatefulWidget {
  final DayData dayData;
  final int shadeIndex;
  final Function(Task task, bool isDone) onToggleTask;
  final Function(String title) onAddTask;
  final Function(Task task, int minutes)? onClarifyTask;
  final Function(Task task, String action)? onFollowUpAction;
  final Function(Task task, String action)? onRescheduleAction;
  final VoidCallback? onOpenBrainDump;

  const DayBlock({
    super.key,
    required this.dayData,
    this.shadeIndex = 0,
    required this.onToggleTask,
    required this.onAddTask,
    this.onClarifyTask,
    this.onFollowUpAction,
    this.onRescheduleAction,
    this.onOpenBrainDump,
  });

  @override
  State<DayBlock> createState() => _DayBlockState();
}

class _DayBlockState extends State<DayBlock> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isAdding = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitTask() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onAddTask(text);
      _textController.clear();
      setState(() {
        _isAdding = false;
      });
    }
  }

  String _formatDateSubtitle(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      final dateFormatted = DateFormat('MMMM, d yyyy').format(parsed);
      final now = DateTime.now();
      final timeFormatted = DateFormat('h:mma').format(now).toLowerCase();
      return '$dateFormatted – $timeFormatted';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shades = isDark ? AppColors.darkDayShades : AppColors.lightDayShades;
    final safeIndex = widget.shadeIndex.clamp(0, shades.length - 1);
    final backgroundColor = shades[safeIndex];

    final primaryTextColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final placeholderColor =
        isDark ? AppColors.darkTextPlaceholder : AppColors.lightTextPlaceholder;

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header H1 (ExtraBold, all caps)
          Text(
            widget.dayData.dayName.toUpperCase(),
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
              color: primaryTextColor,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 5),

          // Date & Time Subtitle (e.g. April, 14 2025 – 9:41am)
          Text(
            _formatDateSubtitle(widget.dayData.date),
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: secondaryTextColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 22),

          // Task Rows
          if (widget.dayData.tasks.isNotEmpty) ...[
            ...widget.dayData.tasks.map(
              (task) => TaskRow(
                key: ValueKey(task.id),
                task: task,
                onToggle: (isDone) => widget.onToggleTask(task, isDone),
                onClarify: (mins) => widget.onClarifyTask?.call(task, mins),
                onFollowUpAction: (act) => widget.onFollowUpAction?.call(task, act),
                onRescheduleAction: (act) => widget.onRescheduleAction?.call(task, act),
              ),
            ),
          ],

          // Generous breathing space between checkbox tasks and "Add a new task..." (~48px)
          const SizedBox(height: 48),

          // "Add a new task..." input or prompt
          if (_isAdding)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    autofocus: true,
                    style: TextStyle(
                      fontSize: 15,
                      color: primaryTextColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add a new task...',
                      hintStyle: TextStyle(
                        color: placeholderColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    onSubmitted: (_) => _submitTask(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.check, size: 18, color: primaryTextColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _submitTask,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: secondaryTextColor),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      _isAdding = false;
                      _textController.clear();
                    });
                  },
                ),
              ],
            )
          else
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isAdding = true;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Text(
                      'Add a new task...',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        color: placeholderColor,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                if (widget.onOpenBrainDump != null)
                  GestureDetector(
                    onTap: widget.onOpenBrainDump,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.mic_none,
                            size: 16,
                            color: placeholderColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Brain-dump',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: placeholderColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
