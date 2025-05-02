  import 'package:flutter/material.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:google_sign_in/google_sign_in.dart';
  import 'package:viva_journal/screens/background_theme.dart';
  import 'package:viva_journal/screens/reset_password.dart';
  import 'package:viva_journal/widgets/widgets.dart';
  import 'package:email_validator/email_validator.dart';
  import 'package:shared_preferences/shared_preferences.dart';

  class LoginScreen extends StatefulWidget {
    const LoginScreen({super.key});
  
    @override
    // ignore: library_private_types_in_public_api
    _LoginScreenState createState() => _LoginScreenState();
  }
  
  class _LoginScreenState extends State<LoginScreen> {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final GoogleSignIn _googleSignIn = GoogleSignIn();
  
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
  
    String? errorMessage;
    bool _obscurePassword = true;
    final FocusNode _emailFocusNode = FocusNode();
    final FocusNode _passwordFocusNode = FocusNode();
  
    Future<void> _handleGoogleSignIn() async {
      try {
        final GoogleSignInAccount? account = await _googleSignIn.signIn();
        if (account != null) {
          // ignore: use_build_context_synchronously
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          setState(() => errorMessage = "Google Sign-In failed. Try again.");
        }
      } catch (error) {
        setState(() => errorMessage = "Google Sign-In error: $error");
      }
    }

    Future<void> _loginWithEmailPassword() async {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        setState(() => errorMessage = "Please enter both email and password!");
        return;
      }

      if (!EmailValidator.validate(email)) {
        setState(() => errorMessage = "Please enter a valid email address!");
        return;
      }

      try {
        final UserCredential userCredential = await _auth
            .signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();  // Clear any cached preferences

        if (userCredential.user != null && !userCredential.user!.emailVerified) {
          setState(() => errorMessage = "Please verify your email before logging in!");
        } else {

          await prefs.setBool('loggedInViaLoginScreen', true);

          // ignore: use_build_context_synchronously
          Navigator.pushReplacementNamed(context, '/home');
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          if (e.code == 'user-not-found') {
            errorMessage = "No user found for this email!";
          } else if (e.code == 'wrong-password') {
            errorMessage = "Incorrect password. Please try again!";
          } else {
            errorMessage = "Login error: ${e.message}";
          }
        });
      } catch (error) {
        setState(() => errorMessage = "Error: $error");
      }
    }

  
    void _togglePasswordVisibility() {
      setState(() => _obscurePassword = !_obscurePassword);
    }
  
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: BackgroundContainer(
              child: Column(
                children: [
                  const SizedBox(height: 30),
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
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 110),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ERROR MESSAGE right above the first text field
                            if (errorMessage != null) ...[
                              Text(
                                errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red, // More noticeable
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
  
                            buildTextField(
                              _emailController,
                              'Username or email',
                              _emailFocusNode,
                              context,
                                  () =>
                                  FocusScope.of(context).requestFocus(
                                      _emailFocusNode),
                            ),
                            const SizedBox(height: 30),
                            buildPasswordField(
                              _passwordController,
                              'Password',
                              _passwordFocusNode,
                              context,
                                  () =>
                                  FocusScope.of(context).requestFocus(
                                      _passwordFocusNode),
                              _obscurePassword,
                              _togglePasswordVisibility,
                            ),
                            const SizedBox(height: 30),
  
                            Align(
                              alignment: Alignment.center,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ForgotPasswordScreen(),
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
                            const SizedBox(height: 30),
  
                            SizedBox(
                              width: 250,
                              child: ElevatedButton(
                                onPressed: _loginWithEmailPassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'Log In',
                                  style: TextStyle(
                                      fontSize: 20, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
  
                            const Text(
                              'OR',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 30),
  
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
                                  'G',
                                  style: TextStyle(
                                      fontSize: 30, color: Colors.white),
                                ),
                                label: const Text(
                                  ' Continue with Google',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
  
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Don’t have an account?',
                                  style: TextStyle(color: Colors.black),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pushReplacementNamed(
                                          context, '/signUp'),
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
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
