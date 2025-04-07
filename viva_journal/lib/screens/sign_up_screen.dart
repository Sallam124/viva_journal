import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Import Google Sign-In package
import 'package:viva_journal/widgets/widgets.dart';
import 'package:viva_journal/screens/background_theme.dart';
import 'package:viva_journal/screens/login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Google Sign-In instance

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  User? _newlyCreatedUser;
  bool _canResendEmail = true;
  int _resendCooldown = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    _resendTimer?.cancel();
    super.dispose();
  }

  void _startCooldownTimer() {
    setState(() {
      _canResendEmail = false;
      _resendCooldown = 30;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown == 1) {
        timer.cancel();
        setState(() {
          _canResendEmail = true;
          _resendCooldown = 0;
        });
      } else {
        setState(() {
          _resendCooldown--;
        });
      }
    });
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final existingMethods = await _auth.fetchSignInMethodsForEmail(email);
      if (existingMethods.isNotEmpty) {
        _showErrorPopup("An account already exists with this email.");
        setState(() => _isLoading = false);
        return;
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      _newlyCreatedUser = userCredential.user;

      // Send verification email but don't store user in Firebase yet
      await _newlyCreatedUser!.sendEmailVerification();
      _showInfoPopup("Verification email sent. Please check your inbox.");

      // Start periodic check for email verification
      _startCooldownTimer();
      _checkEmailVerification();
    } catch (error) {
      _showErrorPopup("Sign-up failed: $error");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkEmailVerification() async {
    Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_newlyCreatedUser != null && _newlyCreatedUser!.emailVerified) {
        // Once the email is verified, store the user details in Firestore
        await _firestore.collection('users').doc(_newlyCreatedUser!.uid).set({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'createdAt': Timestamp.now(),
        });

        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const LoginScreen()));
        timer.cancel();
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    if (_newlyCreatedUser != null && _canResendEmail) {
      try {
        await _newlyCreatedUser!.sendEmailVerification();
        _showInfoPopup("Verification email resent.");
        _startCooldownTimer();
      } catch (e) {
        _showErrorPopup("Failed to resend email: $e");
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        final GoogleSignInAuthentication googleAuth = await account.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in with Google credentials
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        final User? user = userCredential.user;

        if (user != null) {
          // Check if the user is new, and if so, store them in Firestore
          if (userCredential.additionalUserInfo?.isNewUser == true) {
            await _firestore.collection('users').doc(user.uid).set({
              'username': account.displayName,
              'email': account.email,
              'createdAt': Timestamp.now(),
            });
          }
          // Redirect to the home screen
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (error) {
      _showErrorPopup("Google Sign-In error: $error");
    }
  }

  void _showErrorPopup(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  void _showInfoPopup(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: BackgroundContainer(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  const Text('Sign Up', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('Create Your Account', style: TextStyle(fontSize: 16, color: Colors.black54)),
                  const SizedBox(height: 40),
                  CustomTextFormField(
                    controller: _usernameController,
                    focusNode: _usernameFocusNode,
                    hint: 'Username',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Username required';
                      if (value.trim().length < 4) return 'Username must be at least 4 characters';
                      return null;
                    },
                    onTap: () => FocusScope.of(context).requestFocus(_usernameFocusNode),
                  ),
                  const SizedBox(height: 15),
                  CustomTextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    hint: 'Email',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Email required';
                      const pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
                      if (!RegExp(pattern).hasMatch(value.trim())) return 'Invalid email format';
                      return null;
                    },
                    onTap: () => FocusScope.of(context).requestFocus(_emailFocusNode),
                  ),
                  const SizedBox(height: 15),
                  CustomTextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    hint: 'Password',
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Password required';
                      if (value.length < 8) return 'Password must be at least 8 characters';
                      if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Password must include at least one uppercase letter';
                      if (!RegExp(r'[a-z]').hasMatch(value)) return 'Password must include at least one lowercase letter';
                      if (!RegExp(r'[0-9]').hasMatch(value)) return 'Password must include a number';
                      return null;
                    },
                    onTap: () => FocusScope.of(context).requestFocus(_passwordFocusNode),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.black54),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 15),
                  CustomTextFormField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocusNode,
                    hint: 'Confirm Password',
                    obscureText: _obscureConfirmPassword,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Confirm password required';
                      if (value.trim() != _passwordController.text.trim()) return 'Passwords do not match';
                      return null;
                    },
                    onTap: () => FocusScope.of(context).requestFocus(_confirmPasswordFocusNode),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.black54),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text('Sign Up', style: TextStyle(fontSize: 16, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 27),
                      const Text('or', style: TextStyle(fontSize: 25, color: Colors.black54)),
                      const SizedBox(height: 27),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handleGoogleSignIn,
                          icon: const Text('G', style: TextStyle(fontSize: 20, color: Colors.white)),
                          label: const Text('Continue with Google', style: TextStyle(fontSize: 18, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_newlyCreatedUser != null) ...[
                    const SizedBox(height: 20),
                    _canResendEmail
                        ? TextButton(
                      onPressed: _resendVerificationEmail,
                      child: const Text(
                        "Resend Verification Email",
                        style: TextStyle(fontSize: 16, color: Colors.black, decoration: TextDecoration.underline),
                      ),
                    )
                        : Text("Wait $_resendCooldown seconds to resend.", style: const TextStyle(color: Colors.black)),
                  ],
                  const SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? ', style: TextStyle(fontSize: 16)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(fontSize: 16, color: Colors.black, decoration: TextDecoration.underline),
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
    );
  }
}
