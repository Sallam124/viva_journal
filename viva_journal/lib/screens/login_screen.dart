import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:viva_journal/screens/background_theme.dart';
import 'package:viva_journal/screens/home_screen.dart';
import 'package:viva_journal/screens/reset_password.dart';
import 'package:viva_journal/widgets/widgets.dart';
import 'package:email_validator/email_validator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? errorMessage;

  bool _obscurePassword = true;
  FocusNode _emailFocusNode = FocusNode();
  FocusNode _passwordFocusNode = FocusNode();

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        // Fetch Google user details
        String? userName = account.displayName;
        String? userEmail = account.email;
        String? userProfilePicture = account.photoUrl;

        print('User name: $userName');
        print('User email: $userEmail');
        print('User profile picture: $userProfilePicture');

        // Redirect to home screen
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

  Future<void> _loginWithEmailPassword() async {
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        setState(() {
          errorMessage = "Please enter both email and password.";
        });
        return;
      }

      if (!EmailValidator.validate(email)) {
        setState(() {
          errorMessage = "Please enter a valid email address.";
        });
        return;
      }

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if the user's email is verified
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        setState(() {
          errorMessage = "Please verify your email before logging in.";
        });
      } else {
        // Successfully logged in and email is verified
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          errorMessage = "No user found for this email.";
        } else if (e.code == 'wrong-password') {
          errorMessage = "Incorrect password. Please try again.";
        } else {
          errorMessage = "Login failed: ${e.message}";
        }
      });
    } catch (error) {
      setState(() {
        errorMessage = "Login failed: $error";
      });
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
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Dismiss keyboard on tap outside
        },
        child: BackgroundContainer(
          child: Center(
            child: SingleChildScrollView( // ✅ Wrap with SingleChildScrollView
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Column(
                        children: [
                          const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Log in to your account',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
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
                      _passwordFocusNode,
                      context,
                          () {
                        FocusScope.of(context).requestFocus(_passwordFocusNode);
                      },
                      _obscurePassword,
                      _togglePasswordVisibility,
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot your password?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 250,
                      child: ElevatedButton(
                        onPressed: _loginWithEmailPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                            'Log In', style: TextStyle(fontSize: 20, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (errorMessage != null)
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    const SizedBox(height: 10),
                    const Text(
                      'OR',
                      style: TextStyle(color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 250,
                      child: OutlinedButton.icon(
                        onPressed: _handleGoogleSignIn,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          backgroundColor: Colors.black,
                          side: const BorderSide(color: Colors.black),
                        ),
                        icon: const Text(
                            'G', style: TextStyle(fontSize: 30, color: Colors.white)),
                        label: const Text(
                          ' Continue with Google',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Don’t have an account?',
                            style: TextStyle(color: Colors.black)),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/signUp');
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.black,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }
}
