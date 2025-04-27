import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/media.dart';
import 'package:video_player/video_player.dart';
import 'dart:math';

class JournalScreen extends StatefulWidget {
  final String mood;
  final List<String> tags;

  const JournalScreen({Key? key, required this.mood, required this.tags}) : super(key: key);

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class JournalPage {
  String text;
  List<InteractiveMedia> attachments;
  List<DrawingPoint> drawingPoints;

  JournalPage({
    this.text = '',
    List<InteractiveMedia>? attachments,
    List<DrawingPoint>? drawingPoints,
  })  : attachments = attachments ?? [],
        drawingPoints = drawingPoints ?? [];
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

  InteractiveMedia.fromMedia(Media media) : super(
    file: media.file,
    isVideo: media.isVideo,
    position: media.position,
    size: media.size,
    angle: media.angle,
  );
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
  late AnimationController _eraserAnimationController;
  late Animation<double> _eraserAnimation;
  InteractiveMedia? _selectedMedia;
  bool _isRainbowMode = true;
  double _rainbowOffset = 0.0;
  late AnimationController _pencilAnimationController;
  late Animation<double> _pencilAnimation;
  bool _isPencilActive = false;
  final PageController _pageController = PageController();
  List<JournalPage> _pages = [];
  int _currentPage = 0;
  final GlobalKey _pageKey = GlobalKey();
  double _pageHeight = 0;
  TextEditingController _currentPageController = TextEditingController();

  List<Color> _pencilColors = [
    Colors.black,  // Standard black pencil
    Color(0xFFFFE100),  // Original yellow
    Color(0xFFFFC917),  // Original yellow-orange
    Color(0xFFF8650C),  // Original orange
    Color(0xFFF00000),  // Original red
    Color(0xFF8C0000),  // Original dark red
  ];

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _recorder!.openRecorder();

    _pages.add(JournalPage());

    _currentPageController.addListener(_handleTextOverflow);

    _initializeAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePageSize();
    });
  }

  void _updatePageSize() {
    final RenderBox? renderBox = _pageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        _pageHeight = renderBox.size.height;
      });
    }
  }

  void _handleTextOverflow() {
    if (_currentPageController.text.isEmpty) return;

    final TextSpan textSpan = TextSpan(
      text: _currentPageController.text,
      style: TextStyle(color: Colors.black),
    );
    final TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    final availableHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        kToolbarHeight - 40;
    final availableWidth = MediaQuery.of(context).size.width - 40;

    textPainter.layout(maxWidth: availableWidth);

    if (textPainter.height > availableHeight) {
      final lastVisiblePosition = textPainter.getPositionForOffset(
          Offset(0, availableHeight)
      );

      final text = _currentPageController.text;
      int splitIndex = lastVisiblePosition.offset;

      while (splitIndex > 0 && text[splitIndex - 1] != ' ' && text[splitIndex - 1] != '\n') {
        splitIndex--;
      }

      if (splitIndex > 0) {
        final currentPageText = text.substring(0, splitIndex).trimRight();
        final nextPageText = text.substring(splitIndex).trimLeft();

        setState(() {
          _pages[_currentPage].text = currentPageText;
          _currentPageController.text = currentPageText;

          _pages.add(JournalPage(text: nextPageText));

          _pageController.animateToPage(
            _currentPage + 1,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );

          _textFocusNode.requestFocus();
        });
      }
    }
  }

  void _initializeAnimations() {
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

    _pencilAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _pencilAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(
        parent: _pencilAnimationController,
        curve: Curves.easeInOut,
      ),
    );
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
      _eraserAnimationController.reverse();
      _pencilAnimationController.forward();
      _selectedMedia = null;
    });
  }

  void _togglePencil() {
    setState(() {
      _isPencilActive = !_isPencilActive;
      if (_isPencilActive) {
        _pencilAnimationController.forward();
        _eraserAnimationController.reverse();
        _isEraserActive = false;
      } else {
        _pencilAnimationController.reverse();
      }
      _selectedMedia = null;
    });
  }

  void _toggleEraser() {
    setState(() {
      _isEraserActive = !_isEraserActive;
      if (_isEraserActive) {
        _eraserAnimationController.forward();
        _pencilAnimationController.reverse();
        _isPencilActive = false;
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
        isRainbow: false,
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
      media.position += details.focalPointDelta;

      media.size = (media.size * details.scale).clamp(50.0, 500.0);

      if (details.rotation != 0) {
        double newAngle = (details.rotation * 180 / 3.14159265359) / 15.0;
        newAngle = newAngle.round() * 15.0;
        media.angle = newAngle * 3.14159265359 / 180;
      }
    });
  }

  void _addNewPage() {
    setState(() {
      _pages.add(JournalPage());
      _pageController.animateToPage(
        _pages.length - 1,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _checkLastLineAndCreatePage(String text) {
    final TextSpan textSpan = TextSpan(
      text: text,
      style: TextStyle(color: Colors.black),
    );
    final TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    final availableHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        kToolbarHeight - 40;
    final availableWidth = MediaQuery.of(context).size.width - 40;

    textPainter.layout(maxWidth: availableWidth);

    final lineHeight = textPainter.preferredLineHeight;
    final maxLines = (availableHeight / lineHeight).floor();
    final currentLines = '\n'.allMatches(text).length + 1;

    if (currentLines >= maxLines || textPainter.height + lineHeight > availableHeight) {
      setState(() {
        _pages.add(JournalPage());

        _pageController.animateToPage(
          _currentPage + 1,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
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
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addNewPage,
            tooltip: 'Add New Page',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.horizontal,
            pageSnapping: true,
            physics: (_isPencilActive || _isEraserActive)
                ? NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
                _selectedMedia = null;
                _currentPageController.text = _pages[index].text;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Container(
                    key: index == _currentPage ? _pageKey : null,
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          kToolbarHeight,
                    ),
                    child: Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(20),
                          child: TextField(
                            controller: index == _currentPage
                                ? _currentPageController
                                : TextEditingController(text: _pages[index].text),
                            focusNode: index == _currentPage ? _textFocusNode : null,
                            maxLines: null,
                            readOnly: _isDrawingMode || index != _currentPage,
                            style: TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: "Type here...",
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                            onChanged: (value) {
                              _pages[index].text = value;
                              if (value.endsWith('\n')) {
                                _checkLastLineAndCreatePage(value);
                              }
                            },
                          ),
                        ),
                        if (index == _currentPage)
                          IgnorePointer(
                            ignoring: !_isDrawingMode,
                            child: GestureDetector(
                              onPanStart: _handleDrawingStart,
                              onPanUpdate: _handleDrawingUpdate,
                              onPanEnd: _handleDrawingEnd,
                              child: SingleChildScrollView(
                                physics: (_isPencilActive || _isEraserActive)
                                    ? NeverScrollableScrollPhysics()
                                    : ClampingScrollPhysics(),
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  height: MediaQuery.of(context).size.height -
                                      MediaQuery.of(context).padding.top -
                                      kToolbarHeight -
                                      (MediaQuery.of(context).padding.bottom + 60),
                                  child: Stack(
                                    children: [
                                      CustomPaint(
                                        size: Size.infinite,
                                        painter: _SmoothDrawingPainter(
                                          points: _points,
                                          showLines: _showLines,
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
                                              _attachments[index] = InteractiveMedia.fromMedia(updatedMedia);
                                              if (_selectedMedia == media) {
                                                _selectedMedia = _attachments[index];
                                              }
                                            }
                                          });
                                        },
                                        isEditingMode: !_isDrawingMode,
                                      )).toList(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _isDrawingMode ? _buildDrawingToolbar() : null,
      resizeToAvoidBottomInset: true,
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
                  onPressed: _drawingHistory.isEmpty ? null : _clearDrawing,
                ),
                IconButton(
                  icon: Icon(
                    Icons.redo,
                    color: _redoHistory.isEmpty ? Colors.grey : Colors.white,
                    size: toolbarHeight * 0.3,
                  ),
                  onPressed: _redoHistory.isEmpty ? null : _clearDrawing,
                ),
                GestureDetector(
                  onTap: _togglePencil,
                  onDoubleTap: _changePencilColor,
                  child: AnimatedBuilder(
                    animation: _pencilAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_pencilAnimation.value),
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
                  ),
                ),
                GestureDetector(
                  onTap: _toggleEraser,
                  child: AnimatedBuilder(
                    animation: _eraserAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_eraserAnimation.value),
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

class _SmoothDrawingPainter extends CustomPainter {
  final List<DrawingPoint> points;
  final bool showLines;

  _SmoothDrawingPainter({
    required this.points,
    required this.showLines,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    Paint eraserPaint = Paint()
      ..color = Colors.white
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
  bool shouldRepaint(covariant _SmoothDrawingPainter oldDelegate) {
    return true;
  }
}

class DrawingPoint {
  final Offset position;
  final Color color;
  final bool isEraser;
  final double strokeWidth;
  final bool isRainbow;

  DrawingPoint({
    required this.position,
    required this.color,
    required this.isEraser,
    required this.strokeWidth,
    required this.isRainbow,
  });
}