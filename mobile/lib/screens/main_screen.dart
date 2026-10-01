import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'calendar/calendar_screen.dart';
import 'chat_room/chat_room_screen.dart';
import 'profile/profile_screen.dart';
import 'weekly_view/weekly_screen.dart';

class MainScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final int initialTabIndex;
  final AuthService? authService;

  const MainScreen({
    super.key,
    required this.apiService,
    required this.onToggleTheme,
    required this.isDarkMode,
    this.initialTabIndex = 0,
    this.authService,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  String? _initialChatPrompt;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _openChatWithPrompt(String? prompt) {
    setState(() {
      _currentIndex = 1;
      _initialChatPrompt = prompt;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final navBackgroundColor = isDark ? AppColors.darkSurface : AppColors.warmOffWhite;
    final navBorderColor = isDark ? AppColors.darkBorder : AppColors.hairlineGray;
    final activeColor = isDark ? AppColors.darkActiveAccent : AppColors.inkBlack;
    final inactiveColor = isDark ? AppColors.darkTextSecondary : AppColors.warmGray;

    // Per PRD Section 3.6: Web app v1 HANYA berisi To-do dan Calendar
    if (kIsWeb) {
      final safeIndex = _currentIndex.clamp(0, 1);

      return Scaffold(
        body: IndexedStack(
          index: safeIndex,
          children: [
            // Tab 0: To-do
            WeeklyScreen(
              apiService: widget.apiService,
              onToggleTheme: widget.onToggleTheme,
              isDarkMode: widget.isDarkMode,
            ),
            // Tab 1: Calendar
            CalendarScreen(
              isDarkMode: widget.isDarkMode,
              onNavigateToTodo: () => _onTabTapped(0),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: navBackgroundColor,
            border: Border(
              top: BorderSide(
                color: navBorderColor,
                width: 1.0,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: safeIndex,
            onTap: _onTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: navBackgroundColor,
            elevation: 0,
            selectedItemColor: activeColor,
            unselectedItemColor: inactiveColor,
            selectedLabelStyle: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.check_circle_outline_rounded),
                activeIcon: Icon(Icons.check_circle_rounded),
                label: 'To-do',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today_rounded),
                label: 'Calendar',
              ),
            ],
          ),
        ),
      );
    }

    // Native Mobile 5-slot pill — Home bulat hitam di tengah (sesuai gambar)
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          WeeklyScreen(
            apiService: widget.apiService,
            onToggleTheme: widget.onToggleTheme,
            isDarkMode: widget.isDarkMode,
            onOpenChat: _openChatWithPrompt,
          ),
          ChatRoomScreen(
            isDarkMode: widget.isDarkMode,
            initialPrompt: _initialChatPrompt,
            apiService: widget.apiService,
            onTasksCreated: () => setState(() {}),
          ),
          CalendarScreen(
            isDarkMode: widget.isDarkMode,
            onNavigateToTodo: () => _onTabTapped(0),
          ),
          ProfileScreen(
            onToggleTheme: widget.onToggleTheme,
            isDarkMode: widget.isDarkMode,
            authService: widget.authService,
            apiService: widget.apiService,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2B29) : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE8E6E1),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 6)),
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 2, offset: const Offset(0, 1)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _NavSideItem(
                  icon: Icons.check_circle_outline_rounded,
                  activeIcon: Icons.check_circle_rounded,
                  label: 'To-do',
                  active: _currentIndex == 0,
                  isDark: isDark,
                  onTap: () => _onTabTapped(0),
                ),
                _NavSideItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: 'Chat Room',
                  active: _currentIndex == 1,
                  isDark: isDark,
                  onTap: () => _onTabTapped(1),
                ),
                // HOME — center big black circle (the hero, per gambar)
                _NavCenterHome(
                  active: _currentIndex == 0, // highlight when on To-do
                  isDark: isDark,
                  onTap: () => _onTabTapped(0),
                ),
                _NavSideItem(
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today_rounded,
                  label: 'Calendar',
                  active: _currentIndex == 2,
                  isDark: isDark,
                  onTap: () => _onTabTapped(2),
                ),
                _NavSideItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  active: _currentIndex == 3,
                  isDark: isDark,
                  onTap: () => _onTabTapped(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavSideItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;
  const _NavSideItem({required this.icon, required this.activeIcon, required this.label, required this.active, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active
        ? (isDark ? Colors.white : AppColors.inkBlack)
        : (isDark ? AppColors.darkTextSecondary : const Color(0xFF9A9590));
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? activeIcon : icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.1,
                  color: color,
                  height: 1,
                )),
          ],
        ),
      ),
    );
  }
}

class _NavCenterHome extends StatelessWidget {
  final bool active;
  final bool isDark;
  final VoidCallback onTap;
  const _NavCenterHome({required this.active, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isDark ? Colors.white : Colors.black,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(
              active ? Icons.home_rounded : Icons.home_outlined,
              size: 24,
              color: isDark ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text('Home',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
                color: active
                    ? (isDark ? Colors.white : AppColors.inkBlack)
                    : (isDark ? AppColors.darkTextSecondary : const Color(0xFF9A9590)),
                height: 1,
              )),
        ],
      ),
    );
  }
}
