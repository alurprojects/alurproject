import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alur/models/task.dart';
import 'package:alur/screens/main_screen.dart';
import 'package:alur/screens/chat_room/chat_room_screen.dart';
import 'package:alur/screens/calendar/calendar_screen.dart';
import 'package:alur/screens/profile/profile_screen.dart';
import 'package:alur/screens/weekly_view/weekly_screen.dart';
import 'package:alur/services/api_service.dart';

class MockApiService extends ApiService {
  @override
  Future<WeekData> fetchWeekTasks({String? weekDate}) async {
    return WeekData(
      weekStart: '2026-09-14',
      weekEnd: '2026-09-20',
      days: [
        DayData(
          date: '2026-09-18',
          dayName: 'Friday',
          isToday: true,
          tasks: [],
        ),
      ],
    );
  }

  @override
  Future<List<Insight>> fetchInsights() async {
    return [];
  }
}

void main() {
  group('MainScreen 4-Tab Navigation Tests', () {
    testWidgets('renders all 4 tabs in BottomNavigationBar and defaults to To-do', (tester) async {
      final mockApi = MockApiService();

      await tester.pumpWidget(
        MaterialApp(
          home: MainScreen(
            apiService: mockApi,
            onToggleTheme: () {},
            isDarkMode: false,
          ),
        ),
      );

      // Verify all 4 tabs exist in BottomNavigationBar
      expect(find.text('To-do'), findsOneWidget);
      expect(find.text('Chat Room'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify IndexedStack exists
      final indexedStackFinder = find.byType(IndexedStack);
      expect(indexedStackFinder, findsOneWidget);
      final indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      expect(indexedStack.index, 0);

      // Verify initial tab widget is WeeklyScreen
      expect(find.byType(WeeklyScreen), findsOneWidget);
    });

    testWidgets('switches to Chat Room tab when tapped', (tester) async {
      final mockApi = MockApiService();

      await tester.pumpWidget(
        MaterialApp(
          home: MainScreen(
            apiService: mockApi,
            onToggleTheme: () {},
            isDarkMode: false,
          ),
        ),
      );

      // Tap Chat Room
      await tester.tap(find.text('Chat Room'));
      await tester.pump();

      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 1);
      expect(find.byType(ChatRoomScreen), findsOneWidget);
      expect(find.text('CHAT ROOM'), findsOneWidget);
    });

    testWidgets('switches to Calendar tab when tapped', (tester) async {
      final mockApi = MockApiService();

      await tester.pumpWidget(
        MaterialApp(
          home: MainScreen(
            apiService: mockApi,
            onToggleTheme: () {},
            isDarkMode: false,
          ),
        ),
      );

      // Tap Calendar
      await tester.tap(find.text('Calendar'));
      await tester.pump();

      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 2);
      expect(find.byType(CalendarScreen), findsOneWidget);
      expect(find.text('CALENDAR'), findsOneWidget);
    });

    testWidgets('switches to Profile tab and shows settings', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockApi = MockApiService();

      await tester.pumpWidget(
        MaterialApp(
          home: MainScreen(
            apiService: mockApi,
            onToggleTheme: () {},
            isDarkMode: false,
          ),
        ),
      );

      // Tap Profile
      await tester.tap(find.text('Profile'));
      await tester.pump();

      final indexedStack = tester.widget<IndexedStack>(find.byType(IndexedStack));
      expect(indexedStack.index, 3);
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('PROFILE'), findsOneWidget);
      expect(find.text('PENGATURAN'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
    });
  });
}
