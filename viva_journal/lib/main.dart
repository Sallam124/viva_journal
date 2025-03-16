import 'package:flutter/material.dart';
import 'package:viva_journal/screens/loading_screen.dart';
import 'package:viva_journal/screens/login_screen.dart';
import 'package:viva_journal/screens/sign_up_screen.dart';
import 'package:viva_journal/screens/home.dart';
import 'package:viva_journal/screens/background_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Journal App',
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        primarySwatch: Colors.grey,
      ),
      home: WillPopScope(
        onWillPop: () async {
          return await _onWillPop(context);  // Check for back press
        },
        child: BackgroundContainer(child: SignUpScreen()), // Wrap with background
      ),
      routes: {
        '/signUp': (context) => BackgroundContainer(child: SignUpScreen()),
        // '/home': (context) => BackgroundContainer(child: ()),
        '/login': (context) => BackgroundContainer(child: LoginScreen()),
      },
    );
  }

  Future<bool> _onWillPop(BuildContext context) async {
    // Show a confirmation dialog when the back button is pressed
    final shouldExit = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Do you want to exit the app?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Don't exit
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Exit
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return shouldExit ?? false; // Only exit if the user confirms
  }
}
