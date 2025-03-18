import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ✅ Firebase Configurations
import 'package:viva_journal/screens/loading_screen.dart';
import 'package:viva_journal/screens/login_screen.dart';
import 'package:viva_journal/screens/sign_up_screen.dart';
import 'package:viva_journal/screens/home.dart';
import 'package:viva_journal/screens/background_theme.dart';
import 'package:viva_journal/screens/reset_password.dart'; // ✅ Import Reset Password Screen
import 'package:viva_journal/widgets/widgets.dart'; // ✅ Import widgets.dart for `buildWillPopWrapper`

// Global Navigator Key for retrieving context anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Correct Firebase initialization using firebase_options.dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: buildWillPopWrapper(
        child: BackgroundContainer(child: SignUpScreen()), // ✅ Wrapped with WillPopScope for exit confirmation
      ),
      routes: {
        '/signUp': (context) => buildWillPopWrapper(
          child: BackgroundContainer(child: SignUpScreen()),
        ),
        '/loading': (context) => buildWillPopWrapper(
          child: BackgroundContainer(child: LoadingScreen()),
        ),
        '/login': (context) => buildWillPopWrapper(
          child: BackgroundContainer(child: LoginScreen()),
        ),
        '/home': (context) => buildWillPopWrapper(
          child: BackgroundContainer(child: HomeScreen()),
        ),
        '/resetPassword': (context) => buildWillPopWrapper(
          child: BackgroundContainer(child: ForgotPasswordScreen()), // ✅ Added Reset Password Route
        ),
      },
    );
  }
}

/// ✅ Custom Fade Transition for all Screens
class FadePageTransition extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
      PageRoute<T> route, BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(opacity: animation, child: child);
  }
}
