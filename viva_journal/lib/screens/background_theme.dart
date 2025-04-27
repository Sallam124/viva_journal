import 'dart:ui';
import 'package:flutter/material.dart';

class BackgroundContainer extends StatefulWidget {
  final Widget child;
  const BackgroundContainer({super.key, required this.child});

  @override
  _BackgroundContainerState createState() => _BackgroundContainerState();
}

class _BackgroundContainerState extends State<BackgroundContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20), // 360° rotation in 20 sec
    )..repeat(); // Loop animation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // White Background
          Positioned.fill(
            child: Container(color: Colors.white),
          ),
          // Rotating and Blurred Star (BIGGER WITHOUT CROPPING)
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * 2 * 3.1416, // Full rotation
                  child: OverflowBox(
                    maxWidth: double.infinity,
                    maxHeight: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.scale(
                          scale: 2.5, // Enlarges the star without cropping
                          child: Image.asset(
                            'assets/images/Rotate_Star.png',
                            width: 500, // Original size
                            height: 500,
                          ),
                        ),
                        Positioned.fill(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 1500, sigmaY: 1500), // Blur effect
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Centered Child Content
          Align(
            alignment: Alignment.center,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
