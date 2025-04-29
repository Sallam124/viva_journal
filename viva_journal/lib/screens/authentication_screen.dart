import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viva_journal/theme_provider.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({Key? key}) : super(key: key);

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _allowPinEntry = false;
  String _enteredCode = '';
  String? _savedPasscode;
  String? _errorMessage;
  bool _isAuthenticating = true;

  @override
  void initState() {
    super.initState();
    _startAuthentication();
  }

  Future<void> _startAuthentication() async {
    await _loadPasscode();
    bool canCheckBiometrics = await auth.canCheckBiometrics;

    if (canCheckBiometrics) {
      try {
        bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Authenticate to access Viva Journal',
          options: const AuthenticationOptions(
            biometricOnly: true,
          ),
        );

        if (didAuthenticate) {
          _goToHome();
          return;
        } else {
          setState(() {
            _allowPinEntry = true;
            _isAuthenticating = false;
          });
        }
      } catch (e) {
        print("Biometric error: $e");
        setState(() {
          _allowPinEntry = true;
          _isAuthenticating = false;
        });
      }
    } else {
      setState(() {
        _allowPinEntry = true;
        _isAuthenticating = false;
      });
    }
  }

  Future<void> _loadPasscode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedPasscode = prefs.getString('passcode');
    });
  }

  void _onNumberPressed(String digit) {
    if (_enteredCode.length < 4) {
      setState(() {
        _enteredCode += digit;
      });

      if (_enteredCode.length == 4) {
        _validatePasscode();
      }
    }
  }

  void _validatePasscode() {
    if (_enteredCode == _savedPasscode) {
      _goToHome();
    } else {
      setState(() {
        _errorMessage = "Incorrect Passcode. Try Again.";
        _enteredCode = '';
      });
    }
  }

  void _onBackspacePressed() {
    if (_enteredCode.isNotEmpty) {
      setState(() {
        _enteredCode = _enteredCode.substring(0, _enteredCode.length - 1);
      });
    }
  }

  void _goToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  Widget _buildNumberPad() {
    List<String> digits = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '', '0', '⌫',
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      shrinkWrap: true,
      itemCount: digits.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
      ),
      itemBuilder: (context, index) {
        final digit = digits[index];

        if (digit == '') {
          return const SizedBox.shrink();
        } else if (digit == '⌫') {
          return ElevatedButton(
            onPressed: _onBackspacePressed,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: Colors.grey.shade700,
            ),
            child: const Icon(Icons.backspace, color: Colors.white),
          );
        } else {
          return ElevatedButton(
            onPressed: () => _onNumberPressed(digit),
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: Colors.grey.shade800,
            ),
            child: Text(
              digit,
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final brightness = MediaQuery.of(context).platformBrightness;
    final isSystemDark = brightness == Brightness.dark;
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system && isSystemDark);

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: _isAuthenticating
            ? const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Authenticating...", style: TextStyle(fontSize: 18)),
          ],
        )
            : _allowPinEntry
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Enter Passcode", style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                    (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: index < _enteredCode.length ? textColor : textColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 30),
            _buildNumberPad(),
          ],
        )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
