import 'package:flutter/material.dart';
<<<<<<< Updated upstream
=======
import 'package:viva_journal/screens/settings_screen.dart';
import 'package:viva_journal/screens/dashboard_screen.dart';
import 'package:viva_journal/screens/calendar_screen.dart';
import 'package:viva_journal/screens/trackerlog_screen.dart'; // Tracker log screen import
import 'package:viva_journal/database/database.dart'; // Import the DatabaseHelper

/// Home screen with a bottom navigation bar and a floating action button.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _controller;

  /// List of screens corresponding to navigation items.
  final List<Widget> _pages = [
    Center(child: Text('Welcome to Home!', style: TextStyle(color: Colors.black, fontSize: 24))),
    const CalendarScreen(),
    const DashboardScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600), // Floating button animation duration
      vsync: this,
    );

    // Test the database insert and retrieve functionality
    testDatabase();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Handles navigation bar item selection.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Triggers animation and navigates to the tracker log screen.
  void _onFloatingButtonPressed() {
    _controller.forward(from: 0).then((_) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TrackerLogScreen()),
      );
    });
  }
>>>>>>> Stashed changes

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: Text('Welcome to the Home Screen!'),
      ),
    );
  }

  /// Test function to insert and retrieve a mood entry from the database
  void testDatabase() async {
    final dbHelper = DatabaseHelper();

    // Create a new mood entry
    final moodEntry = MoodEntry(
      mood: 'Happy',
      date: '08-04-2025',
      input: 'Feeling great today!',
    );

    // Insert the new entry into the database
    final id = await dbHelper.insertMood(moodEntry);
    print('Inserted mood entry with ID: $id');

    // Retrieve the mood entry by date
    final retrievedMoodEntry = await dbHelper.getMoodForDay('08-04-2025');
    if (retrievedMoodEntry != null) {
      print('Mood for 08-04-2025: ${retrievedMoodEntry.mood}');
    } else {
      print('No mood entry found for 08-04-2025');
    }
  }
}
