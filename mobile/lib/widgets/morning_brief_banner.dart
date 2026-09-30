import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../models/morning_brief.dart';

class MorningBriefBanner extends StatefulWidget {
  final MorningBriefData brief;
  final VoidCallback onDismiss;
  final Function(String taskId, String newTitle) onEditTask;
  final Function(String taskId) onDeleteTask;
  final Function(String taskId, String action) onFollowUpMissed;
  final VoidCallback onAddTask;
  final VoidCallback onOpenChat;

  const MorningBriefBanner({
    super.key,
    required this.brief,
    required this.onDismiss,
    required this.onEditTask,
    required this.onDeleteTask,
    required this.onFollowUpMissed,
    required this.onAddTask,
    required this.onOpenChat,
  });

  @override
  State<MorningBriefBanner> createState() => _MorningBriefBannerState();
}

class _MorningBriefBannerState extends State<MorningBriefBanner> {
  void _showEditTaskDialog(String taskId, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.charcoal;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.warmGray;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.warmOffWhite,
        title: Text(
          'Edit Task',
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
            hintText: 'Nama task...',
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
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != currentTitle) {
                widget.onEditTask(taskId, newTitle);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTask(String taskId, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.charcoal;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.warmGray;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.warmOffWhite,
        title: Text(
          'Hapus Task',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: primaryTextColor,
          ),
        ),
        content: Text(
          'Hapus "$title" dari daftar hari ini?',
          style: TextStyle(color: primaryTextColor, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Batal', style: TextStyle(color: secondaryTextColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orangeAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              widget.onDeleteTask(taskId);
              Navigator.of(ctx).pop();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bannerBg = isDark ? AppColors.darkSurface : AppColors.paperGray;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.charcoal;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.warmGray;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.hairlineGray;

    final brief = widget.brief;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Greeting & Close button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🌅 ', style: TextStyle(fontSize: 18)),
              Expanded(
                child: Text(
                  brief.greeting,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                    height: 1.3,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: secondaryTextColor),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.onDismiss,
                tooltip: 'Tutup brief',
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. Tasks list
          if (brief.tasks.isNotEmpty) ...[
            Text(
              '${brief.tasks.length} task direncanakan hari ini:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: secondaryTextColor,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            ...brief.tasks.map((task) {
              final durationText = task.estimatedMinutes != null
                  ? (task.estimatedMinutes! >= 60
                      ? ' (${task.estimatedMinutes! ~/ 60} jam${task.estimatedMinutes! % 60 > 0 ? " ${task.estimatedMinutes! % 60}m" : ""})'
                      : ' (${task.estimatedMinutes}m)')
                  : '';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_box_outline_blank_rounded,
                      size: 16,
                      color: isDark ? AppColors.darkCheckboxBorder : AppColors.lightCheckboxBorder,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${task.title}$durationText',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: primaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Quick Action: Edit
                    InkWell(
                      onTap: () => _showEditTaskDialog(task.id, task.title),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Quick Action: Remove
                    InkWell(
                      onTap: () => _confirmDeleteTask(task.id, task.title),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          '❌',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            Text(
              'Hari ini belum ada tugas terjadwal.',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: secondaryTextColor,
              ),
            ),
          ],

          // 3. Missed tasks warning (if any)
          if (brief.missedTasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDark ? Colors.orange.shade900 : Colors.orange.shade50).withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (isDark ? Colors.orange.shade700 : Colors.orange.shade200).withValues(alpha: 0.5),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('⚠️ ', style: TextStyle(fontSize: 13)),
                      Text(
                        '${brief.missedTasks.length} task kemarin belum selesai:',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...brief.missedTasks.map((m) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '→ "${m.title}"',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: primaryTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Follow-up chip buttons
                          _buildQuickActionButton(
                            label: 'Udah',
                            onTap: () => widget.onFollowUpMissed(m.id, 'FORGOT'),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 4),
                          _buildQuickActionButton(
                            label: 'Skip',
                            onTap: () => widget.onFollowUpMissed(m.id, 'SKIPPED'),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 4),
                          _buildQuickActionButton(
                            label: '➡ Hari ini',
                            onTap: () => widget.onFollowUpMissed(m.id, 'RESCHEDULED'),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // 4. Capacity remaining
          Row(
            children: [
              const Text('⚡ ', style: TextStyle(fontSize: 13)),
              Text(
                'Kapasitas fokus tersisa: ~${brief.capacitySummary.remainingHours.toStringAsFixed(1)} jam',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryTextColor,
                ),
              ),
            ],
          ),

          // 5. AI Note (Grounded)
          if (brief.aiNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: (isDark ? Colors.black26 : Colors.white).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 0.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💬 ', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Text(
                      brief.aiNote,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                        color: primaryTextColor,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // 6. Action buttons: [+ Tambah task] & [💬 Cerita ke AI]
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Tambah task'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: primaryTextColor,
                    side: BorderSide(color: borderColor, width: 0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: widget.onAddTask,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                  label: const Text('Cerita ke AI'),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: isDark ? AppColors.darkActiveAccent : AppColors.inkBlack,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: widget.onOpenChat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.hairlineGray,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextPrimary : AppColors.charcoal,
          ),
        ),
      ),
    );
  }
}
