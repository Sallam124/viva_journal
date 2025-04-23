import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:viva_journal/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
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
    if (_selectedTime != null) {
      prefs.setInt('notificationHour', _selectedTime!.hour);
      prefs.setInt('notificationMinute', _selectedTime!.minute);
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.themeMode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔔 Notification Toggle
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

              /// 🕒 Time Picker
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
                        _selectedTime == null
                            ? 'Pick a time'
                            : 'Selected: ${_selectedTime!.format(context)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 40),

              /// 🎨 Theme Mode (Dark + System only)
              const Text('Theme Mode:', style: TextStyle(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 10),
              ToggleButtons(
                isSelected: [
                  currentTheme == ThemeMode.dark,
                  currentTheme == ThemeMode.system,
                ],
                onPressed: (index) {
                  if (index == 0) themeProvider.setTheme(ThemeMode.dark);
                  if (index == 1) themeProvider.setTheme(ThemeMode.system);
                },
                borderRadius: BorderRadius.circular(20),
                selectedColor: Colors.white,
                fillColor: Colors.black87,
                color: Colors.white70,
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("Dark"),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("System"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
