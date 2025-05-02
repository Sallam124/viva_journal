import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viva_journal/main.dart';
import 'package:viva_journal/screens/home.dart';
import 'package:viva_journal/screens/login_screen.dart';
import 'package:viva_journal/theme_provider.dart';

// Import from central mock file
import '../mocks/mock_generator.mocks.dart';

void main() {
  late MockTestAuth mockAuth;
  late MockTestUser mockUser;
  late MockTestPrefs mockPrefs;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    mockAuth = MockTestAuth();
    mockUser = MockTestUser();
    mockPrefs = MockTestPrefs();

    // Configure mock user
    when(mockUser.uid).thenReturn('test123');
    when(mockUser.email).thenReturn('test@example.com');

    // Configure mock auth
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUser));

    // Configure mock preferences
    when(mockPrefs.getString('passcode')).thenReturn(null);
    when(mockPrefs.getBool('loggedInViaLoginScreen')).thenReturn(true);
    when(mockPrefs.setBool(any, any)).thenAnswer((_) async => true);
  });

  testWidgets('Should show HomeScreen when authenticated', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            Provider<FirebaseAuth>.value(value: mockAuth),
            Provider<SharedPreferences>.value(value: mockPrefs),
          ],
          child: const MyApp(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}