import 'dart:async'; // 👈 Needed for Timer
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:viva_journal/screens/login_screen.dart';
import 'package:viva_journal/screens/background_theme.dart';
import 'package:viva_journal/widgets/widgets.dart';
import 'package:email_validator/email_validator.dart'; // Email validation package

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ForgotPasswordScreenState createState() => ForgotPasswordScreenState();
}

class ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? errorMessage;
  bool emailSent = false;
  bool isLoading = false;

  int cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    // ✅ Reset previous success/error messages at the beginning
    setState(() {
      errorMessage = null;
      emailSent = false;
    });

    if (_emailController.text.isEmpty) {
      setState(() {
        errorMessage = "Please enter your email.";
      });
      return;
    }

    if (!EmailValidator.validate(_emailController.text)) {
      setState(() {
        errorMessage = "Please enter a valid email address.";
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());

      setState(() {
        emailSent = true;
        errorMessage = null;
      });

      _startCooldown();
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
        isLoading = false;
      });
    }
  }

  void _startCooldown() {
    setState(() {
      cooldownSeconds = 60;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (cooldownSeconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          cooldownSeconds--;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: BackgroundContainer(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Forgot Password',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your email to reset your password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 20),

                  // ✅ Show error message *above* the text field
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),

                  // ✅ Email input field
                  buildTextField(
                    _emailController,
                    'Enter your email',
                    _emailFocusNode,
                    context,
                        () {},
                  ),

                  // ✅ Success message *below* the text field
                  if (emailSent)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        "Password reset email sent! Check your inbox.",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ✅ Send Reset Link Button, Cooldown, or Loading
                  if (isLoading)
                    const CircularProgressIndicator()
                  else if (cooldownSeconds > 0)
                    Text(
                      'Please wait $cooldownSeconds seconds before retrying.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    )
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

                  // ✅ Back to Login button
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