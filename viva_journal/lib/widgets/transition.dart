import 'package:flutter/material.dart';

// Custom Fade Transition class
class FadePageTransition extends PageRouteBuilder {
  final Widget page;

  FadePageTransition({required this.page})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) {
      return page;
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(animation);
      return FadeTransition(opacity: fadeAnimation, child: child);
    },
  );
}
