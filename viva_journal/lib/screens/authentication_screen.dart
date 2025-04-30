import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart'; // Add the local_auth package
import 'package:viva_journal/screens/home.dart'; // Main screen after successful authentication
import 'package:viva_journal/utils/auth_prefs.dart'; // Import AuthPrefs helper class

class PinVerificationScreen extends StatefulWidget {
  const PinVerificationScreen({Key? key}) : super(key: key);

  @override
  _PinVerificationScreenState createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication(); // Initialize LocalAuthentication class
  String enteredPin = ''; // To hold the entered PIN
  bool _isBiometricAvailable = false;
  String? _backgroundImage = 'assets/images/default_background.jpg'; // Default background image

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability(); // Check if biometric authentication is available
    _loadSavedBackground(); // Load the saved background image
  }

  // Check if biometric authentication is available (Face ID or Fingerprint)
  void _checkBiometricAvailability() async {
    final isAvailable = await _localAuth.canCheckBiometrics;
    setState(() {
      _isBiometricAvailable = isAvailable;
    });
  }

  // Load the saved background image from SharedPreferences
  void _loadSavedBackground() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBackground = prefs.getString('background_image');
    if (savedBackground != null) {
      setState(() {
        _backgroundImage = savedBackground; // Use the saved background image
      });
    }
  }

  // Authenticate the user with biometric authentication (if available)
  Future<void> _authenticateWithBiometrics() async {
    try {
      bool isAuthenticated = false;

      if (_isBiometricAvailable) {
        // Try biometric authentication
        isAuthenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate using your biometric credentials',
          options: const AuthenticationOptions(stickyAuth: true),
        );
      }

      if (isAuthenticated) {
        // If biometric authentication is successful, navigate to the HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        // If biometric authentication fails, prompt for PIN
        _showPinDialog();
      }
    } catch (e) {
      print("Biometric authentication error: $e");
      _showPinDialog(); // If biometric authentication fails, fall back to PIN
    }
  }

  // Function to show the PIN dialog
  void _showPinDialog() async {
    final enteredPin = await _showPasscodeDialog(context);
    if (enteredPin != null) {
      _verifyPin(enteredPin);
    }
  }

  // Verify the entered PIN
  void _verifyPin(String enteredPin) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('passcode'); // Getting saved PIN from SharedPreferences

    if (savedPin == enteredPin) {
      // If the entered PIN matches the saved PIN, navigate to the HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      // Show error if the PIN is incorrect
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect PIN, please try again!')),
      );
    }
  }

  // Show the PIN input dialog
  Future<String?> _showPasscodeDialog(BuildContext context) async {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Passcode"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true, // Hide the PIN as the user types
          decoration: const InputDecoration(labelText: '4-digit passcode'),
          maxLength: 4, // Assuming 4-digit PIN
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text("Save")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Attempt biometric authentication when the screen loads
    _authenticateWithBiometrics();

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
                // PIN input field
                TextField(
                  keyboardType: TextInputType.number,
                  obscureText: true,  // Hide the PIN as the user types
                  onChanged: (value) {
                    setState(() {
                      enteredPin = value;  // Update the entered PIN
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Enter your PIN',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 4,  // Assuming 4-digit PIN
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _verifyPin(enteredPin); // Verify PIN if entered manually
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
