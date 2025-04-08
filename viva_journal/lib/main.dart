import 'package:flutter/material.dart';
import 'package:viva_journal/screens/login_screen.dart';
import 'package:viva_journal/screens/sign_up_screen.dart';
import 'package:viva_journal/screens/home.dart';
<<<<<<< Updated upstream
=======
import 'package:viva_journal/screens/background_theme.dart';
import 'package:viva_journal/screens/reset_password.dart';
import 'package:viva_journal/screens/dashboard_screen.dart';
import 'package:viva_journal/screens/calendar_screen.dart';
import 'package:viva_journal/screens/trackerlog_screen.dart';
import 'package:viva_journal/screens/settings_screen.dart';
import 'package:viva_journal/screens/journal_screen.dart';
import 'package:viva_journal/widgets/widgets.dart';
import 'package:viva_journal/services/auth_services.dart'; // ✅ Import AuthService
>>>>>>> Stashed changes

void main() {
  WidgetsFlutterBinding.ensureInitialized();
<<<<<<< Updated upstream
  runApp(const MyApp());
=======

  // Initialize Firebase with specific platform options (for iOS, Android, etc.)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize AuthService to handle authentication-related functionality
  AuthService authService = AuthService();
  await authService.initializeFirebase(); // Initialize Firebase for AuthService

  runApp(MyApp(authService: authService)); // Pass AuthService to MyApp
>>>>>>> Stashed changes
}

class MyApp extends StatelessWidget {
  final AuthService authService;

  const MyApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Journal App',
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        primarySwatch: Colors.grey,
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontFamily: 'SF Pro Display'),
          bodyMedium: TextStyle(fontFamily: 'SF Pro Display'),
          bodySmall: TextStyle(fontFamily: 'SF Pro Display'),
        ),
      ),
<<<<<<< Updated upstream
      home: LoginScreen(), // Initial screen (LoginScreen)
=======
      // ✅ Global wrapper to dismiss keyboard when tapping outside inputs
      builder: (context, child) => buildDismissKeyboardWrapper(child: child!),
<<<<<<< Updated upstream
      home: _buildRoute(const HomeScreen()), // ✅ Wrapped with exit confirmation and background theme
>>>>>>> Stashed changes
      routes: {
        '/signUp': (context) => SignUpScreen(),
        '/home': (context) => HomeScreen(),
=======
      // Determine initial route based on authentication state
      home: _buildRoute(
        authService.isUserLoggedIn()
            ? const HomeScreen() // If logged in, go to HomeScreen
            : const SignUpScreen(), // Otherwise, show SignUpScreen
      ),
      routes: {
        '/signUp': (context) => _buildRoute(const SignUpScreen()),
        '/loading': (context) => _buildRoute(const LoadingScreen()),
        '/login': (context) => _buildRoute(const LoginScreen()),
        '/home': (context) => _buildRoute(const HomeScreen()),
        '/resetPassword': (context) => _buildRoute(const ForgotPasswordScreen()),
        '/dashboard': (context) => _buildRoute(const DashboardScreen()),
        '/calendar': (context) => _buildRoute(const CalendarScreen()),
        '/trackerLog': (context) => _buildRoute(const TrackerLogScreen()),
        '/settings': (context) => _buildRoute(const SettingsScreen()),
        '/journal': (context) => _buildRoute(JournalScreen(mood: 'null', tags: [])),
>>>>>>> Stashed changes
      },
    );
  }
}
