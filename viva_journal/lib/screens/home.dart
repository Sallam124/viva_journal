import 'package:flutter/material.dart';
import 'package:viva_journal/screens/settings_screen.dart';
import 'package:viva_journal/screens/dashboard_screen.dart';
import 'package:viva_journal/screens/calendar_screen.dart';
import 'package:viva_journal/screens/trackerlog_screen.dart';
import 'package:viva_journal/widgets/mini_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Home screen with a bottom navigation bar and a floating action button.
class HomeScreen extends StatefulWidget {
  final int initialIndex;  // Add initialIndex parameter
  const HomeScreen({super.key, this.initialIndex = 0});  // Default to 0 if not provided

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _glowController;
  late AnimationController _splashController;
  late Animation<double> _glowAnimation;
  late Animation<double> _splashAnimation;
  late double homeBarHeight;
  bool _isSplashAnimating = false;
  Offset? _splashPosition;
  double _homeBarOpacity = 1.0;  // Add opacity control
  double _floatingButtonOpacity = 1.0;  // Add opacity control
  String? _username;
  String? _profilePictureUrl;  // Add profile picture URL
  bool _hasNotifications = false;  // Add notification state

  final List<Color> _glowColors = [
    const Color(0xFFFFE100), // Yellow
    const Color(0xFFFFC917), // Light Orange
    const Color(0xFFF8650C), // Orange
    const Color(0xFFF00000), // Red
    const Color(0xFF8C0000), // Dark Red
  ];

  /// Method to get time-based greeting
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  /// Method to fetch username and profile picture from Firestore
  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _username = doc.data()?['username'] as String?;
          _profilePictureUrl = doc.data()?['profilePicture'] as String?;
          _hasNotifications = doc.data()?['hasNotifications'] as bool? ?? false;
        });
      }
    }
  }

  /// Method to build home content
  Widget _buildHomeContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),  // Space for status bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: _profilePictureUrl != null
                            ? NetworkImage(_profilePictureUrl!)
                            : const AssetImage('assets/images/pfp.png') as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                      if (_username != null) ...[
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Text(
                              _username!,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                            const Text(
                              ' ✨',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  // Handle notification tap
                  setState(() {
                    _hasNotifications = false;
                  });
                  // TODO: Navigate to notifications screen
                },
                child: Stack(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: 28,
                      color: Colors.black,
                    ),
                    if (_hasNotifications)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MiniCalendar(key: const ValueKey('mini_calendar')),
          const SizedBox(height: 32), // Increased space between calendar and blocks
          // Blocks Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: _buildBigBlock(
                  title: "Streak",
                  color: Color(0xFFF8650C), // Orange-ish
                  leftImage: Image.asset(
                    'assets/images/streak.gif', // Place your gif in assets/images and update pubspec.yaml
                    width: 80,
                    height: 80,
                  ),
                  onTap: () {
                    // TODO: Handle Streak block tap
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildSmallBlock(
                      title: "On this same day",
                      color: Colors.white,
                      iconPath: 'assets/images/your_calendar_icon.png', // Change accordingly
                      onTap: () {
                        // TODO: Handle On this same day tap
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSmallBlock(
                      title: "Average mood",
                      color: Color(0xFF8C0000), // Dark red
                      iconPath: 'assets/images/your_mood_icon.png', // Change accordingly
                      onTap: () {
                        // TODO: Handle Average mood tap
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _fetchUserData();  // Changed from _fetchUsername to _fetchUserData

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
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
        // Delay the navigation slightly to ensure smooth transition
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => TrackerLogScreen(date: DateTime.now()),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            ).then((_) {
              if (mounted) {
                setState(() {
                  _isSplashAnimating = false;
                  _homeBarOpacity = 1.0;
                  _floatingButtonOpacity = 1.0;
                });
              }
            });
          }
        });
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
      _homeBarOpacity = 0.0;  // Start fade out
      _floatingButtonOpacity = 0.0;  // Start fade out
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
          _selectedIndex == 0 ? _buildHomeContent() :
          _selectedIndex == 1 ? CalendarScreen() :
          _selectedIndex == 2 ? DashboardScreen() :
          const SettingsScreen(),

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
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _homeBarOpacity,
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
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: floatingButtonBottomPadding),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _floatingButtonOpacity,
          child: _buildFloatingButton(floatingButtonSize),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// Builds navigation bar items with responsive sizes
  Widget _buildNavItem(IconData icon, int index, double iconSize, double starSize, double topPadding) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: SizedBox(
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

  // Helper widget for big block
  Widget _buildBigBlock({
    required String title,
    required Color color,
    Widget? leftImage, // New optional parameter for left-aligned image/gif
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            if (leftImage != null)
              Positioned(
                left: 16,
                top: 32,
                bottom: 32,
                child: SizedBox(
                  width: 80,
                  child: leftImage,
                ),
              ),
            Positioned(
              top: 16,
              left: leftImage != null ? 110 : 16, // Move title right if image present
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Icon(Icons.open_in_new, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for small block
  Widget _buildSmallBlock({
    required String title,
    required Color color,
    required String iconPath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: color == Colors.white ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.open_in_new,
                size: 16,
                color: color == Colors.white ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
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
