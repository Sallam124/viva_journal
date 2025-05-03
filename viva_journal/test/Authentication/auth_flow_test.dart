import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:viva_journal/screens/login_screen.dart'; // Adjust the path accordingly

// Create a Mock class for FirebaseAuth
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  // Create an instance of the mock
  final mockAuth = MockFirebaseAuth();

  // Mock the signInWithEmailAndPassword method
  when(mockAuth.signInWithEmailAndPassword(
    email: 'test@example.com',
    password: 'password123',
  )).thenAnswer((_) async => UserCredential(
    credential: AuthCredential(providerId: 'email', signInMethod: 'email'),
    user: User(
      uid: '123',
      email: 'test@example.com',
      displayName: 'Test User',
      photoURL: 'http://photo.url',
    ),
  ));

  testWidgets('Login navigates to HomeScreen on success', (WidgetTester tester) async {
    // Build the LoginScreen widget
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(firebaseAuth: mockAuth), // Pass the mock auth instance
      routes: {'/home': (context) => HomeScreen()},
    ));

    // Enter test email and password
    await tester.enterText(find.byKey(Key('emailField')), 'test@example.com');
    await tester.enterText(find.byKey(Key('passwordField')), 'password123');

    // Tap login button
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle(); // Wait for the result

    // Verify that the HomeScreen widget is displayed
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
