import 'package:flutter/material.dart';
import 'package:viva_journal/screens/settings_screen.dart';
import 'package:viva_journal/screens/dashboard_screen.dart';
import 'package:viva_journal/screens/calendar_screen.dart';
import 'package:viva_journal/screens/trackerlog_screen.dart'; // Tracker log screen import

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
     CalendarScreen(),
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double homeBarHeight = screenWidth * 0.25;
    double floatingButtonSize = homeBarHeight * 0.8;

    return Stack(
      children: [
        Positioned.fill(child: _pages[_selectedIndex]), // Displays the selected page

        // Bottom Navigation Bar Background Image
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Image.asset(
            'assets/images/HomeBarBG.png',
            fit: BoxFit.cover,
            height: homeBarHeight,
          ),
        ),

        // Scaffold with Bottom Navigation and Floating Action Button
        Scaffold(
          backgroundColor: Colors.transparent,
          bottomNavigationBar: BottomAppBar(
            color: Colors.transparent,
            shape: const CircularNotchedRectangle(),
            notchMargin: 10,
            child: SizedBox(
              height: homeBarHeight * 0.9,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildNavItem(Icons.home, 0),
                      SizedBox(width: homeBarHeight * 0.4),
                      _buildNavItem(Icons.calendar_today, 1),
                    ],
                  ),
                  SizedBox(width: homeBarHeight * 0.5),
                  Row(
                    children: [
                      _buildNavItem(Icons.bar_chart, 2),
                      SizedBox(width: homeBarHeight * 0.4),
                      _buildNavItem(Icons.settings, 3),
                    ],
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: SizedBox(
            width: floatingButtonSize,
            height: floatingButtonSize,
            child: FloatingActionButton(
              backgroundColor: Colors.transparent,
              elevation: 0,
              onPressed: _onFloatingButtonPressed,
              child: RotationTransition(
                turns: _controller,
                child: Image.asset('assets/images/float_button.png', width: floatingButtonSize),
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        ),
      ],
    );
  }

  /// Builds navigation bar items with an icon and optional highlight.
  Widget _buildNavItem(IconData icon, int index) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 32,
            color: _selectedIndex == index ? Colors.white : const Color(0xFF3C3C3C),
          ),
          if (_selectedIndex == index)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Image.asset(
                'assets/images/HBstar.png',
                width: 18,
                height: 18,
              ),
            ),
        ],
      ),
    );
  }
}