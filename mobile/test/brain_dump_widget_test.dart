import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alur/models/task.dart';
import 'package:alur/widgets/day_block.dart';
import 'package:alur/widgets/task_row.dart';

void main() {
  testWidgets('DayBlock displays Brain-dump button and responds to tap', (WidgetTester tester) async {
    bool brainDumpTapped = false;

    final dayData = DayData(
      date: '2026-09-15',
      dayName: 'Tuesday',
      isToday: true,
      tasks: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DayBlock(
              dayData: dayData,
              onToggleTask: (task, isDone) {},
              onAddTask: (title) {},
              onOpenBrainDump: () {
                brainDumpTapped = true;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Brain-dump'), findsOneWidget);
    await tester.tap(find.text('Brain-dump'));
    expect(brainDumpTapped, isTrue);
  });

  testWidgets('TaskRow inline clarification expands and submits minutes', (WidgetTester tester) async {
    int? clarifiedMins;

    const ambiguousTask = Task(
      id: 'task-ambig',
      userId: 'user-1',
      title: 'Design brainstorm',
      assignedDate: '2026-09-15',
      status: 'PENDING',
      source: 'BRAIN_DUMP',
      isAmbiguous: true,
      aiGenerated: true,
      missedFollowUp: 'NONE',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskRow(
            task: ambiguousTask,
            onToggle: (_) {},
            onClarify: (mins) {
              clarifiedMins = mins;
            },
          ),
        ),
      ),
    );

    // Initial state: shows (?) badge and does not show 'Berapa lama?'
    expect(find.text('(?)'), findsOneWidget);
    expect(find.text('Berapa lama?'), findsNothing);

    // Tap (?) to open inline clarification
    await tester.tap(find.text('(?)'));
    await tester.pump();

    expect(find.text('Berapa lama?'), findsOneWidget);
    expect(find.text('30m'), findsOneWidget);

    // Tap 30m pill
    await tester.tap(find.text('30m'));
    await tester.pump();

    expect(clarifiedMins, 30);
  });
}
