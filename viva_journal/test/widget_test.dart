import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viva_journal/main.dart';
import 'package:viva_journal/services/auth_services.dart'; // Import AuthService
import 'package:viva_journal/screens/sign_up_screen.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Create a mock or real instance of AuthService (you can also mock it if necessary)
    AuthService authService = AuthService();

    // Build our app and trigger a frame. Pass the authService here
    await tester.pumpWidget(MyApp(authService: authService));

    // You can perform tests on specific parts of the widget now.
    // For example, verify if the app initializes correctly.
    expect(find.byType(MyApp), findsOneWidget);

    // Test logic can go here, e.g., testing buttons or states
    // Verify that the initial screen (SignUpScreen) is shown
    expect(find.byType(SignUpScreen), findsOneWidget);
  });
}
