import 'package:flutter/material.dart';
import 'package:viva_journal/screens/background_theme.dart';
import 'package:viva_journal/screens/sign_up_screen.dart';
import 'package:viva_journal/screens/home.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BackgroundWidget(), // Background Theme
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                SizedBox(height: 100),
                Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Log In to Your Account',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                Spacer(),
                // Username Input Field
                TextField(
                  controller: _usernameController,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Username or email',
                    hintStyle: TextStyle(color: Colors.black54),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.black54, width: 2), // Thicker white border
                    ),
                  ),
                ),
                SizedBox(height: 15),
                // Password Input Field
                TextField(
                  controller: _passwordController,
                  textAlign: TextAlign.center,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(color: Colors.black54),
                    filled: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.black54, width: 3), // Thicker white border
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // Log In Button
                SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text('Log In', style: TextStyle(color: Colors.white)),
                  ),
                ),
                SizedBox(height: 20),
                // OR Text
                Text(
                  'or',
                  style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                // Continue with Google Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: Text(
                      'G',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    label: Text('Continue with Google', style: TextStyle(color: Colors.white)),
                  ),
                ),
                SizedBox(height: 15),
                // Continue with SMS Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: Icon(Icons.phone_iphone, color: Colors.white, size: 24),
                    label: Text('Continue with SMS', style: TextStyle(color: Colors.white)),
                  ),
                ),
                Spacer(),
                // Sign Up Text
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signUp');
                  },
                  child: Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signUp');
                  },
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      color: Colors.black,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20, top: 5),
                  child: Text(
                    'By continuing, you agree to the terms and Conditions \nand Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
