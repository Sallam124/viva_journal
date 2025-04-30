import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'package:viva_journal/theme_provider.dart';
import 'package:viva_journal/widgets/widgets.dart';
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
import 'package:viva_journal/screens/authentication_screen.dart'; // Import the Authentication Screen

// Define navigator key globally
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

// Class to represent authentication status
class AuthStatus {
  final bool isLoggedIn;
  final bool isPinVerified;

  AuthStatus({required this.isLoggedIn, required this.isPinVerified});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        Locale('en'),
      ],
      home: FutureBuilder<AuthStatus>(
        future: _checkUserLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildRoute(const LoadingScreen());
          } else if (snapshot.hasData && snapshot.data!.isLoggedIn) {
            if (snapshot.data!.isPinVerified) {
              return _buildRoute(const HomeScreen());
            } else {
              return _buildRoute(const PinVerificationScreen());
            }
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
        '/dashboard': (context) => _buildRoute(DashboardScreen()),
        '/calendar': (context) => _buildRoute(CalendarScreen()),
        '/trackerLog': (context) => _buildRoute(TrackerLogScreen(date: DateTime.now())),
        '/settings': (context) => _buildRoute(const SettingsScreen()),
        '/authentication': (context) => _buildRoute(const PinVerificationScreen()),
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

  Future<AuthStatus> _checkUserLoginStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();

    // Always reset PIN verification on app start
    await prefs.setBool('isAuthenticated', false);

    return AuthStatus(
      isLoggedIn: user != null,
      isPinVerified: false,
    );
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
