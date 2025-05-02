import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:viva_journal/screens/home.dart';

class PinVerificationScreen extends StatefulWidget {
  const PinVerificationScreen({Key? key}) : super(key: key);

  @override
  _PinVerificationScreenState createState() => _PinVerificationScreenState();
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
    _authenticateWithBiometrics();
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
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      print("Biometric authentication error: $e");
    }
  }

  Future<void> _verifyPin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('passcode')?.trim();
    final enteredPin = _pinController.text.trim();

    print('DEBUG -> Saved PIN: $savedPin | Entered PIN: $enteredPin');

    if (enteredPin.isEmpty || enteredPin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 4-digit PIN')),
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
