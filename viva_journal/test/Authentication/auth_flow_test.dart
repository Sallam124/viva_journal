import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:viva_journal/screens/login_screen.dart';
import 'package:mockito/mockito.dart';
import 'package:viva_journal/test/firebase_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';

// Create a mock for FirebaseWrapper
class MockFirebaseWrapper extends Mock implements FirebaseWrapper {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final mockFirebaseWrapper = MockFirebaseWrapper();

    // Mock the initializeFirebase method to simulate Firebase initialization
    when(mockFirebaseWrapper.initializeFirebase())
        .thenAnswer((_) async => FirebaseApp.instance);
  });

  group('LoginScreen UI tests', () {
    testWidgets('renders email and password fields', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      expect(find.text('Username or email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('shows error when fields are empty and login is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter both email and password!'), findsOneWidget);
    });

    testWidgets('shows error for invalid email', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      await tester.enterText(find.byType(TextField).first, 'invalidemail');
      await tester.enterText(find.byType(TextField).last, 'password123');

      final loginButton = find.widgetWithText(ElevatedButton, 'Log In');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address!'), findsOneWidget);
    });

    testWidgets('displays Google Sign-In button and responds to tap', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      final googleButton = find.widgetWithText(OutlinedButton, ' Continue with Google');
      expect(googleButton, findsOneWidget);

      await tester.tap(googleButton);
      await tester.pump();
    });

    testWidgets('navigates to Forgot Password screen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      final forgotPasswordText = find.text('Forgot your password?');
      await tester.tap(forgotPasswordText);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsNothing);
    });
  });
}
