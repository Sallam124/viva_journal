import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ✅ Firebase Configurations
import 'package:viva_journal/screens/loading_screen.dart';
import 'package:viva_journal/screens/login_screen.dart';
import 'package:viva_journal/screens/sign_up_screen.dart';
import 'package:viva_journal/screens/home.dart';
import 'package:viva_journal/screens/background_theme.dart';
import 'package:viva_journal/screens/reset_password.dart';
import 'package:viva_journal/screens/dashboard_screen.dart';
import 'package:viva_journal/screens/calendar_screen.dart';
import 'package:viva_journal/screens/trackerlog_screen.dart';
import 'package:viva_journal/screens/settings_screen.dart';
import 'package:viva_journal/screens/journal_screen.dart';
import 'package:viva_journal/widgets/widgets.dart';

// Global Navigator Key for retrieving context anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Helper to wrap a screen with the BackgroundContainer and WillPopScope.
  Widget _buildRoute(Widget screen) {
    return buildWillPopWrapper(child: BackgroundContainer(child: screen));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ Enables global navigation access
      debugShowCheckedModeBanner: false,
      title: 'Flutter Journal App',
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        primarySwatch: Colors.grey,
        pageTransitionsTheme: PageTransitionsTheme( // ✅ Global Page Transition Animation
          builders: {
            TargetPlatform.android: FadePageTransition(), // ✅ Custom Fade Transition
            TargetPlatform.iOS: FadePageTransition(), // ✅ Works for iOS too
          },
        ),
      ),
      // ✅ Global wrapper to dismiss keyboard when tapping outside inputs
      builder: (context, child) => buildDismissKeyboardWrapper(child: child!),
      home: _buildRoute(JournalScreen(mood: 'happy', tags: [])), // ✅ Wrapped with exit confirmation and background theme
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
        '/journal': (context) => _buildRoute(JournalScreen(mood: 'happy', tags: [])),
      },
    );
  }
}

/// ✅ Custom Fade Transition for all Screens
class FadePageTransition extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    return FadeTransition(opacity: animation, child: child);
  }
}
