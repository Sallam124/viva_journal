import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viva_journal/theme_provider.dart';
import 'background_theme.dart'; // ✅ Already imported
import 'package:firebase_auth/firebase_auth.dart';
import 'package:viva_journal/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  TimeOfDay? _selectedTime;
  bool _authEnabled = false;
  String? _savedPasscode;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
      _authEnabled = prefs.getBool('authEnabled') ?? false;
      _savedPasscode = prefs.getString('passcode');
      final hour = prefs.getInt('notificationHour');
      final minute = prefs.getInt('notificationMinute');
      if (hour != null && minute != null) {
        _selectedTime = TimeOfDay(hour: hour, minute: minute);
      }
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('notificationsEnabled', _notificationsEnabled);
    prefs.setBool('authEnabled', _authEnabled);
    if (_selectedTime != null) {
      prefs.setInt('notificationHour', _selectedTime!.hour);
      prefs.setInt('notificationMinute', _selectedTime!.minute);
    }
    if (_savedPasscode != null) {
      prefs.setString('passcode', _savedPasscode!);
    }
  }

  void _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
      _savePreferences();
    }
  }

  Future<String?> _showPasscodeDialog(BuildContext context) async {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Passcode"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(labelText: '4-digit passcode'),
          maxLength: 4,
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.themeMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BackgroundContainer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Enable Notifications', style: TextStyle(fontSize: 18, color: Colors.white)),
                  Switch(
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                        if (!value) _selectedTime = null;
                      });
                      _savePreferences();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_notificationsEnabled)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Notification Time:', style: TextStyle(fontSize: 16, color: Colors.white)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _pickTime(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _selectedTime == null ? 'Pick a time' : 'Selected: ${_selectedTime!.format(context)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 40),
              const Text('Theme Mode:', style: TextStyle(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 10),
              ToggleButtons(
                isSelected: [currentTheme == ThemeMode.dark, currentTheme == ThemeMode.system],
                onPressed: (index) {
                  if (index == 0) themeProvider.setTheme(ThemeMode.dark);
                  if (index == 1) themeProvider.setTheme(ThemeMode.system);
                },
                borderRadius: BorderRadius.circular(20),
                selectedColor: Colors.white,
                fillColor: Colors.black87,
                color: Colors.white70,
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Dark")),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("System")),
                ],
              ),
              const SizedBox(height: 40),
              const Text('Authentication', style: TextStyle(fontSize: 18, color: Colors.white)),
              SwitchListTile(
                title: const Text('Enable Extra Authentication', style: TextStyle(color: Colors.white)),
                value: _authEnabled,
                onChanged: (value) {
                  setState(() {
                    _authEnabled = value;
                  });
                  _savePreferences();
                },
              ),
              if (_authEnabled)
                ElevatedButton(
                  onPressed: () async {
                    final newPasscode = await _showPasscodeDialog(context);
                    if (newPasscode != null) {
                      setState(() => _savedPasscode = newPasscode);
                      _savePreferences();
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  child: Text(_savedPasscode == null ? "Set Passcode" : "Change Passcode"),
                ),
              const SizedBox(height: 40),
              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error signing out')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
