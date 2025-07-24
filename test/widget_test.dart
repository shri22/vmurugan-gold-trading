// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:digi_gold/main.dart';

void main() {
  testWidgets('Digi Gold login screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DigiGoldApp());

    // Verify that our app loads with the login screen.
    expect(find.text('Welcome to Digi Gold'), findsOneWidget);
    expect(find.text('Your digital gold investment journey starts here'), findsOneWidget);

    // Verify that login form elements exist.
    expect(find.text('Login to your account'), findsOneWidget);
    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
    expect(find.text('Login with Biometric'), findsOneWidget);

    // Verify register link exists.
    expect(find.text('Register'), findsOneWidget);
  });
}
