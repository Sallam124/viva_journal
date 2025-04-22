import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // ✅ NEW
import 'firebase_options.dart';
import 'package:viva_journal/screens/loading_screen.dart';
import 'package:viva_journal/screens/login_screen.dart';
import 'package:viva_journal/screens/sign_up_screen.dart';
<<<<<<< Updated upstream
import 'package:viva_journal/screens/home.dart'; // HomeScreen is defined in home.dart.
=======
import 'package:viva_journal/screens/home.dart';
>>>>>>> Stashed changes
import 'package:viva_journal/screens/background_theme.dart';
import 'package:viva_journal/screens/reset_password.dart';
import 'package:viva_journal/screens/dashboard_screen.dart';
import 'package:viva_journal/screens/calendar_screen.dart';
import 'package:viva_journal/screens/trackerlog_screen.dart';
import 'package:viva_journal/screens/settings_screen.dart';
import 'package:viva_journal/screens/journal_screen.dart';
import 'package:viva_journal/widgets/widgets.dart';
import 'package:viva_journal/theme_provider.dart'; // ✅ NEW

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(), // ✅ Wrap app with ThemeProvider
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget _buildRoute(Widget screen) {
    return buildWillPopWrapper(child: BackgroundContainer(child: screen));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context); // ✅ Access theme

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
<<<<<<< Updated upstream
      title: 'Flutter Journal App',
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
      // Determines the initial route based on the user’s Firebase login status.
=======
      title: 'Viva Journal',
      theme: ThemeData.light(),           // ✅ Light theme
      darkTheme: ThemeData.dark(),        // ✅ Dark theme
      themeMode: themeProvider.themeMode, // ✅ Controlled by ThemeProvider

      themeAnimationCurve: Curves.easeInOut,
      themeAnimationDuration: const Duration(milliseconds: 400),

      builder: (context, child) => buildDismissKeyboardWrapper(child: child!),

>>>>>>> Stashed changes
      home: FutureBuilder<User?>(
        future: _checkUserLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildRoute(const LoadingScreen());
          } else if (snapshot.hasData && snapshot.data != null) {
<<<<<<< Updated upstream
            // If logged in, go to the CalendarScreen (serving as home).
=======
>>>>>>> Stashed changes
            return _buildRoute(const HomeScreen());
          } else {
            return _buildRoute(const SignUpScreen());
          }
        },
      ),

      routes: {
        '/signUp': (context) => _buildRoute(const SignUpScreen()),
        '/loading': (context) => _buildRoute(const LoadingScreen()),
        '/login': (context) => _buildRoute(const LoginScreen()),
        '/home': (context) => _buildRoute(const HomeScreen()),
        '/resetPassword': (context) => _buildRoute(const ForgotPasswordScreen()),
        '/dashboard': (context) => _buildRoute(const DashboardScreen()),
        '/calendar': (context) => _buildRoute(CalendarScreen()),
        '/trackerLog': (context) => _buildRoute(const TrackerLogScreen()),
        '/settings': (context) => _buildRoute(const SettingsScreen()),
        '/journal': (context) => _buildRoute(JournalScreen(mood: 'happy', tags: [])),
      },
    );
  }

  Future<User?> _checkUserLoginStatus() async {
    return FirebaseAuth.instance.currentUser;
  }
}

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
