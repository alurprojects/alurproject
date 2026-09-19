import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alur/screens/calendar/calendar_screen.dart';
import 'package:alur/screens/profile/profile_screen.dart';

void main() {
  group('Fase 1.5 Calendar Tests', () {
    testWidgets('renders time-block grid and responds to navigation', (tester) async {
      bool todoNavigated = false;

      await tester.pumpWidget(
        MaterialApp(
          home: CalendarScreen(
            isDarkMode: false,
            onNavigateToTodo: () {
              todoNavigated = true;
            },
          ),
        ),
      );

      // Verify header and time-block view title
      expect(find.text('CALENDAR'), findsOneWidget);
      expect(find.textContaining('Time-block View (06:00 - 22:00)'), findsOneWidget);

      // Verify time slot 06:00
      expect(find.text('06:00'), findsOneWidget);

      // Scroll to verify time slot 22:00
      await tester.scrollUntilVisible(find.text('22:00'), 300);
      expect(find.text('22:00'), findsOneWidget);

      // Verify Unscheduled section exists
      expect(find.textContaining('Unscheduled Tasks'), findsOneWidget);

      // Tap Unscheduled section to view tasks
      await tester.tap(find.textContaining('Unscheduled Tasks'));
      await tester.pumpAndSettle();

      // Tap on an unscheduled task chip
      expect(find.text('Riset referensi tipografi Inter'), findsOneWidget);
      await tester.tap(find.text('Riset referensi tipografi Inter'));
      expect(todoNavigated, isTrue);
    });
  });

  group('Fase 1.5 Profile & Retention Tests', () {
    testWidgets('renders user info, settings, and data retention notice banner', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            isDarkMode: false,
            onToggleTheme: () {},
          ),
        ),
      );

      // Verify section titles
      expect(find.text('PROFILE'), findsOneWidget);
      expect(find.text('PENGATURAN'), findsOneWidget);
      expect(find.text('SASARAN AKTIF (ACTIVE GOALS)'), findsOneWidget);
      expect(find.text('TINDAKAN PRIVASI'), findsOneWidget);

      // Verify Data Retention Notice Banner (H-7 alert)
      expect(find.text('Pemberitahuan Retensi Data (H-7)'), findsOneWidget);
      expect(find.text('Unduh Backup'), findsOneWidget);
      expect(find.text('Simpan Selamanya'), findsOneWidget);
      expect(find.text('Oke, hapus saja'), findsOneWidget);

      // Dismiss retention banner via 'Oke, hapus saja'
      await tester.tap(find.text('Oke, hapus saja'));
      await tester.pumpAndSettle();
      expect(find.text('Pemberitahuan Retensi Data (H-7)'), findsNothing);
    });

    testWidgets('requires 2-step verification typing HAPUS to delete chat history', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            isDarkMode: false,
            onToggleTheme: () {},
          ),
        ),
      );

      // Tap Hapus Riwayat Chat
      await tester.tap(find.text('Hapus Riwayat Chat'));
      await tester.pumpAndSettle();

      // Step 1: Warning dialog appears
      expect(find.textContaining('Langkah 1 dari 2'), findsOneWidget);
      expect(find.text('Lanjut ke Konfirmasi'), findsOneWidget);

      // Tap Lanjut ke Konfirmasi
      await tester.tap(find.text('Lanjut ke Konfirmasi'));
      await tester.pumpAndSettle();

      // Step 2: Verification dialog appears requiring keyword "HAPUS"
      expect(find.textContaining('Konfirmasi Akhir (Langkah 2/2)'), findsOneWidget);
      expect(find.text('Hapus Permanen'), findsOneWidget);

      // When text is empty or wrong, tapping Hapus Permanen does not trigger dismissal
      await tester.enterText(find.byType(TextField), 'SALAH');
      await tester.pump();
      await tester.tap(find.text('Hapus Permanen'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Konfirmasi Akhir (Langkah 2/2)'), findsOneWidget);

      // Enter correct keyword "HAPUS"
      await tester.enterText(find.byType(TextField), 'HAPUS');
      await tester.pump();
      await tester.tap(find.text('Hapus Permanen'));
      await tester.pumpAndSettle();

      // Verify dialog dismissed and success snackbar appears
      expect(find.textContaining('Konfirmasi Akhir (Langkah 2/2)'), findsNothing);
      expect(find.textContaining('berhasil dihapus permanen'), findsOneWidget);
    });
  });
}
