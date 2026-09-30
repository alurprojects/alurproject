import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alur/models/morning_brief.dart';
import 'package:alur/widgets/morning_brief_banner.dart';

void main() {
  final sampleBrief = MorningBriefData(
    date: '2026-09-29',
    greeting: 'Selamat pagi! Hari Selasa, 29 September 2026.',
    tasks: const [
      MorningBriefTaskItem(id: 't-1', title: 'Review PR Backend', estimatedMinutes: 60),
      MorningBriefTaskItem(id: 't-2', title: 'Design Morning Banner', estimatedMinutes: 120),
    ],
    missedTasks: const [
      MorningBriefMissedItem(id: 'm-1', title: 'Email client', followUp: 'PENDING'),
    ],
    capacitySummary: const MorningBriefCapacity(
      totalHours: 6.0,
      scheduledHours: 3.0,
      remainingHours: 3.0,
    ),
    aiNote: 'Hari ini ada 2 tugas terencana dengan estimasi sisa fokus ~3.0 jam.',
  );

  testWidgets('MorningBriefBanner renders all sections correctly', (WidgetTester tester) async {
    bool dismissed = false;
    bool addTaskCalled = false;
    bool openChatCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MorningBriefBanner(
            brief: sampleBrief,
            onDismiss: () => dismissed = true,
            onEditTask: (_, __) {},
            onDeleteTask: (_) {},
            onFollowUpMissed: (_, __) {},
            onAddTask: () => addTaskCalled = true,
            onOpenChat: () => openChatCalled = true,
          ),
        ),
      ),
    );

    // Verify Greeting & Header
    expect(find.text('Selamat pagi! Hari Selasa, 29 September 2026.'), findsOneWidget);

    // Verify Tasks
    expect(find.text('2 task direncanakan hari ini:'), findsOneWidget);
    expect(find.text('Review PR Backend (1 jam)'), findsOneWidget);
    expect(find.text('Design Morning Banner (2 jam)'), findsOneWidget);

    // Verify Missed tasks
    expect(find.text('1 task kemarin belum selesai:'), findsOneWidget);
    expect(find.text('→ "Email client"'), findsOneWidget);
    expect(find.text('Udah'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('➡ Hari ini'), findsOneWidget);

    // Verify Capacity & AI note
    expect(find.text('Kapasitas fokus tersisa: ~3.0 jam'), findsOneWidget);
    expect(find.text('Hari ini ada 2 tugas terencana dengan estimasi sisa fokus ~3.0 jam.'), findsOneWidget);

    // Verify Action Buttons
    expect(find.text('Tambah task'), findsOneWidget);
    expect(find.text('Cerita ke AI'), findsOneWidget);

    // Test dismiss button tap
    await tester.tap(find.byTooltip('Tutup brief'));
    expect(dismissed, isTrue);

    // Test Add task button tap
    await tester.tap(find.text('Tambah task'));
    expect(addTaskCalled, isTrue);

    // Test Cerita ke AI tap
    await tester.tap(find.text('Cerita ke AI'));
    expect(openChatCalled, isTrue);
  });

  testWidgets('MorningBriefBanner handles missed task follow-up callbacks', (WidgetTester tester) async {
    String? actionTriggered;
    String? taskTriggered;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MorningBriefBanner(
            brief: sampleBrief,
            onDismiss: () {},
            onEditTask: (_, __) {},
            onDeleteTask: (_) {},
            onFollowUpMissed: (id, act) {
              taskTriggered = id;
              actionTriggered = act;
            },
            onAddTask: () {},
            onOpenChat: () {},
          ),
        ),
      ),
    );

    // Tap 'Udah'
    await tester.tap(find.text('Udah'));
    expect(taskTriggered, 'm-1');
    expect(actionTriggered, 'FORGOT');

    // Tap 'Skip'
    await tester.tap(find.text('Skip'));
    expect(taskTriggered, 'm-1');
    expect(actionTriggered, 'SKIPPED');

    // Tap '➡ Hari ini'
    await tester.tap(find.text('➡ Hari ini'));
    expect(taskTriggered, 'm-1');
    expect(actionTriggered, 'RESCHEDULED');
  });

  testWidgets('MorningBriefBanner opens edit dialog and submits change', (WidgetTester tester) async {
    String? editedId;
    String? editedTitle;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MorningBriefBanner(
            brief: sampleBrief,
            onDismiss: () {},
            onEditTask: (id, title) {
              editedId = id;
              editedTitle = title;
            },
            onDeleteTask: (_) {},
            onFollowUpMissed: (_, __) {},
            onAddTask: () {},
            onOpenChat: () {},
          ),
        ),
      ),
    );

    // Tap first 'Edit'
    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();

    // Verify dialog appeared
    expect(find.text('Edit Task'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);

    // Change text field
    await tester.enterText(find.byType(TextField), 'Review PR Backend v2');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(editedId, 't-1');
    expect(editedTitle, 'Review PR Backend v2');
  });
}
