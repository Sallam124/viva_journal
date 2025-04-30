import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'firebase_options.dart';
import 'package:viva_journal/theme_provider.dart';
import 'package:viva_journal/widgets/widgets.dart';
import 'package:viva_journal/screens/loading_screen.dart';
import 'package:viva_journal/screens/login_screen.dart';
import 'package:viva_journal/screens/sign_up_screen.dart';
import 'package:viva_journal/screens/home_screen.dart';
import 'package:viva_journal/screens/background_theme.dart';
import 'package:viva_journal/screens/reset_password.dart';
import 'package:viva_journal/screens/dashboard_screen.dart';
import 'package:viva_journal/screens/calendar_screen.dart';
import 'package:viva_journal/screens/trackerlog_screen.dart';
import 'package:viva_journal/screens/settings_screen.dart';
import 'package:viva_journal/screens/journal_screen.dart';
import 'package:viva_journal/screens/authentication_screen.dart'; // Import the Authentication Screen

// Define navigator key globally
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Method to wrap screens with background theme container
  Widget _buildRoute(Widget screen) {
    return BackgroundContainer(child: screen);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Viva Journal',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.themeMode,
      themeAnimationCurve: Curves.easeInOut,
      themeAnimationDuration: const Duration(milliseconds: 400),
      builder: (context, child) => buildDismissKeyboardWrapper(child: child!),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // Add other supported locales if needed
      ],

      // Using FutureBuilder to check login status and display AuthenticationScreen if not logged in
      home: FutureBuilder<User?>(
        future: _checkUserLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildRoute(const LoadingScreen()); // Show loading screen while checking login
          } else if (snapshot.hasData && snapshot.data != null) {
            return _buildRoute(const HomeScreen()); // User is logged in, go to HomeScreen
          } else {
            return _buildRoute(const AuthenticationScreen()); // If user is not logged in, go to AuthenticationScreen
          }
        },
      ),

      // Define named routes
      routes: {
        '/signUp': (context) => _buildRoute(const SignUpScreen()),
        '/loading': (context) => _buildRoute(const LoadingScreen()),
        '/login': (context) => _buildRoute(const LoginScreen()),
        '/home': (context) => _buildRoute(const HomeScreen()),
        '/resetPassword': (context) => _buildRoute(const ForgotPasswordScreen()),
        '/dashboard': (context) => _buildRoute(DashboardScreen()),
        '/calendar': (context) => _buildRoute(CalendarScreen()),
        '/trackerLog': (context) => _buildRoute(TrackerLogScreen(date: DateTime.now())),
        '/settings': (context) => _buildRoute(const SettingsScreen()),
        '/journal': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return _buildRoute(JournalScreen(
            date: args['date'] as DateTime,
            color: args['color'] as Color,
          ));
        },
      },
    );
  }

  // Method to check user login status
  Future<User?> _checkUserLoginStatus() async {
    return FirebaseAuth.instance.currentUser; // Check if the user is logged in
  }
}

// Custom Page Transition - FadePageTransition
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
