import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:viva_journal/utils/auth_prefs.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  String _enteredCode = '';
  String? _savedPasscode;
  // final bool _isAuthenticating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startAuthentication();
  }

  Future<void> _startAuthentication() async {
    final bool enabled = await AuthPrefs.isBiometricEnabled();
    final String? savedCode = await AuthPrefs.getSavedPasscode();

    setState(() {
      _savedPasscode = savedCode;
    });

    if (enabled) {
      try {
        bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Authenticate with your biometrics',
          options: const AuthenticationOptions(biometricOnly: true),
        );

        if (didAuthenticate) {
          _goToHome();
        }
      } catch (e) {
        setState(() => _error = "Biometric error: $e");
      }
    }
  }

  void _onNumberPressed(String digit) {
    if (_enteredCode.length < 4) {
      setState(() {
        _enteredCode += digit;
      });

      if (_enteredCode.length == 4) {
        if (_enteredCode == _savedPasscode) {
          _goToHome();
        } else {
          setState(() {
            _error = "Incorrect Passcode";
            _enteredCode = '';
          });
        }
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter Passcode",
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                    (index) => Container(
                  margin: const EdgeInsets.all(8),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _enteredCode.length ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 30),
            _buildNumberPad(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return SizedBox(
      width: 240,
      child: Column(
        children: [
          for (var row in [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['', '0', '<']
          ])
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((value) {
                return _buildKey(value);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildKey(String value) {
    return GestureDetector(
      onTap: () {
        if (value == '<') {
          _onBackspacePressed();
        } else if (value.isNotEmpty) {
          _onNumberPressed(value);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          style: const TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}
