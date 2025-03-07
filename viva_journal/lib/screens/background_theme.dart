import 'dart:ui';
import 'package:flutter/material.dart';

class BackgroundWidget extends StatelessWidget {
  const BackgroundWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.yellow.shade200,
                Colors.orange.shade400,
                Colors.red.shade700,
                Colors.brown.shade900,
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: <Color>[
                Colors.white.withAlpha(0), // Fully transparent white
                Colors.white.withAlpha(80), // 20% opacity white
              ],
              stops: [0.6, 1.0], // Defines where the fading effect starts
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.05)),
          ),
        ),
      ],
    );
  }
}
