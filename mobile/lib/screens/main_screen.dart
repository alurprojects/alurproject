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

    // Native Mobile 4-Tab Navigation
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0: To-do (Weekly/Daily Hybrid View)
          WeeklyScreen(
            apiService: widget.apiService,
            onToggleTheme: widget.onToggleTheme,
            isDarkMode: widget.isDarkMode,
            onOpenChat: _openChatWithPrompt,
          ),
          // Tab 1: Chat Room (AI Companion & Brain-dump)
          ChatRoomScreen(
            isDarkMode: widget.isDarkMode,
            initialPrompt: _initialChatPrompt,
            apiService: widget.apiService,
            onTasksCreated: () {
              setState(() {});
            },
          ),
          // Tab 2: Calendar (Time-block View)
          CalendarScreen(
            isDarkMode: widget.isDarkMode,
            onNavigateToTodo: () => _onTabTapped(0),
          ),
          // Tab 3: Profile (Account Settings & Retention)
          ProfileScreen(
            onToggleTheme: widget.onToggleTheme,
            isDarkMode: widget.isDarkMode,
            authService: widget.authService,
            apiService: widget.apiService,
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
          currentIndex: _currentIndex,
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
              icon: Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Chat Room',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today_rounded),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
