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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _glowController;
  late AnimationController _splashController;
  late Animation<double> _glowAnimation;
  late Animation<double> _splashAnimation;
  late double homeBarHeight;
  bool _isSplashAnimating = false;
  Offset? _splashPosition;

  final List<Color> _glowColors = [
    const Color(0xFFFFE100), // Yellow
    const Color(0xFFFFC917), // Light Orange
    const Color(0xFFF8650C), // Orange
    const Color(0xFFF00000), // Red
    const Color(0xFF8C0000), // Dark Red
  ];

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
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 3000), // Slower animation for smoother flow
      vsync: this,
    );

    _splashController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );

    _splashAnimation = CurvedAnimation(
      parent: _splashController,
      curve: Curves.easeInOut,
    );

    _glowController.repeat();

    _splashController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSplashAnimating = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TrackerLogScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _splashController.dispose();
    super.dispose();
  }

  /// Handles navigation bar item selection.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Triggers animation and navigates to the tracker log screen.
  void _onFloatingButtonPressed(TapDownDetails details) {
    setState(() {
      _isSplashAnimating = true;
      _splashPosition = details.globalPosition;
      _splashController.forward(from: 0);
    });
  }

  Color _getGlowColor(double value) {
    final colorCount = _glowColors.length;
    final position = (value * colorCount).floor();
    final nextPosition = (position + 1) % colorCount;
    final progress = (value * colorCount) - position;

    return Color.lerp(
      _glowColors[position],
      _glowColors[nextPosition],
      progress,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Calculate responsive dimensions
    homeBarHeight = screenWidth * 0.2;  // Slightly smaller for better proportions
    double floatingButtonSize = screenWidth * 0.20;  // Proportional to screen width
    double horizontalPadding = screenWidth * 0.05;
    double floatingButtonBottomPadding = homeBarHeight * 0.4;
    double bottomPadding = screenHeight * 0.01;

    // Calculate icon sizes based on screen width
    double iconSize = screenWidth * 0.07;  // Responsive icon size
    double starSize = screenWidth * 0.04;  // Responsive star indicator size
    double iconTopPadding = homeBarHeight * 0.2;  // Proportional top padding

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          _pages[_selectedIndex],

          if (_isSplashAnimating && _splashPosition != null)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _splashAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: SplashPainter(
                      position: _splashPosition!,
                      progress: _splashAnimation.value,
                      color: _getGlowColor(_glowController.value),
                    ),
                  );
                },
              ),
            ),

          // Bottom Navigation Bar
          Positioned(
            bottom: bottomPadding,
            left: horizontalPadding,
            right: horizontalPadding,
            child: Container(
              height: homeBarHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(screenWidth * 0.05),  // Responsive border radius
                image: DecorationImage(
                  image: AssetImage('assets/images/HomeBarBG.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: homeBarHeight * 0.1
                ),
                child: Row(
                  children: [
                    _buildNavItem(Icons.home, 0, iconSize, starSize, iconTopPadding),
                    const Spacer(),
                    _buildNavItem(Icons.calendar_today, 1, iconSize, starSize, iconTopPadding),
                    const Spacer(flex: 4),
                    _buildNavItem(Icons.bar_chart, 2, iconSize, starSize, iconTopPadding),
                    const Spacer(),
                    _buildNavItem(Icons.settings, 3, iconSize, starSize, iconTopPadding),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: floatingButtonBottomPadding),
        child: _buildFloatingButton(floatingButtonSize),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// Builds navigation bar items with responsive sizes
  Widget _buildNavItem(IconData icon, int index, double iconSize, double starSize, double topPadding) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        height: homeBarHeight * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: Icon(
                icon,
                size: iconSize,
                color: _selectedIndex == index ? Colors.white : const Color(0xFF3C3C3C),
              ),
            ),
            if (_selectedIndex == index)
              Padding(
                padding: EdgeInsets.only(top: homeBarHeight * 0.02),
                child: Image.asset(
                  'assets/images/HBstar.png',
                  width: starSize,
                  height: starSize,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButton(double size) {
    return GestureDetector(
      onTapDown: _onFloatingButtonPressed,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          final glowColor = _getGlowColor(_glowController.value);

          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  glowColor.withAlpha(76),
                  glowColor.withAlpha(153),
                  glowColor.withAlpha(255),
                  glowColor.withAlpha(153),
                  glowColor.withAlpha(76),
                ],
                stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                transform: GradientRotation(_glowController.value * 2 * 3.14159),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(size * 0.05),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withAlpha(153),
                      blurRadius: size * 0.25,  // Responsive blur
                      spreadRadius: size * 0.04,  // Responsive spread
                    ),
                    BoxShadow(
                      color: glowColor.withAlpha(102),
                      blurRadius: size * 0.3,  // Responsive blur
                      spreadRadius: size * 0.06,  // Responsive spread
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/float_button.png',
                    width: size * 0.7,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SplashPainter extends CustomPainter {
  final Offset position;
  final double progress;
  final Color color;

  SplashPainter({
    required this.position,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final radius = size.width * 2 * progress;
    canvas.drawCircle(position, radius, paint);
  }

  @override
  bool shouldRepaint(SplashPainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.progress != progress;
  }
}
