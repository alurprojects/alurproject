import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alur/models/task.dart';
import 'package:alur/screens/chat_room/chat_room_screen.dart';
import 'package:alur/screens/profile/profile_screen.dart';
import 'package:alur/services/api_service.dart';

class MockChatApiService extends ApiService {
  bool sendCalled = false;
  bool exportCalled = false;
  bool overrideCalled = false;
  bool deleteCalled = false;

  @override
  Future<List<ChatHistoryEntry>> fetchChatHistory({String? date}) async {
    return [
      ChatHistoryEntry(
        id: 'hist-1',
        role: 'ai',
        content: 'Halo dari history backend!',
        messageType: 'CHAT',
        toneUsed: 'HONEST',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
    ];
  }

  @override
  Future<ChatApiResponse> sendChatMessage(String message) async {
    sendCalled = true;
    await Future.delayed(const Duration(milliseconds: 50));
    if (message.contains('error')) {
      throw Exception('Simulated Network Error');
    }
    return ChatApiResponse(
      reply: 'Saya telah mencatat tugas dari chat ini.',
      messageType: 'TASK_CAPTURE',
      toneUsed: 'HONEST',
      extractedTasks: [
        Task(
          id: 'task-chat-1',
          userId: '00000000-0000-0000-0000-000000000001',
          title: 'Review proposal',
          assignedDate: '2026-09-19',
          status: 'PENDING',
          source: 'CHAT_ROOM',
          isAmbiguous: false,
          aiGenerated: true,
          missedFollowUp: 'NONE',
        ),
      ],
    );
  }

  @override
  Future<Map<String, dynamic>> exportChatHistory() async {
    exportCalled = true;
    return {
      'exported_at': DateTime.now().toIsoformat(),
      'total_messages': 5,
      'logs': [],
    };
  }

  @override
  Future<bool> overrideChatRetention({List<String>? logIds}) async {
    overrideCalled = true;
    return true;
  }

  @override
  Future<bool> deleteChatHistory() async {
    deleteCalled = true;
    return true;
  }
}

extension on DateTime {
  String toIsoformat() => toIso8601String();
}

void main() {
  group('Fase 2 Chat Room Live Integration Tests', () {
    testWidgets('loads history on init and displays AI message', (tester) async {
      final mockApi = MockChatApiService();

      await tester.pumpWidget(
        MaterialApp(
          home: ChatRoomScreen(
            isDarkMode: false,
            apiService: mockApi,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Halo dari history backend!'), findsOneWidget);
    });

    testWidgets('sends message via ApiService and renders extracted tasks', (tester) async {
      final mockApi = MockChatApiService();
      bool taskCallbackTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ChatRoomScreen(
            isDarkMode: false,
            apiService: mockApi,
            onTasksCreated: () {
              taskCallbackTriggered = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter text and send
      await tester.enterText(find.byType(TextField), 'Besok review proposal');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();

      // Typing indicator
      expect(find.text('Companion sedang memikirkan respons...'), findsOneWidget);

      await tester.pumpAndSettle();

      // Verify response received
      expect(mockApi.sendCalled, isTrue);
      expect(find.text('Saya telah mencatat tugas dari chat ini.'), findsOneWidget);
      expect(find.text('TUGAS TERSINKRONKAN:'), findsOneWidget);
      expect(find.textContaining('Review proposal (2026-09-19)'), findsOneWidget);
      expect(taskCallbackTriggered, isTrue);
    });

    testWidgets('gracefully handles timeout or network failure with retry button', (tester) async {
      final mockApi = MockChatApiService();

      await tester.pumpWidget(
        MaterialApp(
          home: ChatRoomScreen(
            isDarkMode: false,
            apiService: mockApi,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Send error-triggering text
      await tester.enterText(find.byType(TextField), 'trigger error');
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();

      expect(find.textContaining('batas waktu Vercel (10s) terlampaui'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
    });
  });

  group('Fase 2 Profile Data Retention API Integration Tests', () {
    testWidgets('triggers export and override retention via ApiService', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockApi = MockChatApiService();

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            isDarkMode: false,
            onToggleTheme: () {},
            apiService: mockApi,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Unduh Backup
      await tester.tap(find.text('Unduh Backup'));
      await tester.pumpAndSettle();
      expect(mockApi.exportCalled, isTrue);

      // Tap Simpan Selamanya
      await tester.tap(find.text('Simpan Selamanya'));
      await tester.pumpAndSettle();
      expect(mockApi.overrideCalled, isTrue);
    });

    testWidgets('triggers deleteChatHistory after typing HAPUS', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockApi = MockChatApiService();

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            isDarkMode: false,
            onToggleTheme: () {},
            apiService: mockApi,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Hapus Riwayat Chat
      await tester.tap(find.text('Hapus Riwayat Chat'));
      await tester.pumpAndSettle();

      // Step 1
      await tester.tap(find.text('Lanjut ke Konfirmasi'));
      await tester.pumpAndSettle();

      // Step 2
      await tester.enterText(find.byType(TextField), 'HAPUS');
      await tester.pump();
      await tester.tap(find.text('Hapus Permanen'));
      await tester.pumpAndSettle();

      expect(mockApi.deleteCalled, isTrue);
    });
  });
}
