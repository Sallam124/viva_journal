import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth functionality.
import 'firebase_options.dart'; // Firebase configuration options.
import 'package:viva_journal/screens/loading_screen.dart';
import 'package:viva_journal/screens/login_screen.dart';
import 'package:viva_journal/screens/sign_up_screen.dart';
import 'package:viva_journal/screens/home.dart'; // Fixed import path
import 'package:viva_journal/screens/background_theme.dart';
import 'package:viva_journal/screens/reset_password.dart';
import 'package:viva_journal/screens/dashboard_screen.dart';
import 'package:viva_journal/screens/calendar_screen.dart';
import 'package:viva_journal/screens/trackerlog_screen.dart';
import 'package:viva_journal/screens/settings_screen.dart';
import 'package:viva_journal/screens/journal_screen.dart';
import 'package:viva_journal/widgets/widgets.dart';

// Global navigator key for app-wide navigation control.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Main function: Initializes Firebase and runs the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Helper method to wrap a screen with BackgroundContainer and a WillPopScope.
  Widget _buildRoute(Widget screen) {
    return buildWillPopWrapper(child: BackgroundContainer(child: screen));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Viva Journal',
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        primarySwatch: Colors.grey,
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadePageTransition(),
            TargetPlatform.iOS: FadePageTransition(),
          },
        ),
      ),
      // Wraps each screen in a dismiss keyboard wrapper.
      builder: (context, child) => buildDismissKeyboardWrapper(child: child!),
      // Determines the initial route based on the user's Firebase login status.
      home: FutureBuilder<User?>(
        future: _checkUserLoginStatus(), // Check if user is already logged in.
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // While waiting for login status, show a loading screen.
            return _buildRoute(const LoadingScreen());
          } else if (snapshot.hasData && snapshot.data != null) {
            // If logged in, go to the HomeScreen
            return _buildRoute(const SignUpScreen());
          } else {
            // If not logged in, show the SignUpScreen.
            return _buildRoute(const SignUpScreen());
          }
        },
      ),
      // Define named routes for app navigation.
      routes: {
        '/signUp': (context) => _buildRoute(const SignUpScreen()),
        '/loading': (context) => _buildRoute(const LoadingScreen()),
        '/login': (context) => _buildRoute(const LoginScreen()),
        '/home': (context) => _buildRoute(const HomeScreen()),
        '/resetPassword': (context) => _buildRoute(const ForgotPasswordScreen()),
        '/dashboard': (context) => _buildRoute(DashboardScreen()),
        '/calendar': (context) => _buildRoute(CalendarScreen()),
        '/trackerLog': (context) => _buildRoute(TrackerLogScreen()),
        '/settings': (context) => _buildRoute(const SettingsScreen()),
        '/journal': (context) => _buildRoute(JournalScreen(mood: 'happy', tags: [])),
      },
    );
  }

  // Checks if a user is currently logged in via FirebaseAuth.
  Future<User?> _checkUserLoginStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    return user;
  }
}

/// Custom Fade Transition for page changes.
class FadePageTransition extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context,
      Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(opacity: animation, child: child);
  }
}
