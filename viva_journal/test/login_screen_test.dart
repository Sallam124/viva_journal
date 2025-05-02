import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:viva_journal/screens/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'LoginScreen accepts input and triggers login logic', (tester) async {
    final mockUser = MockUser(email: 'test@example.com', isEmailVerified: true);
    final mockAuth = MockFirebaseAuth(mockUser: mockUser);

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(auth: mockAuth),
      ),
    );

    await tester.pumpAndSettle();

    // ✅ Enter email
    final emailField = find
        .byType(TextField)
        .first;
    await tester.enterText(emailField, 'test@example.com');

    // ✅ Enter password
    final passwordField = find
        .byType(TextField)
        .last;
    await tester.enterText(passwordField, 'password123');

    // ✅ Tap Login button
    final loginButton = find.text('Log In');
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // ✅ Success: Just ensure no error message is shown
    expect(find.textContaining('Login error'), findsNothing);
  });
}