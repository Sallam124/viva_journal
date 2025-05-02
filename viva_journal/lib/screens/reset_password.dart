import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:viva_journal/screens/login_screen.dart';
import 'package:viva_journal/screens/background_theme.dart';
import 'package:viva_journal/widgets/widgets.dart';
import 'package:email_validator/email_validator.dart';

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
        child: const BackgroundContainer(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: ForgotPasswordForm(),
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordForm extends StatelessWidget {
  const ForgotPasswordForm({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<ForgotPasswordScreenState>()!;
    return Column(
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

        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              state.errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        const SizedBox(height: 10),

        buildTextField(
          state._emailController,
          'Enter your email',
          state._emailFocusNode,
          context,
              () {},
        ),

        if (state.emailSent)
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

        if (state.isLoading)
          const CircularProgressIndicator()
        else if (state.cooldownSeconds > 0)
          Text(
            'Please wait ${state.cooldownSeconds} seconds before retrying.',
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
              onPressed: state._resetPassword,
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

        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
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
    );
  }
}
