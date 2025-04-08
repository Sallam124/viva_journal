import 'package:flutter/material.dart';
import 'package:viva_journal/screens/background_theme.dart';
import 'package:viva_journal/screens/sign_up_screen.dart';
import 'package:viva_journal/screens/home.dart';

<<<<<<< Updated upstream
class LoginScreen extends StatefulWidget {
=======
class LoginScreen extends StatefulWidget
{
  const LoginScreen({super.key});

>>>>>>> Stashed changes
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
<<<<<<< Updated upstream
=======
  FocusNode _emailFocusNode = FocusNode();
  FocusNode _passwordFocusNode = FocusNode();

  // Check if the email exists in Firebase
  Future<bool> _emailExists(String email) async {
    try {
      final user = await _auth.fetchSignInMethodsForEmail(email);
      return user.isNotEmpty;
    } catch (error) {
      print("Error checking email existence: $error");
      return false;
    }
  }

  // Handle Google Sign-In
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

  // Login with email and password
  Future<void> _loginWithEmailPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = "Please enter both email and password.";
      });
      return;
    }

    // Check if the email exists
    bool emailExists = await _emailExists(email);
    if (!emailExists) {
      setState(() {
        errorMessage = "No account found for this Username/Email.";
      });
      return;
    }

    try {
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
      if (e.code == 'user-not-found') {
        setState(() {
          errorMessage = "No user found for this email.";
        });
      } else if (e.code == 'wrong-password') {
        setState(() {
          errorMessage = "Incorrect password. Please try again.";
        });
      } else {
        setState(() {
          errorMessage = "Login failed: ${e.message}";
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = "Login failed: $error";
      });
    }
  }

  // Toggle password visibility
  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
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
=======
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 250,
                    child: ElevatedButton(
                      onPressed: _loginWithEmailPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                          'Log In', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (errorMessage != null)
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.black, fontSize: 14),
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
>>>>>>> Stashed changes
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
