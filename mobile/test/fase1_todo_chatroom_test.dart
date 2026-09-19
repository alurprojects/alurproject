import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alur/models/task.dart';
import 'package:alur/screens/weekly_view/weekly_screen.dart';
import 'package:alur/screens/chat_room/chat_room_screen.dart';
import 'package:alur/services/api_service.dart';

class MockTodoApiService extends ApiService {
  @override
  Future<WeekData> fetchWeekTasks({String? weekDate}) async {
    return WeekData(
      weekStart: '2026-09-14',
      weekEnd: '2026-09-20',
      days: [
        DayData(
          date: '2026-09-14',
          dayName: 'Monday',
          isToday: false,
          tasks: [
            const Task(
              id: 'task-mon-1',
              userId: 'user-1',
              title: 'Review Project Specs',
              assignedDate: '2026-09-14',
              status: 'PENDING',
              source: 'MANUAL',
              isAmbiguous: false,
              aiGenerated: false,
              missedFollowUp: 'NONE',
            ),
          ],
        ),
        DayData(
          date: '2026-09-15',
          dayName: 'Tuesday',
          isToday: true,
          tasks: [
            const Task(
              id: 'task-tue-1',
              userId: 'user-1',
              title: 'Client Demo Sync',
              assignedDate: '2026-09-15',
              status: 'PENDING',
              source: 'MANUAL',
              isAmbiguous: false,
              aiGenerated: false,
              missedFollowUp: 'NONE',
            ),
          ],
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
  group('Fase 1.3 To-do Hybrid View Tests', () {
    testWidgets('defaults to Daily Focus with PageView and toggles to Weekly Overview',
        (WidgetTester tester) async {
      final mockApi = MockTodoApiService();

      await tester.pumpWidget(
        MaterialApp(
          home: WeeklyScreen(
            apiService: mockApi,
            onToggleTheme: () {},
            isDarkMode: false,
          ),
        ),
      );

      // Wait for data load
      await tester.pumpAndSettle();

      // Verify Daily Focus View renders PageView
      expect(find.byType(PageView), findsOneWidget);

      // Verify toggle button exists and tap it to switch to Weekly Overview
      final toggleFinder = find.byTooltip('Beralih ke Weekly Overview');
      expect(toggleFinder, findsOneWidget);
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      // Verify PageView is replaced by Accordion ListView
      expect(find.byType(PageView), findsNothing);
      expect(find.byTooltip('Beralih ke Daily Focus'), findsOneWidget);

      // Tap toggle again to return to Daily Focus
      await tester.tap(find.byTooltip('Beralih ke Daily Focus'));
      await tester.pumpAndSettle();

      // Verify PageView is back
      expect(find.byType(PageView), findsOneWidget);
    });
  });

  group('Fase 1.4 Chat Room UI Shell Tests', () {
    testWidgets('renders message list, sends user message, and receives mock AI response',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChatRoomScreen(
            isDarkMode: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial welcoming AI message
      expect(find.text('CHAT ROOM'), findsOneWidget);
      expect(find.textContaining('ruang refleksi dan brain-dump'), findsOneWidget);

      // Verify quick prompt chips exist
      expect(find.text('🧠 Brain-dump tugas baru'), findsOneWidget);

      // Type a message in text field
      await tester.enterText(find.byType(TextField), 'Besok meeting jam 10 pagi');
      await tester.pump();

      // Tap send button
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();

      // Verify user message appears
      expect(find.text('Besok meeting jam 10 pagi'), findsOneWidget);

      // Verify typing indicator appears
      expect(find.text('Companion sedang memikirkan respons...'), findsOneWidget);

      // Advance timer for mock AI response (700ms)
      await tester.pump(const Duration(milliseconds: 750));

      // Verify mock AI response appears
      expect(find.textContaining('Saya menangkap tugas dari brain-dump kamu'), findsOneWidget);
    });

    testWidgets('tapping quick prompt chip immediately sends it',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChatRoomScreen(
            isDarkMode: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll into view and tap quick prompt chip
      final chipFinder = find.text('💭 Aku merasa overwhelmed');
      await tester.ensureVisible(chipFinder);
      await tester.pumpAndSettle();
      await tester.tap(chipFinder);
      await tester.pump();

      // Verify message appears in chat history while chip remains
      expect(chipFinder, findsNWidgets(2));

      // Advance timer for AI response
      await tester.pump(const Duration(milliseconds: 750));

      // Verify empathetic gentle tone response
      expect(find.textContaining('Wajar jika merasa overload'), findsOneWidget);
    });
  });
}
