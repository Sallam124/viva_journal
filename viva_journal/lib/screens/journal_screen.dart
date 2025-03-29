import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/media.dart';
import 'package:viva_journal/widgets/media.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui' as ui;

class JournalScreen extends StatefulWidget {
  final String mood;
  final List<String> tags;

  const JournalScreen({Key? key, required this.mood, required this.tags}) : super(key: key);

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class Media {
  File file;
  Offset position;
  double size;
  double angle;
  bool isVideo;
  double? _lastRotation;

  Media({
    required this.file,
    this.position = Offset.zero,
    this.size = 1.0,
    this.angle = 0.0,
    this.isVideo = false,
  });
}

class _JournalScreenState extends State<JournalScreen> with SingleTickerProviderStateMixin {
  TextEditingController _textController = TextEditingController();
  List<DrawingPoint> _points = [];
  List<List<DrawingPoint>> _drawingHistory = [];
  List<List<DrawingPoint>> _redoHistory = [];
  List<InteractiveMedia> _attachments = [];
  FlutterSoundRecorder? _recorder;
  String? _voiceNotePath;
  final FlutterTts _flutterTts = FlutterTts();
  bool _isRecording = false;
  bool _showLines = false;
  Color _currentColor = Colors.black;
  int _pencilIndex = 0;
  bool _isEraserActive = false;
  double _strokeWidth = 3.0;
  double _eraserWidth = 30.0;
  FocusNode _textFocusNode = FocusNode();
  bool _isDrawingMode = false;
  late AnimationController _eraserAnimationController;
  late Animation<double> _eraserAnimation;
  InteractiveMedia? _selectedMedia;

  List<Color> _pencilColors = [
    Colors.black,
    Color(0xFFFFE100),
    Color(0xFFFFC917),
    Color(0xFFF8650C),
    Color(0xFFF00000),
    Color(0xFF8C0000)
  ];

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _recorder!.openRecorder();

    _eraserAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _eraserAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(
        parent: _eraserAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    _recorder!.closeRecorder();
    _eraserAnimationController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickMedia(
      requestFullMetadata: false,
    );

    if (pickedFile != null) {
      bool isVideo = pickedFile.mimeType?.startsWith('video/') ?? false;

      setState(() {
        _attachments.add(InteractiveMedia(
          file: File(pickedFile.path),
          isVideo: isVideo,
          position: Offset(100, 100),
          size: 200.0,
          angle: 0.0,
        ));
      });
    }
  }

  Future<void> _startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    _voiceNotePath = '${dir.path}/voice_note.aac';
    await _recorder!.startRecorder(toFile: _voiceNotePath!);
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder!.stopRecorder();
    setState(() {
      _isRecording = false;
    });
  }

  void _speakText() {
    _flutterTts.speak(_textController.text);
  }

  void _undo() {
    if (_drawingHistory.isNotEmpty) {
      setState(() {
        _redoHistory.add(List.from(_points));
        _points = _drawingHistory.removeLast();
      });
    }
  }

  void _redo() {
    if (_redoHistory.isNotEmpty) {
      setState(() {
        _drawingHistory.add(List.from(_points));
        _points = _redoHistory.removeLast();
      });
    }
  }

  void _changePencilColor() {
    setState(() {
      _pencilIndex = (_pencilIndex + 1) % _pencilColors.length;
      _currentColor = _pencilColors[_pencilIndex];
      _isEraserActive = false;
      _eraserAnimationController.reverse();
      _selectedMedia = null;
    });
  }

  void _toggleEraser() {
    setState(() {
      _isEraserActive = !_isEraserActive;
      if (_isEraserActive) {
        _eraserAnimationController.forward();
      } else {
        _eraserAnimationController.reverse();
      }
      _selectedMedia = null;
    });
  }

  void _clearDrawing() {
    setState(() {
      _drawingHistory.add(List.from(_points));
      _points = [];
      _redoHistory.clear();
      _selectedMedia = null;
    });
  }

  void _toggleLines() {
    setState(() {
      _showLines = !_showLines;
    });
  }

  void _toggleDrawingMode() {
    setState(() {
      _isDrawingMode = !_isDrawingMode;
      if (!_isDrawingMode) {
        _textFocusNode.requestFocus();
      } else {
        _textFocusNode.unfocus();
      }
      _selectedMedia = null;
    });
  }

  void _handleDrawingStart(DragStartDetails details) {
    final position = details.localPosition;
    setState(() {
      _drawingHistory.add(List.from(_points));
      _points.add(DrawingPoint(
        position: position,
        color: _isEraserActive ? Colors.white : _currentColor,
        isEraser: _isEraserActive,
        strokeWidth: _isEraserActive ? _eraserWidth : _strokeWidth,
      ));
      _redoHistory.clear();
    });
  }

  void _handleDrawingUpdate(DragUpdateDetails details) {
    final position = details.localPosition;

    setState(() {
      if (_isEraserActive) {
        _points.removeWhere(
              (point) => (point.position - position).distance <= _eraserWidth / 2,
        );
      } else {
        _points.add(DrawingPoint(
          position: position,
          color: _currentColor,
          isEraser: false,
          strokeWidth: _strokeWidth,
        ));
      }
    });
  }

  void _handleDrawingEnd(DragEndDetails details) {
    if (_selectedMedia != null) return;

    setState(() {
      _points.add(DrawingPoint(
        position: Offset.zero,
        color: Colors.transparent,
        isEraser: false,
        strokeWidth: 0,
      ));
    });
  }

  void _handleMediaTap(InteractiveMedia media) {
    setState(() {
      if (_selectedMedia == media) {
        _selectedMedia = null;
      } else {
        _selectedMedia = media;
      }
    });
  }

  void _handleMediaPanUpdate(ScaleUpdateDetails details, Media media) {
    setState(() {
      media.position += details.focalPointDelta;
    });
  }

  void _handleMediaScaleUpdate(ScaleUpdateDetails details, InteractiveMedia media) {
    setState(() {
      double newSize = media.size * details.scale;
      media.size = newSize.clamp(50.0, 500.0);
    });
  }

  void _handleRotateMedia(DragUpdateDetails details) {
    if (_selectedMedia != null) {
      setState(() {
        _selectedMedia!.angle += details.delta.dx * 0.01;
      });
    }
  }

  void _deleteSelectedMedia() {
    if (_selectedMedia != null) {
      setState(() {
        _attachments.remove(_selectedMedia);
        _selectedMedia = null;
      });
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details, InteractiveMedia media) {
    setState(() {
      // Handle movement (panning)
      media.position += details.focalPointDelta;

      // Handle scaling
      media.size = (media.size * details.scale).clamp(50.0, 500.0);

      // Handle rotation with two fingers
      if (details.rotation != 0) {
        // Convert rotation from radians to degrees and snap to 15-degree increments
        double newAngle = (details.rotation * 180 / 3.14159265359) / 15.0;
        newAngle = newAngle.round() * 15.0;
        media.angle = newAngle * 3.14159265359 / 180; // Convert back to radians

      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/trackerlog_screen');
          },
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            icon: Icon(_isDrawingMode ? Icons.text_fields : Icons.edit),
            onPressed: _toggleDrawingMode,
            tooltip: _isDrawingMode ? 'Switch to Text Mode' : 'Switch to Drawing Mode',
          ),
          if (_selectedMedia != null)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteSelectedMedia,
              tooltip: 'Delete Selected Media',
            ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.all(20),
            children: [
              // Text input field
              TextField(
                controller: _textController,
                focusNode: _textFocusNode,
                maxLines: null,
                readOnly: _isDrawingMode,
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Type here...",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),

              // Display Images & Videos in Scrollable View
              Column(
                children: _attachments.map((media) {
                  return GestureDetector(
                    onTap: () => _handleMediaTap(media),
                    onScaleUpdate: (details) => _handleScaleUpdate(details, media),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Transform.rotate(
                        angle: media.angle,
                        child: Transform.scale(
                          scale: media.size / 200.0,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              border: _selectedMedia == media
                                  ? Border.all(color: Colors.blue, width: 2)
                                  : null,
                            ),
                            child: media.isVideo
                                ? VideoWidget(file: media.file)
                                : Image.file(media.file, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Drawing layer above everything
          IgnorePointer(
            ignoring: !_isDrawingMode,
            child: GestureDetector(
              onPanStart: _handleDrawingStart,
              onPanUpdate: _handleDrawingUpdate,
              onPanEnd: _handleDrawingEnd,
              child: CustomPaint(
                painter: _SmoothDrawingPainter(
                  points: _points,
                  showLines: _showLines,
                ),
                child: Container(), // Ensures it covers the whole screen
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isDrawingMode ? _buildDrawingToolbar() : null,
    );
  }


  Widget _buildDrawingToolbar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.undo, color: Colors.white),
            onPressed: _undo,
          ),
          IconButton(
            icon: Icon(Icons.redo, color: Colors.white),
            onPressed: _redo,
          ),
          GestureDetector(
            onTap: _changePencilColor,
            child: Container(
              padding: EdgeInsets.all(5),
              child: Image.asset(
                'assets/images/pencil_${_pencilIndex + 1}.png',
                width: 24,
              ),
            ),
          ),
          GestureDetector(
            onTap: _toggleEraser,
            child: AnimatedBuilder(
              animation: _eraserAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_eraserAnimation.value),
                  child: Image.asset(
                    'assets/images/eraser.png',
                    width: 24,
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: Icon(_isRecording ? Icons.mic_off : Icons.mic, color: Colors.white),
            onPressed: _isRecording ? _stopRecording : _startRecording,
          ),
          IconButton(
            icon: Icon(Icons.image, color: Colors.white),
            onPressed: _pickMedia,
          ),
          IconButton(
            icon: Icon(Icons.grid_on, color: Colors.white),
            onPressed: _toggleLines,
          ),
        ],
      ),
    );
  }
}

class VideoWidget extends StatefulWidget {
  final File file;

  const VideoWidget({Key? key, required this.file}) : super(key: key);

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!_isInitialized) return;

        setState(() {
          _isPlaying = !_isPlaying;
          if (_isPlaying) {
            _controller.play();
          } else {
            _controller.pause();
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isInitialized)
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
          else
            const CircularProgressIndicator(),
          if (!_isPlaying && _isInitialized)
            const Icon(Icons.play_arrow, size: 50, color: Colors.white),
        ],
      ),
    );
  }
}

class InteractiveMedia extends Media {
  InteractiveMedia({
    required File file,
    bool isVideo = false,
    Offset position = Offset.zero,
    double size = 1.0,
    double angle = 0.0,
  }) : super(
    file: file,
    isVideo: isVideo,
    position: position,
    size: size,
    angle: angle,
  );
}

class _SmoothDrawingPainter extends CustomPainter {
  final List<DrawingPoint> points;
  final bool showLines;

  _SmoothDrawingPainter({
    required this.points,
    required this.showLines,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.transparent,
    );

    Paint paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    Paint eraserPaint = Paint()
      ..color = Colors.transparent
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].position == Offset.zero || points[i + 1].position == Offset.zero) {
        continue;
      }

      if (points[i].isEraser) {
        eraserPaint.strokeWidth = points[i].strokeWidth;
        canvas.drawLine(points[i].position, points[i + 1].position, eraserPaint);
      } else {
        paint.color = points[i].color;
        paint.strokeWidth = points[i].strokeWidth;
        canvas.drawLine(points[i].position, points[i + 1].position, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class DrawingPoint {
  final Offset position;
  final Color color;
  final bool isEraser;
  final double strokeWidth;

  DrawingPoint({
    required this.position,
    required this.color,
    required this.isEraser,
    required this.strokeWidth,
  });
}