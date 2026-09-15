import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alur/models/task.dart';
import 'package:alur/widgets/follow_up_chip.dart';
import 'package:alur/widgets/task_row.dart';

void main() {
  testWidgets('FollowUpChip renders question and responds to all 3 action buttons', (WidgetTester tester) async {
    String? chosenAction;

    const missedTask = Task(
      id: 'task-missed-1',
      userId: 'user-1',
      title: 'Design research to-do app',
      assignedDate: '2026-09-14',
      status: 'MISSED',
      source: 'MANUAL',
      isAmbiguous: false,
      aiGenerated: false,
      missedFollowUp: 'PENDING',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FollowUpChip(
            task: missedTask,
            onAction: (act) {
              chosenAction = act;
            },
          ),
        ),
      ),
    );

    expect(find.text('"Design research to-do app" kemarin gak dicentang — lupa atau emang skip?'), findsOneWidget);
    expect(find.text('Udah, lupa centang'), findsOneWidget);
    expect(find.text('Emang skip'), findsOneWidget);
    expect(find.text('Pindah ke hari ini'), findsOneWidget);

    // Test tap 'Udah, lupa centang'
    await tester.tap(find.text('Udah, lupa centang'));
    expect(chosenAction, 'FORGOT');

    // Test tap 'Emang skip'
    await tester.tap(find.text('Emang skip'));
    expect(chosenAction, 'SKIPPED');

    // Test tap 'Pindah ke hari ini'
    await tester.tap(find.text('Pindah ke hari ini'));
    expect(chosenAction, 'RESCHEDULED');
  });

  testWidgets('TaskRow renders reschedule suggestion and responds to Terima / Abaikan', (WidgetTester tester) async {
    String? rescheduleAction;

    const taskWithSuggestion = Task(
      id: 'task-sug-1',
      userId: 'user-1',
      title: 'Long architecture review',
      assignedDate: '2026-09-15',
      status: 'PENDING',
      source: 'MANUAL',
      isAmbiguous: false,
      aiGenerated: false,
      missedFollowUp: 'NONE',
      suggestion: TaskSuggestion(
        id: 'sug-1',
        taskId: 'task-sug-1',
        userId: 'user-1',
        suggestedDate: '2026-09-17',
        reason: 'Overloaded today',
        status: 'PENDING',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskRow(
            task: taskWithSuggestion,
            onToggle: (_) {},
            onRescheduleAction: (act) {
              rescheduleAction = act;
            },
          ),
        ),
      ),
    );

    expect(find.text('AI sarankan pindah ke 2026-09-17'), findsOneWidget);
    expect(find.text('Terima'), findsOneWidget);
    expect(find.text('Abaikan'), findsOneWidget);

    // Tap Terima
    await tester.tap(find.text('Terima'));
    expect(rescheduleAction, 'ACCEPT');

    // Tap Abaikan
    await tester.tap(find.text('Abaikan'));
    expect(rescheduleAction, 'REJECT');
  });
}
