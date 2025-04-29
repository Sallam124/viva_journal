import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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

  Media copyWith({
    File? file,
    Offset? position,
    double? size,
    double? angle,
    bool? isVideo,
  }) {
    return Media(
      file: file ?? this.file,
      position: position ?? this.position,
      size: size ?? this.size,
      angle: angle ?? this.angle,
      isVideo: isVideo ?? this.isVideo,
    );
  }
}

class MediaWidget extends StatefulWidget {
  final Media media;
  final bool isSelected;
  final Function(Media) onUpdate;
  final VoidCallback onTap;
  final bool isEditingMode;

  const MediaWidget({
    super.key,
    required this.media,
    required this.isSelected,
    required this.onUpdate,
    required this.onTap,
    required this.isEditingMode,
  });

  @override
  MediaWidgetState createState() => MediaWidgetState();
}

class MediaWidgetState extends State<MediaWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.media.isVideo) {
      _controller = VideoPlayerController.file(widget.media.file)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
          }
        });
    }
  }

  @override
  void dispose() {
    if (widget.media.isVideo) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _togglePlayPause() {
    if (!_isInitialized) return;

    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _controller.play();
      } else {
        _controller.pause();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.media.position.dx,
      top: widget.media.position.dy,
      child: GestureDetector(
        onTap: widget.media.isVideo ? _togglePlayPause : widget.onTap,
        onScaleUpdate: widget.isEditingMode
            ? (details) {
          widget.onUpdate(widget.media.copyWith(
            position: widget.media.position + details.focalPointDelta,
            size: widget.media.size * details.scale,
            angle: widget.media.angle + details.rotation,
          ));
        }
            : null,
        child: Transform.rotate(
          angle: widget.media.angle,
          child: Container(
            width: widget.media.size,
            height: widget.media.size,
            decoration: BoxDecoration(
              border: widget.isSelected
                  ? Border.all(color: Colors.blue, width: 2)
                  : null,
            ),
            child: widget.media.isVideo
                ? _isInitialized
                ? Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
                if (!_isPlaying)
                  const Icon(Icons.play_arrow, size: 50, color: Colors.white),
              ],
            )
                : const Center(child: CircularProgressIndicator())
                : Image.file(
              widget.media.file,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}