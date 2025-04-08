import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:viva_journal/screens/login_screen.dart';
import 'package:viva_journal/screens/background_theme.dart';
import 'package:viva_journal/widgets/widgets.dart';
import 'package:email_validator/email_validator.dart'; // Added email validation package

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? errorMessage;
  bool emailSent = false;
  bool isLoading = false; // Added to track loading state

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  /// ✅ Sends a password reset request to Firebase
  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        errorMessage = "Please enter your email.";
      });
      return;
    }

    // Email validation
    if (!EmailValidator.validate(_emailController.text)) {
      setState(() {
        errorMessage = "Please enter a valid email address.";
      });
      return;
    }

    setState(() {
      isLoading = true; // Show loading indicator
    });

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());

      setState(() {
        emailSent = true;
        errorMessage = null;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found') {
          errorMessage = 'No user found for that email.';
        } else {
          errorMessage = e.message;
        }
      });
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Dismiss keyboard when tapping outside
        },
        child: BackgroundContainer(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Forgot Password',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Enter your email to reset your password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 30),

                  /// ✅ Input Field for Email
                  buildTextField(
                    _emailController,
                    'Enter your email',
                    _emailFocusNode,
                    context,
                        () {},
                  ),

                  const SizedBox(height: 15),

                  /// ✅ Show confirmation or error message
                  if (errorMessage != null)
                    Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (emailSent)
                    const Text(
                      "Password reset email sent! Check your inbox.",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  const SizedBox(height: 20),

                  /// ✅ Send Reset Link Button
                  if (isLoading)
                    const CircularProgressIndicator()
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Send Reset Link',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  /// ✅ Back to Login Button
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
