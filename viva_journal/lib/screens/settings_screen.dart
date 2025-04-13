import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _selectedHour;
  String? _selectedMinute;

  final List<String> hours = List.generate(24, (i) => i.toString().padLeft(2, '0'));
  final List<String> minutes = ['00', '15', '30', '45'];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// 🖼 Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/images/background.png',
            fit: BoxFit.cover,
          ),
        ),

        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text("Notification Settings"),
            backgroundColor: Colors.black87,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// Custom Dropdown Time Picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DropdownButton<String>(
                      value: _selectedHour,
                      hint: const Text("Hour", style: TextStyle(color: Colors.white)),
                      dropdownColor: Colors.grey[900],
                      style: const TextStyle(color: Colors.white),
                      items: hours.map((hour) {
                        return DropdownMenuItem(
                          value: hour,
                          child: Text(hour),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedHour = value;
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<String>(
                      value: _selectedMinute,
                      hint: const Text("Minute", style: TextStyle(color: Colors.white)),
                      dropdownColor: Colors.grey[900],
                      style: const TextStyle(color: Colors.white),
                      items: minutes.map((min) {
                        return DropdownMenuItem(
                          value: min,
                          child: Text(min),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMinute = value;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                /// Show selected time
                Text(
                  _selectedHour == null || _selectedMinute == null
                      ? "No time selected"
                      : "Selected: $_selectedHour:$_selectedMinute",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
