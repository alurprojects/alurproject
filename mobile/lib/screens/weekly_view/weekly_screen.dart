import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/task.dart';
import '../../services/api_service.dart';
import '../../widgets/day_block.dart';
import '../../widgets/day_strip.dart';

class WeeklyScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const WeeklyScreen({
    super.key,
    required this.apiService,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<WeeklyScreen> createState() => _WeeklyScreenState();
}

class _WeeklyScreenState extends State<WeeklyScreen> {
  late DateTime _currentMonday;
  WeekData? _weekData;
  List<Insight> _insights = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _expandedDayIndex = -1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonday = now.subtract(Duration(days: now.weekday - 1));
    _loadWeek();
  }

  Future<void> _loadWeek() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final weekDateStr = DateFormat('yyyy-MM-dd').format(_currentMonday);
    try {
      final data = await widget.apiService.fetchWeekTasks(weekDate: weekDateStr);
      final insights = await widget.apiService.fetchInsights();
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Find index of today or default to Monday (0)
      int todayIdx = data.days.indexWhere((d) => d.date == todayStr);
      if (todayIdx == -1) {
        todayIdx = 0;
      }

      setState(() {
        _weekData = data;
        _insights = insights;
        _isLoading = false;
        _expandedDayIndex = todayIdx;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _previousWeek() {
    setState(() {
      _currentMonday = _currentMonday.subtract(const Duration(days: 7));
    });
    _loadWeek();
  }

  void _nextWeek() {
    setState(() {
      _currentMonday = _currentMonday.add(const Duration(days: 7));
    });
    _loadWeek();
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonday = now.subtract(Duration(days: now.weekday - 1));
    });
    _loadWeek();
  }

  Future<void> _toggleTaskStatus(Task task, bool isDone) async {
    if (_weekData == null) return;

    // Optimistic UI update
    final updatedTask = task.copyWith(status: isDone ? 'DONE' : 'PENDING');
    setState(() {
      final day = _weekData!.days[_expandedDayIndex];
      final newTasks = day.tasks.map((t) => t.id == task.id ? updatedTask : t).toList();
      _weekData!.days[_expandedDayIndex] = day.copyWith(tasks: newTasks);
    });

    try {
      await widget.apiService.toggleTaskStatus(taskId: task.id, isDone: isDone);
    } catch (e) {
      // Revert on failure
      setState(() {
        final day = _weekData!.days[_expandedDayIndex];
        final revertedTasks = day.tasks.map((t) => t.id == task.id ? task : t).toList();
        _weekData!.days[_expandedDayIndex] = day.copyWith(tasks: revertedTasks);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update task: $e')),
        );
      }
    }
  }

  Future<void> _handleAddTask(String dayDate, String title) async {
    try {
      final newTask = await widget.apiService.createTask(
        title: title,
        assignedDate: dayDate,
      );

      setState(() {
        final day = _weekData!.days[_expandedDayIndex];
        _weekData!.days[_expandedDayIndex] = day.copyWith(
          tasks: [...day.tasks, newTask],
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create task: $e')),
        );
      }
    }
  }

  Future<void> _handleClarifyTask(Task task, int minutes) async {
    if (_weekData == null) return;

    // Optimistic UI update
    final updatedTask = task.copyWith(
      estimatedMinutes: minutes,
      isAmbiguous: false,
    );
    setState(() {
      final day = _weekData!.days[_expandedDayIndex];
      final newTasks = day.tasks.map((t) => t.id == task.id ? updatedTask : t).toList();
      _weekData!.days[_expandedDayIndex] = day.copyWith(tasks: newTasks);
    });

    try {
      await widget.apiService.clarifyTask(
        taskId: task.id,
        estimatedMinutes: minutes,
      );
    } catch (e) {
      _loadWeek();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clarify task: $e')),
        );
      }
    }
  }

  Future<void> _handleFollowUp(Task task, String action) async {
    try {
      await widget.apiService.followUpTask(taskId: task.id, action: action);
      _loadWeek();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to follow up: $e')),
        );
      }
    }
  }

  Future<void> _handleReschedule(Task task, String action) async {
    if (task.suggestion == null) return;
    try {
      await widget.apiService.respondReschedule(
        taskId: task.id,
        suggestionId: task.suggestion!.id,
        action: action,
      );
      _loadWeek();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reschedule: $e')),
        );
      }
    }
  }

  void _openBrainDumpSheet() {
    final textController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDarkMode ? AppColors.darkSurface : AppColors.warmOffWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = widget.isDarkMode;
            final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.charcoal;
            final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.warmGray;
            final border = OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.hairlineGray,
              ),
            );

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'BRAIN-DUMP',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: primaryTextColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: secondaryTextColor),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dump your thoughts freely. AI will extract tasks, detect duration, and schedule them into your week.',
                    style: TextStyle(
                      fontSize: 13,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    autofocus: true,
                    maxLines: 4,
                    minLines: 3,
                    style: TextStyle(
                      fontSize: 15,
                      color: primaryTextColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Besok lari pagi 30 menit, riset desain to-do app, beli kopi',
                      hintStyle: TextStyle(color: secondaryTextColor),
                      enabledBorder: border,
                      focusedBorder: border.copyWith(
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkActiveAccent : AppColors.inkBlack,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.darkActiveAccent : AppColors.inkBlack,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final text = textController.text.trim();
                              if (text.isEmpty) return;

                              setModalState(() {
                                isSubmitting = true;
                              });

                              try {
                                await widget.apiService.brainDump(text: text);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                                _loadWeek();
                              } catch (e) {
                                setModalState(() {
                                  isSubmitting = false;
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Brain-dump error: $e')),
                                  );
                                }
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Process Brain-dump',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.charcoal;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.warmGray;

    final weekRangeText = _weekData != null
        ? '${DateFormat('MMM d').format(DateTime.parse(_weekData!.weekStart))} – ${DateFormat('MMM d, yyyy').format(DateTime.parse(_weekData!.weekEnd))}'
        : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ALUR',
          style: TextStyle(
            letterSpacing: 2.0,
            fontWeight: FontWeight.w900,
            color: primaryTextColor,
          ),
        ),
        actions: [
          // Today jump button
          TextButton(
            onPressed: _goToToday,
            child: Text(
              'Today',
              style: TextStyle(
                color: primaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Theme switch toggle (prominent, not hidden)
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: primaryTextColor,
            ),
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.charcoal,
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Unable to load planner',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: secondaryTextColor),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadWeek,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.darkActiveAccent : AppColors.inkBlack,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Surfaced Weekly Insight Banner (if available)
                    if (_insights.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.paperGray,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.hairlineGray,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💡 ', style: TextStyle(fontSize: 14)),
                            Expanded(
                              child: Text(
                                _insights.first.content,
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
                      ),

                    // Week Selector Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_ios, size: 16, color: primaryTextColor),
                            onPressed: _previousWeek,
                          ),
                          Text(
                            weekRangeText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: secondaryTextColor,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_forward_ios, size: 16, color: primaryTextColor),
                            onPressed: _nextWeek,
                          ),
                        ],
                      ),
                    ),

                    // 7-day Accordion List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                        itemCount: _weekData?.days.length ?? 0,
                        itemBuilder: (context, index) {
                          final day = _weekData!.days[index];
                          final isExpanded = index == _expandedDayIndex;

                          return AnimatedCrossFade(
                            duration: const Duration(milliseconds: 250),
                            firstCurve: Curves.easeInOut,
                            secondCurve: Curves.easeInOut,
                            crossFadeState: isExpanded
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                            firstChild: DayBlock(
                              dayData: day,
                              onToggleTask: _toggleTaskStatus,
                              onAddTask: (title) => _handleAddTask(day.date, title),
                              onClarifyTask: _handleClarifyTask,
                              onFollowUpAction: _handleFollowUp,
                              onRescheduleAction: _handleReschedule,
                              onOpenBrainDump: _openBrainDumpSheet,
                            ),
                            secondChild: DayStrip(
                              dayName: day.dayName,
                              taskCount: day.tasks.length,
                              onTap: () {
                                setState(() {
                                  _expandedDayIndex = index;
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
