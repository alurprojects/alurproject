import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/daily_task.dart';
import 'daily_day_strip.dart';
import 'daily_task_row.dart';

/// Composite Daily To-do — replikasi gambar, clean minimalist.
/// Dipakai di WeeklyScreen (DailyFocus) atau sebagai screen standalone.

List<DailyDay> _defaultDays() => const [
      DailyDay(date: 5, label: 'MON'),
      DailyDay(date: 6, label: 'TUE'),
      DailyDay(date: 7, label: 'WED'),
      DailyDay(date: 8, label: 'THU'),
      DailyDay(date: 9, label: 'FRI', isActive: true),
      DailyDay(date: 10, label: 'SAT'),
      DailyDay(date: 11, label: 'SUN'),
    ];

List<DailyTask> _defaultTasks() => const [
      DailyTask(id: '1', title: "Daria's 20th Birthday", kind: DailyTaskKind.event, icon: DailyTaskIcon.star),
      DailyTask(id: '2', title: 'Wake up', kind: DailyTaskKind.scheduled, icon: DailyTaskIcon.clock, time: '09:00'),
      DailyTask(id: '3', title: 'Design Crit', kind: DailyTaskKind.scheduled, icon: DailyTaskIcon.grid, time: '10:00'),
      DailyTask(id: '4', title: 'Haircut with Vincent', kind: DailyTaskKind.scheduled, icon: DailyTaskIcon.people, time: '13:00'),
      DailyTask(id: '5', title: 'Make pasta', kind: DailyTaskKind.todo),
      DailyTask(id: '6', title: 'Pushups x100', kind: DailyTaskKind.subTodo),
      DailyTask(id: '7', title: 'Wind down', kind: DailyTaskKind.ritual, icon: DailyTaskIcon.moon, time: '21:00'),
    ];

class DailyTodoView extends StatefulWidget {
  final String dateLabel; // Dec 9
  final String year;
  final String dayName; // Fri
  final List<DailyDay>? days;
  final List<DailyTask>? tasks;
  final ValueChanged<String>? onToggleTask;

  const DailyTodoView({
    super.key,
    this.dateLabel = 'December 9',
    this.year = '2024',
    this.dayName = 'Fri',
    this.days,
    this.tasks,
    this.onToggleTask,
  });

  @override
  State<DailyTodoView> createState() => _DailyTodoViewState();
}

class _DailyTodoViewState extends State<DailyTodoView> {
  late List<DailyDay> _days;
  late List<DailyTask> _tasks;

  @override
  void initState() {
    super.initState();
    _days = widget.days ?? _defaultDays();
    _tasks = widget.tasks ?? _defaultTasks();
  }

  void _selectDay(int date) {
    setState(() => _days = _days.map((d) => d.copyWith(isActive: d.date == date)).toList());
  }

  void _toggle(String id) {
    if (widget.onToggleTask != null) {
      widget.onToggleTask!(id);
      return;
    }
    setState(() => _tasks = _tasks.map((t) => t.id == id ? t.copyWith(completed: !t.completed) : t).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header: Fri •  | Dec 9 / 2024
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.dayName,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: AppColors.charcoal,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: Color(0xFFFF6B6B), shape: BoxShape.circle),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(widget.dateLabel,
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.warmGray)),
                  Text(widget.year,
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.warmGray)),
                ],
              ),
            ],
          ),
        ),
        DailyDayStrip(days: _days, onSelect: _selectDay),
        // Task list
        Expanded(
          child: Container(
            color: Colors.white.withValues(alpha: 0.55),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              itemCount: _tasks.length,
              itemBuilder: (_, i) => DailyTaskRow(task: _tasks[i], onToggle: _toggle),
            ),
          ),
        ),
        // Bottom pill nav — minimalis
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.hairlineGray.withValues(alpha: 0.6)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(label: 'Activity', active: false),
                _NavItem(label: 'Nutrition', active: false),
                _NavItem(label: 'Home', active: true),
                _NavItem(label: 'Sleep', active: false),
                _NavItem(label: 'Calendar', active: false),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final bool active;
  const _NavItem({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.inkBlack : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: active ? Colors.white.withValues(alpha: 0.15) : AppColors.paperGray,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              label == 'Home' ? '⌂' : '○',
              style: TextStyle(fontSize: 11, color: active ? Colors.white : AppColors.warmGray),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: active ? Colors.white : AppColors.warmGray,
            ),
          ),
        ],
      ),
    );
  }
}
