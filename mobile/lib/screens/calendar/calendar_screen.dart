import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';

class ScheduledEvent {
  final String title;
  final int startHour;
  final int durationMinutes;
  final String category;

  const ScheduledEvent({
    required this.title,
    required this.startHour,
    required this.durationMinutes,
    required this.category,
  });
}

class CalendarScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onNavigateToTodo;

  const CalendarScreen({
    super.key,
    required this.isDarkMode,
    this.onNavigateToTodo,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDate;
  bool _showUnscheduledDetails = false;

  final List<String> _unscheduledTasks = [
    'Riset referensi tipografi Inter',
    'Review token warna monokromatik',
    'Tulis draf refleksi mingguan',
  ];

  final Map<int, List<ScheduledEvent>> _mockSchedule = {
    9: [
      const ScheduledEvent(
        title: 'Deep Work: Rebuild UI ALUR',
        startHour: 9,
        durationMinutes: 90,
        category: 'Development',
      ),
    ],
    11: [
      const ScheduledEvent(
        title: 'Standup & Review Kapasitas',
        startHour: 11,
        durationMinutes: 45,
        category: 'Meeting',
      ),
    ],
    14: [
      const ScheduledEvent(
        title: 'Database Schema & Supabase RLS',
        startHour: 14,
        durationMinutes: 60,
        category: 'Backend',
      ),
    ],
    16: [
      const ScheduledEvent(
        title: 'Evaluasi DCDC & Brain-dump Catchup',
        startHour: 16,
        durationMinutes: 30,
        category: 'Reflection',
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.charcoal;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.warmGray;
    final backgroundColor = isDark ? AppColors.darkBackground : AppColors.warmOffWhite;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.paperGray;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.hairlineGray;

    final formattedDayName = DateFormat('EEEE').format(_selectedDate).toUpperCase();
    final formattedDate = DateFormat('d MMM yyyy').format(_selectedDate);

    // Time blocks 06:00 to 22:00 (17 hours)
    final hours = List.generate(17, (index) => 6 + index);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CALENDAR',
              style: GoogleFonts.inter(
                letterSpacing: 2.0,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Time-block View (06:00 - 22:00) • Read-Only',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _goToToday,
            child: Text(
              'Today',
              style: GoogleFonts.inter(
                color: primaryTextColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Date navigation bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left_rounded, color: primaryTextColor),
                    onPressed: _previousDay,
                  ),
                  Column(
                    children: [
                      Text(
                        formattedDayName,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: primaryTextColor,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right_rounded, color: primaryTextColor),
                    onPressed: _nextDay,
                  ),
                ],
              ),
            ),

            // Unscheduled Section Banner (Expandable)
            Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border(bottom: BorderSide(color: borderColor, width: 1)),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showUnscheduledDetails = !_showUnscheduledDetails;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.schedule_outlined, size: 16, color: secondaryTextColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Unscheduled Tasks (${_unscheduledTasks.length})',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: primaryTextColor,
                              ),
                            ),
                          ),
                          Text(
                            _showUnscheduledDetails ? 'Tutup' : 'Lihat',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: secondaryTextColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _showUnscheduledDetails
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: secondaryTextColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showUnscheduledDetails)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _unscheduledTasks.map((t) {
                          return InkWell(
                            onTap: widget.onNavigateToTodo,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: borderColor, width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    t,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: secondaryTextColor),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),

            // Time block vertical grid (06:00 - 22:00)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: hours.length,
                itemBuilder: (context, index) {
                  final hour = hours[index];
                  final timeLabel = '${hour.toString().padLeft(2, '0')}:00';
                  final events = _mockSchedule[hour] ?? [];

                  return Container(
                    constraints: const BoxConstraints(minHeight: 60),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: borderColor.withAlpha(120),
                          width: 0.8,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left time label
                        SizedBox(
                          width: 64,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8, right: 12),
                            child: Text(
                              timeLabel,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: secondaryTextColor,
                              ),
                            ),
                          ),
                        ),
                        // Divider column
                        Container(
                          width: 1,
                          color: borderColor,
                        ),
                        // Events area in this hour slot
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: events.isEmpty
                                ? const SizedBox(height: 52)
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: events.map((ev) {
                                      return InkWell(
                                        onTap: widget.onNavigateToTodo,
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(bottom: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: surfaceColor,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: borderColor,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      ev.title,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                        color: primaryTextColor,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${ev.category} • ${ev.durationMinutes}m',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        color: secondaryTextColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons.open_in_new_rounded,
                                                size: 14,
                                                color: secondaryTextColor,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
