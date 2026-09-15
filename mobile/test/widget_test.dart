import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alur/models/task.dart';
import 'package:alur/widgets/day_strip.dart';
import 'package:alur/widgets/task_row.dart';

void main() {
  testWidgets('DayStrip displays uppercase name and responds to tap', (WidgetTester tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DayStrip(
            dayName: 'Tuesday',
            taskCount: 3,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('TUESDAY'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.text('TUESDAY'));
    expect(tapped, isTrue);
  });

  testWidgets('TaskRow renders checkbox and title with strikethrough when done', (WidgetTester tester) async {
    bool toggledValue = false;

    const pendingTask = Task(
      id: 'task-1',
      userId: 'user-1',
      title: 'Morning Workout',
      assignedDate: '2026-09-15',
      status: 'PENDING',
      source: 'MANUAL',
      isAmbiguous: false,
      aiGenerated: false,
      missedFollowUp: 'NONE',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskRow(
            task: pendingTask,
            onToggle: (val) {
              toggledValue = val;
            },
          ),
        ),
      ),
    );

    expect(find.text('Morning Workout'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);

    // Tap checkbox
    await tester.tap(find.byType(GestureDetector).first);
    expect(toggledValue, isTrue);

    // Render done task
    const doneTask = Task(
      id: 'task-2',
      userId: 'user-1',
      title: 'Read Book',
      assignedDate: '2026-09-15',
      status: 'DONE',
      source: 'MANUAL',
      isAmbiguous: false,
      aiGenerated: false,
      missedFollowUp: 'NONE',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskRow(
            task: doneTask,
            onToggle: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Read Book'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('TaskRow shows (?) marker for ambiguous tasks', (WidgetTester tester) async {
    const ambiguousTask = Task(
      id: 'task-3',
      userId: 'user-1',
      title: 'Brain dump item',
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
          ),
        ),
      ),
    );

    expect(find.text('(?)'), findsOneWidget);
  });
}
