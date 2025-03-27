import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

class JournalScreen extends StatefulWidget {
  final String mood;
  final List<String> tags;

  const JournalScreen({Key? key, required this.mood, required this.tags}) : super(key: key);

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> with SingleTickerProviderStateMixin {
  // State variables and controllers
  TextEditingController _textController = TextEditingController();
  List<DrawingPoint> _points = [];
  List<List<DrawingPoint>> _drawingHistory = [];
  List<List<DrawingPoint>> _redoHistory = [];
  List<File> _attachments = [];
  FlutterSoundRecorder? _recorder;
  String? _voiceNotePath;
  final FlutterTts _flutterTts = FlutterTts();
  bool _isRecording = false;
  bool _showLines = false;
  Color _currentColor = Colors.black;
  int _pencilIndex = 0;
  bool _isEraserActive = false;
  double _strokeWidth = 3.0;
  FocusNode _textFocusNode = FocusNode();
  bool _isDrawingMode = false;
  late AnimationController _eraserAnimationController;
  late Animation<double> _eraserAnimation;

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

    // Eraser animation controller
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

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _attachments.add(File(pickedFile.path));
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
    });
  }

  void _clearDrawing() {
    setState(() {
      _drawingHistory.add(List.from(_points));
      _points = [];
      _redoHistory.clear();
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
    });
  }

  void _handleDrawingStart(DragStartDetails details) {
    final position = details.localPosition;
    setState(() {
      _drawingHistory.add(List.from(_points));
      if (_isEraserActive) {
        // Erase nearby points
        final eraseRadius = 20.0;
        _points = _points.where((point) {
          return (point.position - position).distance > eraseRadius;
        }).toList();
      } else {
        // Add new drawing point
        _points.add(DrawingPoint(
          position: position,
          color: _currentColor,
          isEraser: false,
          strokeWidth: _strokeWidth,
        ));
      }
      _redoHistory.clear();
    });
  }

  void _handleDrawingUpdate(DragUpdateDetails details) {
    final position = details.localPosition;
    setState(() {
      if (_isEraserActive) {
        // Continue erasing
        final eraseRadius = 20.0;
        _points = _points.where((point) {
          return (point.position - position).distance > eraseRadius;
        }).toList();
      } else {
        // Continue drawing
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
    setState(() {
      _points.add(DrawingPoint(
        position: Offset.zero,
        color: Colors.transparent,
        isEraser: false,
        strokeWidth: 0,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Journal Editor'),
        actions: [
          IconButton(
            icon: Icon(_isDrawingMode ? Icons.text_fields : Icons.edit),
            onPressed: _toggleDrawingMode,
            tooltip: _isDrawingMode ? 'Switch to Text Mode' : 'Switch to Drawing Mode',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Text editor (always visible)
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: TextField(
                controller: _textController,
                focusNode: _textFocusNode,
                maxLines: null,
                readOnly: _isDrawingMode, // Disable text input when in drawing mode
                decoration: InputDecoration(
                  hintText: "Type here...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // Drawing canvas (always visible but only interactive in drawing mode)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_isDrawingMode, // Only allow interaction in drawing mode
              child: GestureDetector(
                onPanStart: _handleDrawingStart,
                onPanUpdate: _handleDrawingUpdate,
                onPanEnd: _handleDrawingEnd,
                child: CustomPaint(
                  painter: DrawingPainter(_points, _showLines),
                  child: Container(),
                ),
              ),
            ),
          ),

          // Attachments
          ..._attachments.map((attachment) => Positioned(
            left: 50,
            top: 50,
            child: Image.file(attachment, width: 100, height: 100),
          )).toList(),
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
                    color: Colors.white,
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
            onPressed: _pickImage,
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

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint> points;
  final bool showLines;

  DrawingPainter(this.points, this.showLines);

  @override
  void paint(Canvas canvas, Size size) {
    if (showLines) {
      Paint gridPaint = Paint()
        ..color = Colors.grey.withOpacity(0.3)
        ..strokeWidth = 0.5;

      for (double i = 0; i < size.width; i += 20) {
        canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
      }
      for (double i = 0; i < size.height; i += 20) {
        canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
      }
    }

    Paint paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].position != Offset.zero && points[i + 1].position != Offset.zero) {
        paint
          ..color = points[i].color
          ..strokeWidth = points[i].strokeWidth;

        canvas.drawLine(points[i].position, points[i + 1].position, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.showLines != showLines;
}