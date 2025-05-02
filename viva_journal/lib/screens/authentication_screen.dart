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
  final TextEditingController _pinController = TextEditingController();

  bool _isBiometricAvailable = false;
  String? _backgroundImage = 'assets/images/background.png';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _loadSavedBackground();
<<<<<<< HEAD
    _authenticateWithBiometrics();
=======
    _clearPreviousUserData();  // Add this line to clear old data
    _authenticateWithBiometrics(); // Trigger biometric authentication on load
>>>>>>> 68e0b18927f958f12491b2918f23b526b4c7d67d
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

      if (isAuthenticated && mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAuthenticated', true);
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

  Future<void> _verifyPin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('passcode')?.trim();
    final enteredPin = _pinController.text.trim();

<<<<<<< HEAD
    print('DEBUG -> Saved PIN: $savedPin | Entered PIN: $enteredPin');

    if (enteredPin.isEmpty || enteredPin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 4-digit PIN')),
=======
    if (savedPin == enteredPin) {
      await prefs.setBool('isAuthenticated', true); // Save verification status
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
>>>>>>> 68e0b18927f958f12491b2918f23b526b4c7d67d
      );
      return;
    }

    if (savedPin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No passcode was set. Please go to settings.')),
      );
      return;
    }

    if (enteredPin == savedPin) {
      await prefs.setBool('isAuthenticated', true);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
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
                const Text(
                  'Please enter your 4-digit passcode',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'PIN',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  maxLength: 4,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _verifyPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  ),
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
