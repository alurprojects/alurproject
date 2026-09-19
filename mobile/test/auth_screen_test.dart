import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alur/screens/auth/auth_screen.dart';
import 'package:alur/screens/auth/widgets/google_sign_in_button.dart';

void main() {
  group('AuthScreen Tests', () {
    testWidgets('renders all essential auth elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthScreen(),
        ),
      );

      // Verify title / text
      expect(find.text('BE KIND TO YOUR TIME.'), findsOneWidget);
      expect(find.text('A realistic planner that respects your limits.'), findsOneWidget);
      expect(find.text('By continuing, you agree to our Terms'), findsOneWidget);

      // Verify buttons
      expect(find.byType(GoogleSignInButton), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });
  });
}
