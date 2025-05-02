import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:viva_journal/screens/home.dart';

class PinVerificationScreen extends StatefulWidget {
  const PinVerificationScreen({super.key});

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  String enteredPin = '';
  bool _isBiometricAvailable = false;
  String? _backgroundImage = 'assets/images/background.png';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _loadSavedBackground();
    _clearPreviousUserData();  // Add this line to clear old data
    _authenticateWithBiometrics(); // Trigger biometric authentication on load
  }

  void _checkBiometricAvailability() async {
    final isAvailable = await _localAuth.canCheckBiometrics;
    setState(() {
      _isBiometricAvailable = isAvailable;
    });
  }

  void _loadSavedBackground() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBackground = prefs.getString('background_image');
    if (savedBackground != null) {
      setState(() {
        _backgroundImage = savedBackground;
      });
    }
  }

  // ✅ Clear old session data
  void _clearPreviousUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('passcode');  // Clear old PIN
    await prefs.remove('isAuthenticated');  // Reset authentication status
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      bool isAuthenticated = false;

      if (_isBiometricAvailable) {
        isAuthenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate using your biometric credentials',
          options: const AuthenticationOptions(stickyAuth: true),
        );
      }

      if (isAuthenticated) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAuthenticated', true); // Save PIN status
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      //working with biometric authentication
    }
  }

  void _verifyPin(String enteredPin) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('passcode');

    if (savedPin == enteredPin) {
      await prefs.setBool('isAuthenticated', true); // Save verification status
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect PIN, please try again!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter PIN')),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              _backgroundImage!,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  onChanged: (value) {
                    setState(() {
                      enteredPin = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Enter your PIN',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 4,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _verifyPin(enteredPin);
                  },
                  child: const Text('Verify PIN'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
