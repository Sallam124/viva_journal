import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:viva_journal/screens/background_theme.dart';
import 'package:viva_journal/screens/home.dart';
import 'package:viva_journal/widgets/widgets.dart';  // Importing the form_widgets.dart file

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  String? userName;
  String? userEmail;
  String? userProfilePicture;
  String? errorMessage;

  bool _obscurePassword = true;
  FocusNode _emailFocusNode = FocusNode();
  FocusNode _passwordFocusNode = FocusNode();

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        userName = account.displayName;
        userEmail = account.email;
        userProfilePicture = account.photoUrl;

        print('User name: $userName');
        print('User email: $userEmail');
        print('User profile picture: $userProfilePicture');

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          errorMessage = "Google Sign-In failed. Please try again.";
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = "Google Sign-In error: $error";
      });
      print('Google Sign-In Error: $error');
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundContainer(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Move "Sign In" to the very top
                Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 38,  // Increased size
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Log in to your account',
                        style: TextStyle(
                          fontSize: 18,  // Reduced size and unbolded
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),  // Reduced space between text and fields
                buildTextField(
                  _emailController,
                  'Username or email',
                  _emailFocusNode,
                  context,
                      () {
                    FocusScope.of(context).requestFocus(_emailFocusNode);
                  },
                ),
                const SizedBox(height: 15),
                buildPasswordField(
                  _passwordController,
                  'Password',
                  true,
                  _passwordFocusNode,
                  context,
                      () {
                    FocusScope.of(context).requestFocus(_passwordFocusNode);
                  },
                  _obscurePassword,
                  _togglePasswordVisibility,
                ),
                const SizedBox(height: 10),  // Reduced space between Password and Log In button
                SizedBox(
                  width: 250, // Narrower button width
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, // Black color for login button
                      padding: const EdgeInsets.symmetric(vertical: 10), // Smaller button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // Round edges
                      ),
                    ),
                    child: const Text('Log In', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 10),  // Reduced space between Log In button and OR text
                if (errorMessage != null)
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                  ),
                const SizedBox(height: 10),  // Reduced space after error message
                // "OR" as bold text
                const Text(
                  'OR',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,  // Bold text
                  ),
                ),
                const SizedBox(height: 20),  // Reduced space between OR text and Google button
                // Google Sign-In Button, pulled towards the bottom
                SizedBox(
                  width: 250, // Adjusted size for "Continue with Google"
                  child: OutlinedButton.icon(
                    onPressed: _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),  // Reduced vertical padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // Round edges
                      ),
                      backgroundColor: Colors.black, // Make Google button black
                      side: const BorderSide(color: Colors.grey), // Border like input fields
                    ),
                    icon: const Text(
                      'G',
                      style: TextStyle(fontSize: 30, color: Colors.white), // Big white G
                    ),
                    label: const Text(
                      ' Continue with Google',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),  // Reduced space after Google button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Don’t have an account?',
                      style: TextStyle(color: Colors.black),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signUp');
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.black,
                          decoration: TextDecoration.underline, // Underlined and black
                          fontWeight: FontWeight.bold,  // Bold text for Sign Up
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
