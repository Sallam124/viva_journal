import 'package:flutter/material.dart';
import 'package:viva_journal/screens/trackerlog_screen.dart';

class HomeBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const HomeBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  _HomeBarState createState() => _HomeBarState();
}

class _HomeBarState extends State<HomeBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  late double homeBarHeight;

  final List<Color> _glowColors = [
    const Color(0xFFFFE100), // Yellow
    const Color(0xFFFFC917), // Light Orange
    const Color(0xFFF8650C), // Orange
    const Color(0xFFF00000), // Red
    const Color(0xFF8C0000), // Dark Red
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _glowAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  void _onFloatingButtonPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TrackerLogScreen()),
    );
  }

  Widget _buildFloatingButton(double size) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final glowColor = _getGlowColor(_controller.value);

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
              transform: GradientRotation(_controller.value * 2 * 3.14159),
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
                    blurRadius: 25,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: glowColor.withAlpha(102),
                    blurRadius: 30,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Center(
                child: FloatingActionButton(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  onPressed: _onFloatingButtonPressed,
                  child: Image.asset(
                    'assets/images/float_button.png',
                    width: size * 0.7,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    return GestureDetector(
      onTap: () => widget.onItemTapped(index),
      child: Container(
        height: homeBarHeight * 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Icon(
                icon,
                size: 30,
                color: widget.selectedIndex == index ? Colors.white : const Color(0xFF3C3C3C),
              ),
            ),
            if (widget.selectedIndex == index)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Image.asset(
                  'assets/images/HBstar.png',
                  width: 16,
                  height: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    homeBarHeight = screenWidth * 0.25;
    double floatingButtonSize = homeBarHeight * 0.8;
    double horizontalPadding = screenWidth * 0.05;
    double floatingButtonBottomPadding = homeBarHeight * 0.4;
    double bottomPadding = screenHeight * 0.015;

    return Stack(
      children: [
        Positioned(
          bottom: bottomPadding,
          left: horizontalPadding,
          right: horizontalPadding,
          child: Container(
            height: homeBarHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: AssetImage('assets/images/HomeBarBG.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
              child: Row(
                children: [
                  _buildNavItem(Icons.home, 0),
                  const Spacer(),
                  _buildNavItem(Icons.calendar_today, 1),
                  const Spacer(flex: 4),
                  _buildNavItem(Icons.bar_chart, 2),
                  const Spacer(),
                  _buildNavItem(Icons.settings, 3),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: floatingButtonBottomPadding,
          left: 0,
          right: 0,
          child: Center(
            child: _buildFloatingButton(floatingButtonSize),
          ),
        ),
      ],
    );
  }
}
