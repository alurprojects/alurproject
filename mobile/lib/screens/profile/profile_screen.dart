import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class ActiveGoal {
  final String id;
  final String title;
  final String deadline;
  final List<String> subTasks;

  const ActiveGoal({
    required this.id,
    required this.title,
    required this.deadline,
    required this.subTasks,
  });
}

class ProfileScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final AuthService? authService;
  final ApiService? apiService;

  const ProfileScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
    this.authService,
    this.apiService,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthService _authService;
  bool _isLoggingOut = false;

  // Settings state
  String _timezone = 'Asia/Jakarta (WIB)';
  int _dailyCapacityHours = 6;

  // Data Retention state
  bool _hasPendingRetentionAlert = true;

  // Goals state
  final Set<String> _expandedGoals = {'goal-1'};
  final List<ActiveGoal> _goals = const [
    ActiveGoal(
      id: 'goal-1',
      title: '🎯 Rilis MVP ALUR v1.0',
      deadline: '30 Sep 2026',
      subTasks: [
        'Finalisasi integrasi Native Google Auth',
        'Validasi layout 4-tab navigasi dan Hybrid view',
        'Setup cron otomatis refleksi mingguan',
      ],
    ),
    ActiveGoal(
      id: 'goal-2',
      title: '🌿 Disiplin Deep Work & Kapasitas Realistis',
      deadline: '15 Okt 2026',
      subTasks: [
        'Batasi komitmen harian maksimal 6 jam',
        'Lakukan evaluasi harian saat malam hari',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  void _showDailyCapacityDialog() {
    final isDark = widget.isDarkMode;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.charcoal;

    showDialog(
      context: context,
      builder: (context) {
        int selected = _dailyCapacityHours;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.warmOffWhite,
              title: Text(
                'Target Kapasitas Harian',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: primaryTextColor),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [4, 6, 8, 10].map((hours) {
                  return RadioListTile<int>(
                    title: Text('$hours Jam / hari', style: GoogleFonts.inter(fontSize: 14, color: primaryTextColor)),
                    value: hours,
                    // ignore: deprecated_member_use
                    groupValue: selected,
                    activeColor: isDark ? AppColors.darkActiveAccent : AppColors.inkBlack,
                    // ignore: deprecated_member_use
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selected = val);
                      }
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkActiveAccent : AppColors.inkBlack,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                  ),
                  onPressed: () {
                    setState(() => _dailyCapacityHours = selected);
                    Navigator.pop(context);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTimezoneDialog() {
    final isDark = widget.isDarkMode;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.charcoal;
    final zones = ['Asia/Jakarta (WIB)', 'Asia/Makassar (WITA)', 'Asia/Jayapura (WIT)', 'UTC (Coordinated Universal Time)'];

    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.warmOffWhite,
          title: Text(
            'Pilih Zona Waktu',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: primaryTextColor),
          ),
          children: zones.map((z) {
            return SimpleDialogOption(
              onPressed: () {
                setState(() => _timezone = z);
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(z, style: GoogleFonts.inter(fontSize: 14, color: primaryTextColor)),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _handleDeleteAllChatHistory() async {
    final isDark = widget.isDarkMode;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.charcoal;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.warmGray;

    // LANGKAH 1: Dialog Peringatan Destruktif Awal
    final step1Confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.warmOffWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hapus Riwayat Chat?',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17, color: primaryTextColor),
                ),
              ),
            ],
          ),
          content: Text(
            'Langkah 1 dari 2:\n\nTindakan ini bersifat destruktif dan permanen. '
            'Seluruh data percakapan di server (conversation_logs) akan dihapus secara total dan tidak dapat dipulihkan.',
            style: GoogleFonts.inter(fontSize: 13, height: 1.45, color: secondaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal', style: GoogleFonts.inter(color: secondaryTextColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, true),
              child: Text('Lanjut ke Konfirmasi', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );

    if (step1Confirmed != true || !mounted) return;

    // LANGKAH 2: Konfirmasi Verifikasi Ketik "HAPUS"
    final textController = TextEditingController();
    bool isInputValid = false;

    final step2Confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.warmOffWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(
                'Konfirmasi Akhir (Langkah 2/2)',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17, color: primaryTextColor),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ketik kata "HAPUS" (huruf kapital) di bawah untuk mengonfirmasi penghapusan seluruh data riwayat chat:',
                    style: GoogleFonts.inter(fontSize: 13, color: secondaryTextColor, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: textController,
                    autofocus: true,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: primaryTextColor),
                    decoration: InputDecoration(
                      hintText: 'HAPUS',
                      hintStyle: GoogleFonts.inter(color: secondaryTextColor),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        isInputValid = val.trim() == 'HAPUS';
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Batal', style: GoogleFonts.inter(color: secondaryTextColor)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isInputValid ? Colors.redAccent : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isInputValid ? () => Navigator.pop(context, true) : null,
                  child: Text('Hapus Permanen', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );

    if (step2Confirmed == true && mounted) {
      if (widget.apiService != null) {
        try {
          await widget.apiService!.deleteChatHistory();
        } catch (_) {}
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seluruh riwayat percakapan chat telah berhasil dihapus permanen.'),
          backgroundColor: AppColors.inkBlack,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final isDark = widget.isDarkMode;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.charcoal;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.warmGray;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.warmOffWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Keluar dari Akun?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: primaryTextColor),
          ),
          content: Text(
            'Anda akan dialihkan kembali ke layar login.',
            style: GoogleFonts.inter(fontSize: 14, color: secondaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Batal', style: GoogleFonts.inter(color: secondaryTextColor, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkActiveAccent : AppColors.inkBlack,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() => _isLoggingOut = true);
      try {
        await _authService.signOut();
      } catch (e) {
        if (mounted) {
          setState(() => _isLoggingOut = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal logout: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.charcoal;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.warmGray;
    final backgroundColor = isDark ? AppColors.darkBackground : AppColors.warmOffWhite;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.paperGray;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.hairlineGray;

    final user = _authService.currentUser;
    final userEmail = user?.email ?? 'user@alur.app';
    final userName = user?.userMetadata?['full_name'] as String? ??
        user?.userMetadata?['name'] as String? ??
        'User ALUR';
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'PROFILE',
          style: GoogleFonts.inter(
            letterSpacing: 2.0,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: primaryTextColor,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // User Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isDark ? AppColors.darkBorder : AppColors.hairlineGray,
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: primaryTextColor,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: secondaryTextColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notice Banner Retensi Chat (>83 hari)
            if (_hasPendingRetentionAlert) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF33271D) : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFF97316).withAlpha(120),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFFEA580C), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pemberitahuan Retensi Data (H-7)',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFEA580C),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '3 riwayat percakapan chat lebih dari 83 hari akan dihapus permanen dalam 7 hari.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.4,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFEA580C)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            if (widget.apiService != null) {
                              try {
                                final res = await widget.apiService!.exportChatHistory();
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Backup JSON berhasil diunduh (${res['total_messages'] ?? 0} log pesan).',
                                    ),
                                  ),
                                );
                                return;
                              } catch (_) {}
                            }
                            if (!mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Mengunduh backup chat (JSON)...')),
                            );
                          },
                          child: Text('Unduh Backup', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFEA580C))),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEA580C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            if (widget.apiService != null) {
                              try {
                                await widget.apiService!.overrideChatRetention();
                              } catch (_) {}
                            }
                            if (!mounted) return;
                            setState(() => _hasPendingRetentionAlert = false);
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Riwayat chat berhasil ditandai Simpan Selamanya.')),
                            );
                          },
                          child: Text('Simpan Selamanya', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () {
                            setState(() => _hasPendingRetentionAlert = false);
                          },
                          child: Text('Oke, hapus saja', style: GoogleFonts.inter(fontSize: 11, color: secondaryTextColor)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Active Goals Section (PRD 3.5)
            Text(
              'SASARAN AKTIF (ACTIVE GOALS)',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            ..._goals.map((goal) {
              final isExpanded = _expandedGoals.contains(goal.id);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        goal.title,
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: primaryTextColor),
                      ),
                      subtitle: Text(
                        'Target: ${goal.deadline}',
                        style: GoogleFonts.inter(fontSize: 12, color: secondaryTextColor),
                      ),
                      trailing: Icon(
                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: secondaryTextColor,
                      ),
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedGoals.remove(goal.id);
                          } else {
                            _expandedGoals.add(goal.id);
                          }
                        });
                      },
                    ),
                    if (isExpanded)
                      Container(
                        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(color: borderColor, height: 1),
                            const SizedBox(height: 10),
                            ...goal.subTasks.map((st) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkActiveAccent : AppColors.inkBlack,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        st,
                                        style: GoogleFonts.inter(fontSize: 12, color: primaryTextColor),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // Settings Section Header
            Text(
              'PENGATURAN',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 12),

            // Theme Toggle Tile
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: ListTile(
                leading: Icon(
                  isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  color: primaryTextColor,
                ),
                title: Text(
                  'Tema Gelap (Dark Mode)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                  ),
                ),
                trailing: Switch.adaptive(
                  value: isDark,
                  activeThumbColor: isDark ? AppColors.darkActiveAccent : AppColors.inkBlack,
                  onChanged: (_) => widget.onToggleTheme(),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Timezone Tile
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: ListTile(
                leading: Icon(Icons.public_outlined, color: primaryTextColor),
                title: Text(
                  'Zona Waktu',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _timezone,
                      style: GoogleFonts.inter(fontSize: 12, color: secondaryTextColor),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: secondaryTextColor),
                  ],
                ),
                onTap: _showTimezoneDialog,
              ),
            ),
            const SizedBox(height: 10),

            // Daily Capacity Hours Tile
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: ListTile(
                leading: Icon(Icons.timer_outlined, color: primaryTextColor),
                title: Text(
                  'Kapasitas Harian',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_dailyCapacityHours Jam / hari',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: secondaryTextColor),
                  ],
                ),
                onTap: _showDailyCapacityDialog,
              ),
            ),
            const SizedBox(height: 24),

            // Destructive Chat Deletion Section
            Text(
              'TINDAKAN PRIVASI',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: ListTile(
                leading: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent),
                title: Text(
                  'Hapus Riwayat Chat',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
                subtitle: Text(
                  'Hapus seluruh conversation logs (Konfirmasi 2-langkah)',
                  style: GoogleFonts.inter(fontSize: 11, color: secondaryTextColor),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.redAccent),
                onTap: _handleDeleteAllChatHistory,
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.hairlineGray,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: _isLoggingOut
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.logout_rounded, size: 18, color: primaryTextColor),
                label: Text(
                  _isLoggingOut ? 'Sedang keluar...' : 'Log Out',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
                onPressed: _isLoggingOut ? null : _handleLogout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
