import 'package:flutter/material.dart';
import 'package:viva_journal/screens/login_screen.dart';
import 'package:viva_journal/screens/sign_up_screen.dart';
import 'package:viva_journal/screens/home.dart';

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
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontFamily: 'SF Pro Display'),
          bodyMedium: TextStyle(fontFamily: 'SF Pro Display'),
          bodySmall: TextStyle(fontFamily: 'SF Pro Display'),
        ),
      ),
      home: LoginScreen(), // Initial screen (LoginScreen)
      routes: {
        '/signUp': (context) => SignUpScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
