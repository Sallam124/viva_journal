
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
  bool _authEnabled = false;
  String? _savedPasscode;
  String? _savedBackground;

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
      _savedBackground = prefs.getString('background_image');
      final hour = prefs.getInt('notificationHour');
      final minute = prefs.getInt('notificationMinute');
      if (hour != null && minute != null) {
        _selectedTime = TimeOfDay(hour: hour, minute: minute);
      }
    });

    // لو مفيش خلفية محفوظة، نحفظ واحدة افتراضية
    if (_savedBackground == null) {
      await _saveBackground('assets/images/background.png');
    }
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

  Future<void> _saveBackground(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('background_image', path);
    setState(() {
      _savedBackground = path;
    });
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
          maxLength: 4,
          decoration: const InputDecoration(labelText: '4-digit passcode'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.themeMode;
    final brightness = MediaQuery.of(context).platformBrightness;
    final bool isDark = (currentTheme == ThemeMode.dark) ||
        (currentTheme == ThemeMode.system && brightness == Brightness.dark);

    final backgroundColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final toggleSelectedColor = isDark ? Colors.black : Colors.white;
    final toggleUnselectedColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
<<<<<<< Updated upstream
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        width: double.infinity,
        height: double.infinity,
=======
        width: double.infinity,
        height: double.infinity,
        decoration: () {
          if (currentTheme == ThemeMode.system) {
            if (_savedBackground != null) {
              return BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(_savedBackground!),
                  fit: BoxFit.cover,
                ),
              );
            } else {
              return BoxDecoration(
                color: isDark ? Colors.black : Colors.white,
              );
            }
          } else {
            if (isDark) {
              return const BoxDecoration(color: Colors.black);
            } else {
              return const BoxDecoration(color: Colors.white);
            }
          }
        }(),
>>>>>>> Stashed changes
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Enable Notifications', style: TextStyle(fontSize: 18, color: textColor)),
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
                    Text('Notification Time:', style: TextStyle(fontSize: 16, color: textColor)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _pickTime(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: toggleUnselectedColor,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _selectedTime == null
                            ? 'Pick a time'
                            : 'Selected: ${_selectedTime!.format(context)}',
                        style: TextStyle(color: toggleSelectedColor),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 40),
              Text('Theme Mode:', style: TextStyle(fontSize: 18, color: textColor)),
              const SizedBox(height: 10),
              ToggleButtons(
                isSelected: [
                  currentTheme == ThemeMode.light,
                  currentTheme == ThemeMode.dark,
                  currentTheme == ThemeMode.system
                ],
                onPressed: (index) {
                  setState(() {
                    if (index == 0) themeProvider.setTheme(ThemeMode.light);
                    if (index == 1) themeProvider.setTheme(ThemeMode.dark);
                    if (index == 2) themeProvider.setTheme(ThemeMode.system);
                  });
                },
                borderRadius: BorderRadius.circular(20),
                selectedColor: toggleSelectedColor,
                fillColor: toggleUnselectedColor,
                color: toggleUnselectedColor.withOpacity(0.6),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("Light", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("Dark", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("System", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text('Authentication', style: TextStyle(fontSize: 18, color: textColor)),
              SwitchListTile(
                title: Text('Enable Extra Authentication', style: TextStyle(color: textColor)),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: toggleUnselectedColor,
                  ),
                  child: Text(
                    _savedPasscode == null ? "Set Passcode" : "Change Passcode",
                    style: TextStyle(color: toggleSelectedColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
