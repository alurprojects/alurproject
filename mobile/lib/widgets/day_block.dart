import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../models/task.dart';
import 'task_row.dart';

class DayBlock extends StatefulWidget {
  final DayData dayData;
  final Function(Task task, bool isDone) onToggleTask;
  final Function(String title) onAddTask;
  final Function(Task task, int minutes)? onClarifyTask;
  final Function(Task task, String action)? onFollowUpAction;
  final Function(Task task, String action)? onRescheduleAction;
  final VoidCallback? onOpenBrainDump;

  const DayBlock({
    super.key,
    required this.dayData,
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

  String _formatDateMeta(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('MMMM, d yyyy').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final h1Color =
        isDark ? AppColors.darkTextPrimary : AppColors.charcoal;
    final metaColor =
        isDark ? AppColors.darkTextSecondary : AppColors.warmGray;
    final inputBorderColor =
        isDark ? AppColors.darkBorder : AppColors.hairlineGray;
    final activeBorderColor =
        isDark ? AppColors.darkActiveAccent : AppColors.inkBlack;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // H1 Day Header
          Text(
            widget.dayData.dayName.toUpperCase(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: h1Color,
            ),
          ),
          const SizedBox(height: 4),

          // Date Meta Line
          Text(
            _formatDateMeta(widget.dayData.date),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: metaColor,
            ),
          ),
          const SizedBox(height: 16),

          // Task List
          if (widget.dayData.tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'No tasks scheduled for today.',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: metaColor,
                ),
              ),
            )
          else
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

          const SizedBox(height: 16),

          // Inline Add Task / Brain-dump Row
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
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.charcoal,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Task name...',
                      hintStyle: TextStyle(color: metaColor),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: inputBorderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: activeBorderColor),
                      ),
                    ),
                    onSubmitted: (_) => _submitTask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _submitTask,
                  icon: Icon(
                    Icons.check,
                    color: activeBorderColor,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isAdding = false;
                      _textController.clear();
                    });
                  },
                  icon: Icon(
                    Icons.close,
                    color: metaColor,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                // Add task text button
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isAdding = true;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add,
                            size: 18,
                            color: metaColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Add a new task...',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: metaColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Brain-dump Pill Button (from DESIGN.md)
                if (widget.onOpenBrainDump != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onOpenBrainDump,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkActiveAccent
                            : AppColors.inkBlack,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.mic_none,
                            size: 16,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Brain-dump',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
