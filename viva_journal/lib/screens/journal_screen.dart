import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../widgets/media.dart';
import 'package:viva_journal/widgets/media.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui' as ui;
import 'dart:math';

class JournalScreen extends StatefulWidget {
  final String mood;
  final List<String> tags;
  final DateTime date;

  const JournalScreen({
    Key? key,
    required this.mood,
    required this.tags,
    required this.date,
  }) : super(key: key);

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

class _JournalScreenState extends State<JournalScreen> with TickerProviderStateMixin {
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
  AnimationController? _eraserAnimationController;
  Animation<double>? _eraserAnimation;
  InteractiveMedia? _selectedMedia;
  bool _isRainbowMode = true;
  double _rainbowOffset = 0.0;
  AnimationController? _pencilAnimationController;
  Animation<double>? _pencilAnimation;
  bool _isPencilActive = false;

  List<Color> _pencilColors = [
    Colors.black,  // Standard black pencil
    Color(0xFFFFE100),  // Original yellow
    Color(0xFFFFC917),  // Original yellow-orange
    Color(0xFFF8650C),  // Original orange
    Color(0xFFF00000),  // Original red
    Color(0xFF8C0000),  // Original dark red
  ];

  void _initializeAnimations() {
    _eraserAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _eraserAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(
        parent: _eraserAnimationController!,
        curve: Curves.easeInOut,
      ),
    );

    _pencilAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _pencilAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(
        parent: _pencilAnimationController!,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _recorder!.openRecorder();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    _recorder!.closeRecorder();
    _eraserAnimationController?.dispose();
    _pencilAnimationController?.dispose();
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

  Color _getRainbowColor(Offset position) {
    final List<Color> rainbowColors = [
      Color(0xFFFFE100),  // Yellow
      Color(0xFFFFC917),  // Yellow-orange
      Color(0xFFF8650C),  // Orange
      Color(0xFFF00000),  // Red
      Color(0xFF8C0000),  // Dark red
    ];

    final double time = DateTime.now().millisecondsSinceEpoch / 500.0;
    final double x = position.dx / 50.0;
    final double y = position.dy / 50.0;

    final double pattern = (sin(x + time) + cos(y + time) + sin(x * y + time)) / 3.0;
    final double normalizedPattern = (pattern + 1) / 2;
    final int colorIndex = (normalizedPattern * (rainbowColors.length - 1)).floor();
    final double t = (normalizedPattern * (rainbowColors.length - 1)) - colorIndex;

    if (colorIndex >= rainbowColors.length - 1) {
      return rainbowColors.last;
    }

    return Color.lerp(rainbowColors[colorIndex], rainbowColors[colorIndex + 1], t) ?? rainbowColors[0];
  }

  void _changePencilColor() {
    setState(() {
      _pencilIndex = (_pencilIndex + 1) % _pencilColors.length;
      _currentColor = _pencilColors[_pencilIndex];
      _isEraserActive = false;
      _isRainbowMode = _pencilIndex == 0;
      _eraserAnimationController?.reverse();
      _pencilAnimationController?.forward();
      _selectedMedia = null;
    });
  }

  void _togglePencil() {
    setState(() {
      _isPencilActive = !_isPencilActive;
      if (_isPencilActive) {
        _pencilAnimationController?.forward();
        _eraserAnimationController?.reverse();
        _isEraserActive = false;
      } else {
        _pencilAnimationController?.reverse();
      }
      _selectedMedia = null;
    });
  }

  void _toggleEraser() {
    setState(() {
      _isEraserActive = !_isEraserActive;
      if (_isEraserActive) {
        _eraserAnimationController?.forward();
        _pencilAnimationController?.reverse();
        _isPencilActive = false;
      } else {
        _eraserAnimationController?.reverse();
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
        _selectedMedia = null;
      }
    });
  }

  void _handleDrawingStart(DragStartDetails details) {
    if (!_isPencilActive && !_isEraserActive) return;

    final position = details.localPosition;
    setState(() {
      _drawingHistory.add(List.from(_points));
      _points.add(DrawingPoint(
        position: position,
        color: _isEraserActive ? Colors.white : (_isRainbowMode ? _getRainbowColor(position) : _currentColor),
        isEraser: _isEraserActive,
        strokeWidth: _isEraserActive ? _eraserWidth : _strokeWidth,
        isRainbow: _isRainbowMode,
      ));
      _redoHistory.clear();
    });
  }

  void _handleDrawingUpdate(DragUpdateDetails details) {
    final position = details.localPosition;

    setState(() {
      if (_isEraserActive) {
        List<DrawingPoint> pointsToKeep = [];
        List<DrawingPoint> currentStroke = [];

        for (int i = 0; i < _points.length; i++) {
          if (_points[i].position == Offset.zero) {
            bool strokeIntersects = false;
            for (var point in currentStroke) {
              if ((point.position - position).distance <= _eraserWidth / 2) {
                strokeIntersects = true;
                break;
              }
            }

            if (!strokeIntersects) {
              pointsToKeep.addAll(currentStroke);
              pointsToKeep.add(_points[i]);
            }
            currentStroke = [];
          } else {
            currentStroke.add(_points[i]);
          }
        }

        if (currentStroke.isNotEmpty) {
          bool strokeIntersects = false;
          for (var point in currentStroke) {
            if ((point.position - position).distance <= _eraserWidth / 2) {
              strokeIntersects = true;
              break;
            }
          }
          if (!strokeIntersects) {
            pointsToKeep.addAll(currentStroke);
          }
        }

        _points = pointsToKeep;
      } else {
        _points.add(DrawingPoint(
          position: position,
          color: _isRainbowMode ? _getRainbowColor(position) : _currentColor,
          isEraser: false,
          strokeWidth: _strokeWidth,
          isRainbow: _isRainbowMode,
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

  void _deleteSelectedMedia() {
    if (_selectedMedia != null) {
      setState(() {
        _attachments.remove(_selectedMedia);
        _selectedMedia = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/trackerlog_screen'),
        ),
        title: Text(
          DateFormat("d MMM, yy | E").format(widget.date),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          IconButton(
            icon: Icon(_isDrawingMode ? Icons.text_fields : Icons.edit),
            onPressed: _toggleDrawingMode,
          ),
          if (_selectedMedia != null)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteSelectedMedia,
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(20),
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height - 100, // Full height minus padding and app bar
                      child: Stack(
                        children: [
                          // Text field that covers the whole area
                          Container(
                            height: double.infinity,
                            child: TextField(
                              controller: _textController,
                              focusNode: _textFocusNode,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              readOnly: _isDrawingMode,
                              decoration: InputDecoration(
                                hintText: "Type here...",
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(0),
                              ),
                            ),
                          ),

                          // Drawing overlay (always visible)
                          Positioned.fill(
                            child: GestureDetector(
                              onPanStart: _isDrawingMode ? (details) {
                                if (_isPencilActive || _isEraserActive) {
                                  _handleDrawingStart(details);
                                }
                              } : null,
                              onPanUpdate: _isDrawingMode ? (details) {
                                if (_isPencilActive || _isEraserActive) {
                                  _handleDrawingUpdate(details);
                                }
                              } : null,
                              onPanEnd: _isDrawingMode ? (details) {
                                if (_isPencilActive || _isEraserActive) {
                                  _handleDrawingEnd(details);
                                }
                              } : null,
                              child: CustomPaint(
                                painter: _SmoothDrawingPainter(
                                  points: _points,
                                  showLines: _showLines,
                                ),
                                child: Container(color: Colors.transparent),
                              ),
                            ),
                          ),

                          // Media attachments
                          ..._attachments.map((media) => MediaWidget(
                            media: media,
                            isSelected: _selectedMedia == media,
                            onTap: () => _handleMediaTap(media),
                            onUpdate: (updatedMedia) {
                              setState(() {
                                final index = _attachments.indexOf(media);
                                if (index != -1) {
                                  _attachments[index] = updatedMedia;
                                  if (_selectedMedia == media) {
                                    _selectedMedia = updatedMedia;
                                  }
                                }
                              });
                            },
                            isEditingMode: !_isDrawingMode,
                          )).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Drawing toolbar fixed at bottom
          if (_isDrawingMode)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildDrawingToolbar(),
            ),
        ],
      ),
    );
  }

  Widget _buildDrawingToolbar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = MediaQuery.of(context).size.width;
        double toolbarHeight = screenWidth * 0.2;

        return Container(
          width: screenWidth,
          height: toolbarHeight,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/StarBar.png'),
              fit: BoxFit.fill,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.undo,
                    color: _drawingHistory.isEmpty ? Colors.grey : Colors.white,
                    size: toolbarHeight * 0.3,
                  ),
                  onPressed: _drawingHistory.isEmpty ? null : _undo,
                ),
                IconButton(
                  icon: Icon(
                    Icons.redo,
                    color: _redoHistory.isEmpty ? Colors.grey : Colors.white,
                    size: toolbarHeight * 0.3,
                  ),
                  onPressed: _redoHistory.isEmpty ? null : _redo,
                ),
                GestureDetector(
                  onTap: _togglePencil,
                  onDoubleTap: _changePencilColor,
                  child: _pencilAnimation != null
                      ? AnimatedBuilder(
                    animation: _pencilAnimation!,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_pencilAnimation!.value),
                        child: Container(
                          padding: EdgeInsets.all(toolbarHeight * 0.05),
                          decoration: BoxDecoration(
                            color: _isPencilActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.asset(
                            'assets/images/pencil_${_pencilIndex + 1}.png',
                            width: toolbarHeight * 0.4,
                          ),
                        ),
                      );
                    },
                  )
                      : Container(
                    padding: EdgeInsets.all(toolbarHeight * 0.05),
                    decoration: BoxDecoration(
                      color: _isPencilActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      'assets/images/pencil_${_pencilIndex + 1}.png',
                      width: toolbarHeight * 0.4,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _toggleEraser,
                  child: _eraserAnimation != null
                      ? AnimatedBuilder(
                    animation: _eraserAnimation!,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_eraserAnimation!.value),
                        child: Container(
                          padding: EdgeInsets.all(toolbarHeight * 0.05),
                          decoration: BoxDecoration(
                            color: _isEraserActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.asset(
                            'assets/images/eraser.png',
                            width: toolbarHeight * 0.4,
                          ),
                        ),
                      );
                    },
                  )
                      : Container(
                    padding: EdgeInsets.all(toolbarHeight * 0.05),
                    decoration: BoxDecoration(
                      color: _isEraserActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      'assets/images/eraser.png',
                      width: toolbarHeight * 0.4,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isRecording ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                    size: toolbarHeight * 0.3,
                  ),
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                ),
                IconButton(
                  icon: Icon(
                    Icons.image,
                    color: Colors.white,
                    size: toolbarHeight * 0.3,
                  ),
                  onPressed: _pickMedia,
                ),
                IconButton(
                  icon: Icon(
                    Icons.grid_on,
                    color: Colors.white,
                    size: toolbarHeight * 0.3,
                  ),
                  onPressed: _toggleLines,
                ),
              ],
            ),
          ),
        );
      },
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
  Offset position;
  final Color color;
  final bool isEraser;
  final double strokeWidth;
  final bool isRainbow;

  DrawingPoint({
    required this.position,
    required this.color,
    required this.isEraser,
    required this.strokeWidth,
    this.isRainbow = false,
  });
}

class MediaWidget extends StatefulWidget {
  final InteractiveMedia media;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(InteractiveMedia) onUpdate;
  final bool isEditingMode;

  const MediaWidget({
    required this.media,
    required this.isSelected,
    required this.onTap,
    required this.onUpdate,
    required this.isEditingMode,
    Key? key,
  }) : super(key: key);

  @override
  _MediaWidgetState createState() => _MediaWidgetState();
}

class _MediaWidgetState extends State<MediaWidget> {
  bool _isInEditMode = false;
  double _initialAngle = 0;
  double _initialScale = 1.0;
  Offset _initialPosition = Offset.zero;
  Offset _dragStartPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.media.position.dx,
      top: widget.media.position.dy,
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: () {
          setState(() {
            _isInEditMode = !_isInEditMode;
          });
        },
        onScaleStart: _isInEditMode
            ? (details) {
          _initialAngle = widget.media.angle;
          _initialScale = widget.media.size / 200.0;
          _initialPosition = widget.media.position;
          _dragStartPosition = details.focalPoint;
        }
            : null,
        onScaleUpdate: _isInEditMode
            ? (details) {
          final offsetDelta = details.focalPoint - _dragStartPosition;
          final newPosition = _initialPosition + offsetDelta;

          final newAngle = _initialAngle + details.rotation;
          final newScale = (_initialScale * details.scale).clamp(0.25, 4.0);

          widget.onUpdate(InteractiveMedia(
            file: widget.media.file,
            isVideo: widget.media.isVideo,
            position: newPosition,
            size: newScale * 200.0,
            angle: newAngle,
          ));
        }
            : null,
        child: Transform.rotate(
          angle: widget.media.angle,
          child: Transform.scale(
            scale: widget.media.size / 200.0,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: widget.isSelected || _isInEditMode
                    ? Border.all(
                    color: _isInEditMode ? Colors.green : Colors.blue,
                    width: 2)
                    : null,
              ),
              child: widget.media.isVideo
                  ? VideoWidget(file: widget.media.file)
                  : Image.file(widget.media.file, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}