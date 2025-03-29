import 'dart:io';
import 'package:flutter/material.dart';

class Media {
  File file;
  Offset position;
  double size;
  double angle;
  bool isVideo;

  Media({
    required this.file,
    this.position = Offset.zero,
    this.size = 1.0,
    this.angle = 0.0,
    this.isVideo = false,
  });
}