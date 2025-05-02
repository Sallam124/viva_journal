import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viva_journal/screens/authentication_screen.dart';
import 'package:viva_journal/main.dart'; // For MyApp
import 'package:viva_journal/theme_provider.dart'; // For ThemeProvider

import 'pin_verification_test.mocks.dart'; // Import generated mocks

@GenerateMocks([SharedPreferences])
void main() {
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferences();
  });

  testWidgets('Skips PIN screen if no passcode exists', (tester) async {
    // Arrange
    when(mockPrefs.getString('passcode')).thenReturn(null);
    when(mockPrefs.getBool('isAuthenticated')).thenReturn(false);
    when(mockPrefs.getBool('loggedInViaLoginScreen')).thenReturn(true);

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          child: Builder(
            builder: (context) {
              return FutureBuilder<bool>(
                future: Future.value(true), // Mock successful auth
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return const MyApp();
                  }
                  return const CircularProgressIndicator();
                },
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(PinVerificationScreen), findsNothing);
  });

  testWidgets('Shows PIN screen if passcode exists', (tester) async {
    // Arrange
    when(mockPrefs.getString('passcode')).thenReturn('1234');
    when(mockPrefs.getBool('isAuthenticated')).thenReturn(false);
    when(mockPrefs.getBool('loggedInViaLoginScreen')).thenReturn(true);

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          child: Builder(
            builder: (context) {
              return FutureBuilder<bool>(
                future: Future.value(true), // Mock successful auth
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return const MyApp();
                  }
                  return const CircularProgressIndicator();
                },
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(PinVerificationScreen), findsOneWidget);
  });
}