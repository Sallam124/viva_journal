import 'package:flutter/material.dart'; // Correct import
import 'package:viva_journal/screens/login_screen.dart'; // Ensure the correct path

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure binding initialization
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Login Screen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:  LoginScreen(), // Ensure LoginScreen is a constant widget if possible
    );
  }
}
