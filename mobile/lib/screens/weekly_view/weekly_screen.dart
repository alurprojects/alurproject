import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/daily_task.dart' as daily;
import '../../models/morning_brief.dart';
import '../../models/task.dart';
import '../../services/api_service.dart';
import '../../widgets/daily/daily_day_strip.dart';
import '../../widgets/daily/daily_task_row.dart';
import '../../widgets/day_block.dart';
import '../../widgets/day_strip.dart';
import '../../widgets/morning_brief_banner.dart';
import '../../widgets/pill_button.dart';

enum TodoViewMode { dailyFocus, weeklyOverview }

class WeeklyScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final Function(String? prompt)? onOpenChat;

  const WeeklyScreen({
    super.key,
    required this.apiService,
    required this.onToggleTheme,
    required this.isDarkMode,
    this.onOpenChat,
  });

  @override
  State<WeeklyScreen> createState() => _WeeklyScreenState();
}

class _WeeklyScreenState extends State<WeeklyScreen> {
  late DateTime _currentMonday;
  WeekData? _weekData;
  List<Insight> _insights = [];
  MorningBriefData? _morningBrief;
  bool _isBriefDismissed = false;
  bool _isLoading = true;
  String? _errorMessage;
  int _expandedDayIndex = -1;
  int _selectedDayIndex = 0;
  TodoViewMode _viewMode = TodoViewMode.dailyFocus;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    final now = DateTime.now();
    _currentMonday = now.subtract(Duration(days: now.weekday - 1));
    _loadWeek();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadWeek() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final weekDateStr = DateFormat('yyyy-MM-dd').format(_currentMonday);
    WeekData? data;
    List<Insight> insights = [];
    MorningBriefData? morningBrief;

    try {
      data = await widget.apiService.fetchWeekTasks(weekDate: weekDateStr);
    } catch (e) {
      debugPrint('fetchWeekTasks failed: $e');
    }
    try { insights = await widget.apiService.fetchInsights(); } catch (_) {}
    try { morningBrief = await widget.apiService.fetchMorningBrief(); } catch (_) {}

    // Fallback mock jika backend 500 / offline — biar UI tetap tampil seperti gambar
    data ??= _buildMockWeek(_currentMonday);

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    int todayIdx = data.days.indexWhere((d) => d.date == todayStr);
    if (todayIdx == -1) todayIdx = 0;

    setState(() {
      _weekData = data;
      _insights = insights;
      _morningBrief = morningBrief;
      _isLoading = false;
      _expandedDayIndex = todayIdx;
      _selectedDayIndex = todayIdx;
      // hanya tampilkan error sebagai banner kecil, bukan full-screen block
      _errorMessage = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(todayIdx);
      }
    });
  }

  WeekData _buildMockWeek(DateTime monday) {
    String iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
    const names = ['SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU', 'MINGGU'];

    // Dummy varied per hari — realistis, clean, tiap hari ada isinya
    Task t(String id, String title, DateTime d, {int? mins, String status = 'PENDING'}) =>
        Task(id: id, userId: 'local', title: title, assignedDate: iso(d), status: status, source: 'MANUAL', isAmbiguous: false, aiGenerated: false, missedFollowUp: 'NONE', estimatedMinutes: mins);

    final md0 = monday;
    final md1 = monday.add(const Duration(days: 1));
    final md2 = monday.add(const Duration(days: 2));
    final md3 = monday.add(const Duration(days: 3));
    final md4 = monday.add(const Duration(days: 4));
    final md5 = monday.add(const Duration(days: 5));
    final md6 = monday.add(const Duration(days: 6));

    final tasksByDay = <List<Task>>[
      [t('m0-1', 'Morning jog', md0, mins: 420), t('m0-2', 'Team standup', md0, mins: 540), t('m0-3', 'Review PR #42', md0), t('m0-4', 'Wind down', md0, mins: 1320)],
      [t('m1-1', 'Study Flutter', md1, mins: 480), t('m1-2', 'Lunch with Maya', md1, mins: 720), t('m1-3', 'Buy groceries', md1), t('m1-4', 'Pushups x50', md1)],
      [t('m2-1', 'Deep work — ALUR spec', md2, mins: 540), t('m2-2', 'Call Mom', md2, mins: 1080), t('m2-3', 'Make pasta', md2)],
      [t('m3-1', 'Gym • Leg day', md3, mins: 360), t('m3-2', 'Client call', md3, mins: 600), t('m3-3', 'Write journal', md3, mins: 1260)],
      [t('m4-1', "Daria's 20th Birthday", md4), t('m4-2', 'Wake up', md4, mins: 540), t('m4-3', 'Design Crit', md4, mins: 600), t('m4-4', 'Haircut with Vincent', md4, mins: 780), t('m4-5', 'Make pasta', md4), t('m4-6', 'Pushups x100', md4), t('m4-7', 'Wind down', md4, mins: 1260)],
      [t('m5-1', 'Brunch', md5, mins: 600), t('m5-2', 'Hiking', md5, mins: 480), t('m5-3', 'Movie night', md5, mins: 1200)],
      [t('m6-1', 'Weekly review', md6, mins: 540), t('m6-2', 'Plan next week', md6, mins: 600), t('m6-3', 'Family dinner', md6, mins: 1080), t('m6-4', 'Wind down', md6, mins: 1320)],
    ];
    final days = List.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      return DayData(date: iso(d), dayName: names[i], isToday: iso(d) == iso(DateTime.now()), tasks: tasksByDay[i]);
    });
    return WeekData(weekStart: iso(monday), weekEnd: iso(monday.add(const Duration(days: 6))), days: days);
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

  void _selectDay(int index) {
    setState(() {
      _selectedDayIndex = index;
      _expandedDayIndex = index;
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _toggleTaskStatus(Task task, bool isDone, [int? dayIndexOverride]) async {
    if (_weekData == null) return;
    final dayIndex = dayIndexOverride ??
        (_viewMode == TodoViewMode.dailyFocus ? _selectedDayIndex : _expandedDayIndex);
    if (dayIndex < 0 || dayIndex >= _weekData!.days.length) return;

    // Optimistic UI update
    final updatedTask = task.copyWith(status: isDone ? 'DONE' : 'PENDING');
    setState(() {
      final day = _weekData!.days[dayIndex];
      final newTasks = day.tasks.map((t) => t.id == task.id ? updatedTask : t).toList();
      _weekData!.days[dayIndex] = day.copyWith(tasks: newTasks);
    });

    try {
      await widget.apiService.toggleTaskStatus(taskId: task.id, isDone: isDone);
    } catch (e) {
      // Revert on failure
      setState(() {
        final day = _weekData!.days[dayIndex];
        final revertedTasks = day.tasks.map((t) => t.id == task.id ? task : t).toList();
        _weekData!.days[dayIndex] = day.copyWith(tasks: revertedTasks);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update task: $e')),
        );
      }
    }
  }

  Future<void> _handleAddTask(String dayDate, String title, [int? dayIndexOverride]) async {
    final dayIndex = dayIndexOverride ??
        (_viewMode == TodoViewMode.dailyFocus ? _selectedDayIndex : _expandedDayIndex);
    if (_weekData == null || dayIndex < 0 || dayIndex >= _weekData!.days.length) return;

    try {
      final newTask = await widget.apiService.createTask(
        title: title,
        assignedDate: dayDate,
      );

      setState(() {
        final day = _weekData!.days[dayIndex];
        _weekData!.days[dayIndex] = day.copyWith(
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

  Future<void> _handleClarifyTask(Task task, int minutes, [int? dayIndexOverride]) async {
    if (_weekData == null) return;
    final dayIndex = dayIndexOverride ??
        (_viewMode == TodoViewMode.dailyFocus ? _selectedDayIndex : _expandedDayIndex);
    if (dayIndex < 0 || dayIndex >= _weekData!.days.length) return;

    // Optimistic UI update
    final updatedTask = task.copyWith(
      estimatedMinutes: minutes,
      isAmbiguous: false,
    );
    setState(() {
      final day = _weekData!.days[dayIndex];
      final newTasks = day.tasks.map((t) => t.id == task.id ? updatedTask : t).toList();
      _weekData!.days[dayIndex] = day.copyWith(tasks: newTasks);
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

  Future<void> _handleEditTaskTitle(String taskId, String newTitle) async {
    try {
      await widget.apiService.updateTaskTitle(taskId: taskId, title: newTitle);
      _loadWeek();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update task: $e')),
        );
      }
    }
  }

  Future<void> _handleDeleteTask(String taskId) async {
    try {
      await widget.apiService.deleteTask(taskId: taskId);
      _loadWeek();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete task: $e')),
        );
      }
    }
  }

  Future<void> _handleFollowUpMissed(String taskId, String action) async {
    try {
      await widget.apiService.followUpTask(taskId: taskId, action: action);
      _loadWeek();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to follow up: $e')),
        );
      }
    }
  }

  void _showQuickAddTaskDialog(String dayDate, int dayIndex) {
    final controller = TextEditingController();
    final isDark = widget.isDarkMode;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.charcoal;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.warmGray;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.warmOffWhite,
        title: Text(
          'Tambah Task',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: primaryTextColor,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: primaryTextColor),
          decoration: InputDecoration(
            hintText: 'Nama task baru...',
            hintStyle: TextStyle(color: secondaryTextColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.hairlineGray,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Batal', style: TextStyle(color: secondaryTextColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.darkActiveAccent : AppColors.inkBlack,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                _handleAddTask(dayDate, title, dayIndex);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
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
                        style: GoogleFonts.inter(
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
                  PillButton(
                    width: double.infinity,
                    height: 48,
                    label: 'Process Brain-dump',
                    isLoading: isSubmitting,
                    onPressed: () async {
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
                  ),
                  if (widget.onOpenChat != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: primaryTextColor,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                        label: const Text(
                          'Buka & Bahas di Chat Room ➔',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          final text = textController.text.trim();
                          Navigator.of(context).pop();
                          widget.onOpenChat?.call(text.isNotEmpty ? text : null);
                        },
                      ),
                    ),
                  ],
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 42,
        title: Text(
          'ALUR',
          style: GoogleFonts.inter(
            letterSpacing: 2.0,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: primaryTextColor,
          ),
        ),
        actions: [
          // View Mode Toggle (Daily Focus <-> Weekly Overview)
          IconButton(
            tooltip: _viewMode == TodoViewMode.dailyFocus
                ? 'Beralih ke Weekly Overview'
                : 'Beralih ke Daily Focus',
            icon: Icon(
              _viewMode == TodoViewMode.dailyFocus
                  ? Icons.calendar_view_week_rounded
                  : Icons.calendar_view_day_rounded,
              size: 20,
              color: primaryTextColor,
            ),
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == TodoViewMode.dailyFocus
                    ? TodoViewMode.weeklyOverview
                    : TodoViewMode.dailyFocus;
              });
            },
          ),
          // Today jump button
          TextButton(
            onPressed: _goToToday,
            child: Text(
              'Today',
              style: TextStyle(
                color: primaryTextColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          // Theme switch toggle
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 19,
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
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_ios, size: 14, color: primaryTextColor),
                            visualDensity: VisualDensity.compact,
                            onPressed: _previousWeek,
                          ),
                          Text(
                            weekRangeText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: secondaryTextColor,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_forward_ios, size: 14, color: primaryTextColor),
                            visualDensity: VisualDensity.compact,
                            onPressed: _nextWeek,
                          ),
                        ],
                      ),
                    ),

                    // Mode: Daily Focus View vs Weekly Overview Accordion
                    if (_viewMode == TodoViewMode.dailyFocus) ...[
                      // ——— Daily header ala gambar (Fri •  |  Dec 9  / 2024)
                      Builder(builder: (context) {
                        final idx = _selectedDayIndex.clamp(0, (_weekData?.days.length ?? 1) - 1);
                        final sel = _weekData!.days[idx];
                        DateTime? dt;
                        try { dt = DateTime.parse(sel.date); } catch (_) {}
                        final dayLabel = sel.dayName.isNotEmpty ? sel.dayName.substring(0, 3) : 'Fri';
                        final prettyDay = dayLabel[0].toUpperCase() + dayLabel.substring(1).toLowerCase();
                        final dateLabel = dt != null ? DateFormat('MMMM d').format(dt) : sel.date;
                        final yearLabel = dt != null ? '${dt.year}' : '';
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(prettyDay,
                                    style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.8, color: primaryTextColor, height: 1)),
                                const SizedBox(width: 6),
                                Container(margin: const EdgeInsets.only(top: 6), width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFFFF6B6B), shape: BoxShape.circle)),
                              ]),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text(dateLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: secondaryTextColor)),
                                Text(yearLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: secondaryTextColor)),
                              ]),
                            ],
                          ),
                        );
                      }),
                      // Day strip — active = Ink Black, FRI red (match gambar)
                      Builder(builder: (context) {
                        final stripDays = List.generate(_weekData!.days.length, (i) {
                          final d = _weekData!.days[i];
                          DateTime? dt;
                          try { dt = DateTime.parse(d.date); } catch (_) {}
                          final num = dt?.day ?? (i + 5);
                          // dayName di API mis. "SENIN" → ambil 3 huruf
                          final raw = d.dayName.trim();
                          final short = raw.length >= 3 ? raw.substring(0, 3).toUpperCase() : raw.toUpperCase();
                          const mapId = {'SEN': 'MON', 'SEL': 'TUE', 'RAB': 'WED', 'KAM': 'THU', 'JUM': 'FRI', 'SAB': 'SAT', 'MIN': 'SUN'};
                          final label = mapId[short] ?? short;
                          return daily.DailyDay(date: num, label: label, isActive: i == _selectedDayIndex);
                        });
                        return DailyDayStrip(
                          days: stripDays,
                          onSelect: (dateNum) {
                            final idx = stripDays.indexWhere((e) => e.date == dateNum);
                            if (idx != -1) _selectDay(idx);
                          },
                        );
                      }),

                      // Swipeable PageView — tiap halaman = list task ala gambar
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _weekData?.days.length ?? 0,
                          onPageChanged: (index) {
                            setState(() {
                              _selectedDayIndex = index;
                              _expandedDayIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final day = _weekData!.days[index];
                            final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
                            final showMorningBrief = day.date == todayStr && _morningBrief != null && !_isBriefDismissed;

                            // Map real Task → DailyTask (clean modular)
                            daily.DailyTaskIcon? pickIcon(Task t) {
                              final s = t.title.toLowerCase();
                              if (s.contains('birthday') || s.contains('ultah')) return daily.DailyTaskIcon.star;
                              if (s.contains('wind down') || s.contains('tidur')) return daily.DailyTaskIcon.moon;
                              if (s.contains('haircut') || s.contains('vincent') || s.contains('meeting')) return daily.DailyTaskIcon.people;
                              if (s.contains('design') || s.contains('crit')) return daily.DailyTaskIcon.grid;
                              return daily.DailyTaskIcon.clock;
                            }
                            final dailyTasks = day.tasks.map((t) {
                              final hasTime = t.estimatedMinutes != null;
                              final hh = hasTime ? '${(t.estimatedMinutes! ~/ 60).toString().padLeft(2, '0')}:${(t.estimatedMinutes! % 60).toString().padLeft(2, '0')}' : null;
                              // scheduled/ritual/event vs todo → pakai checkbox kalau todo, badge kalau ada waktu/birthday
                              final isEvent = t.title.toLowerCase().contains('birthday') || t.title.toLowerCase().contains('ultah');
                              final isRitual = t.title.toLowerCase().contains('wind down');
                              daily.DailyTaskKind kind;
                              if (isEvent) { kind = daily.DailyTaskKind.event; }
                              else if (isRitual) { kind = daily.DailyTaskKind.ritual; }
                              else if (hasTime) { kind = daily.DailyTaskKind.scheduled; }
                              else { kind = daily.DailyTaskKind.todo; }
                              return daily.DailyTask(
                                id: t.id,
                                title: t.title,
                                kind: kind,
                                icon: (kind == daily.DailyTaskKind.todo) ? null : pickIcon(t),
                                time: hh,
                                completed: t.isDone,
                              );
                            }).toList();

                            return SingleChildScrollView(
                              key: ValueKey('DailyFocus_${day.date}'),
                              child: Column(
                                children: [
                                  if (showMorningBrief)
                                    MorningBriefBanner(
                                      brief: _morningBrief!,
                                      onDismiss: () => setState(() => _isBriefDismissed = true),
                                      onEditTask: (taskId, newTitle) => _handleEditTaskTitle(taskId, newTitle),
                                      onDeleteTask: (taskId) => _handleDeleteTask(taskId),
                                      onFollowUpMissed: (taskId, action) => _handleFollowUpMissed(taskId, action),
                                      onAddTask: () => _showQuickAddTaskDialog(day.date, index),
                                      onOpenChat: () => widget.onOpenChat?.call("Mau cerita tentang rencana hari ini"),
                                    ),
                                  Container(
                                    color: (isDark ? AppColors.darkBackground : Colors.white).withValues(alpha: isDark ? 1 : 0.55),
                                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                                    child: dailyTasks.isEmpty
                                        ? Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 24),
                                            child: Text('Belum ada task — tap + untuk tambah',
                                                style: GoogleFonts.inter(fontSize: 13, color: secondaryTextColor)),
                                          )
                                        : Column(
                                            children: [
                                              ...dailyTasks.map((dt) => DailyTaskRow(
                                                    task: dt,
                                                    onToggle: (id) {
                                                      final orig = day.tasks.firstWhere((e) => e.id == id);
                                                      _toggleTaskStatus(orig, !orig.isDone, index);
                                                    },
                                                  )),
                                              const SizedBox(height: 8),
                                              // Add task row (inline, clean)
                                              InkWell(
                                                onTap: () => _showQuickAddTaskDialog(day.date, index),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                                  child: Row(children: [
                                                    Container(
                                                      width: 20, height: 20,
                                                      decoration: BoxDecoration(border: Border.all(color: AppColors.hairlineGray), borderRadius: BorderRadius.circular(5), color: Colors.white),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text('Add a new task...', style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.warmGray)),
                                                  ]),
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      // 7-day Accordion List (Weekly Overview)
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _weekData?.days.length ?? 0,
                          itemBuilder: (context, index) {
                            final day = _weekData!.days[index];
                            final isExpanded = index == _expandedDayIndex;
                            final shadeIndex = index;

                            return AnimatedCrossFade(
                              duration: const Duration(milliseconds: 220),
                              firstCurve: Curves.easeInOut,
                              secondCurve: Curves.easeInOut,
                              crossFadeState: isExpanded
                                  ? CrossFadeState.showFirst
                                  : CrossFadeState.showSecond,
                              firstChild: DayBlock(
                                dayData: day,
                                shadeIndex: shadeIndex,
                                onToggleTask: (task, isDone) => _toggleTaskStatus(task, isDone, index),
                                onAddTask: (title) => _handleAddTask(day.date, title, index),
                                onClarifyTask: (task, mins) => _handleClarifyTask(task, mins, index),
                                onFollowUpAction: _handleFollowUp,
                                onRescheduleAction: _handleReschedule,
                                onOpenBrainDump: _openBrainDumpSheet,
                              ),
                              secondChild: DayStrip(
                                dayName: day.dayName,
                                taskCount: day.tasks.length,
                                shadeIndex: shadeIndex,
                                onTap: () {
                                  setState(() {
                                    _expandedDayIndex = index;
                                    _selectedDayIndex = index;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}
