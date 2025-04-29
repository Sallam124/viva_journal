//old file
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/media.dart';
import 'package:video_player/video_player.dart';
import 'dart:math';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class JournalScreen extends StatefulWidget {
  final String mood;
  final List<String> tags;

  const JournalScreen({super.key, required this.mood, required this.tags});

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class InteractiveMedia extends Media {
  InteractiveMedia({
    required super.file,
    super.isVideo,
    super.position,
    super.size,
    super.angle,
  });

  InteractiveMedia.fromMedia(Media media) : super(
    file: media.file,
    isVideo: media.isVideo,
    position: media.position,
    size: media.size,
    angle: media.angle,
  );
}

class _JournalScreenState extends State<JournalScreen> with TickerProviderStateMixin {
  late QuillController _controller;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  List<DrawingPoint> _points = [];
  final List<List<DrawingPoint>> _drawingHistory = [];
  final List<List<DrawingPoint>> _redoHistory = [];
  final List<InteractiveMedia> _attachments = [];
  FlutterSoundRecorder? _recorder;
  String? _voiceNotePath;
  final FlutterTts _flutterTts = FlutterTts();
  bool _isRecording = false;
  bool _showLines = false;
  Color _currentColor = Colors.black;
  int _pencilIndex = 0;
  bool _isEraserActive = false;
  final double _strokeWidth = 3.0;
  final double _eraserWidth = 30.0;
  bool _isDrawingMode = false;
  late AnimationController _eraserAnimationController;
  late Animation<double> _eraserAnimation;
  InteractiveMedia? _selectedMedia;
  bool _isRainbowMode = true;
  late AnimationController _pencilAnimationController;
  late Animation<double> _pencilAnimation;
  bool _isPencilActive = false;
  final GlobalKey _pageKey = GlobalKey();

  final List<Color> _pencilColors = [
    Colors.black,
    Color(0xFFFFE100),
    Color(0xFFFFC917),
    Color(0xFFF8650C),
    Color(0xFFF00000),
    Color(0xFF8C0000),
  ];

  @override
  void initState() {
    super.initState();
    _controller = QuillController.basic();
    _recorder = FlutterSoundRecorder();
    _recorder!.openRecorder();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _controller.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    _recorder?.closeRecorder();
    _eraserAnimationController.dispose();
    _pencilAnimationController.dispose();
    super.dispose();
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
      Color(0xFFFFE100),
      Color(0xFFFFC917),
      Color(0xFFF8650C),
      Color(0xFFF00000),
      Color(0xFF8C0000),
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
        _editorFocusNode.requestFocus();
      } else {
        _editorFocusNode.unfocus();
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
      body: Container(
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
        child: Column(
          children: [
            Expanded(
              child: Container(
                key: _pageKey,
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      controller: _editorScrollController,
                      child: Container(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height -
                              MediaQuery.of(context).padding.top -
                              kToolbarHeight -
                              (MediaQuery.of(context).padding.bottom + 60),
                        ),
                        child: Stack(
                          children: [
                            Container(
                              padding: EdgeInsets.all(20),
                              child: QuillEditor(
                                focusNode: _editorFocusNode,
                                scrollController: _editorScrollController,
                                controller: _controller,
                                config: QuillEditorConfig(
                                  placeholder: 'Start writing your notes...',
                                  padding: const EdgeInsets.all(16),
                                  embedBuilders: FlutterQuillEmbeds.editorBuilders(
                                    imageEmbedConfig: QuillEditorImageEmbedConfig(
                                      imageProviderBuilder: (context, imageUrl) {
                                        if (imageUrl.startsWith('assets/')) {
                                          return AssetImage(imageUrl);
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onPanStart: _isDrawingMode ? _handleDrawingStart : null,
                              onPanUpdate: _isDrawingMode ? _handleDrawingUpdate : null,
                              onPanEnd: _isDrawingMode ? _handleDrawingEnd : null,
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
                                    ..._attachments.map((media) => Positioned(
                                      left: media.position.dx,
                                      top: media.position.dy,
                                      child: Transform.scale(
                                        scale: media.size / 200.0,
                                        child: Transform.rotate(
                                          angle: media.angle,
                                          child: MediaWidget(
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
                                          ),
                                        ),
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isDrawingMode ? _buildDrawingToolbar() : _buildQuillToolbar(),
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

  Widget _buildQuillToolbar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildToolbarButton(Icons.format_bold, () {
              _controller.formatSelection(Attribute.bold);
              _editorFocusNode.requestFocus();
            }),
            _buildToolbarButton(Icons.format_italic, () {
              _controller.formatSelection(Attribute.italic);
              _editorFocusNode.requestFocus();
            }),
            _buildToolbarButton(Icons.format_underline, () {
              _controller.formatSelection(Attribute.underline);
              _editorFocusNode.requestFocus();
            }),
            _buildToolbarButton(Icons.format_strikethrough, () {
              _controller.formatSelection(Attribute.strikeThrough);
              _editorFocusNode.requestFocus();
            }),
            VerticalDivider(thickness: 1, width: 8, color: Colors.grey[300]),
            _buildToolbarButton(Icons.format_align_left, () {
              _controller.formatSelection(Attribute.leftAlignment);
              _editorFocusNode.requestFocus();
            }),
            _buildToolbarButton(Icons.format_align_center, () {
              _controller.formatSelection(Attribute.centerAlignment);
              _editorFocusNode.requestFocus();
            }),
            _buildToolbarButton(Icons.format_align_right, () {
              _controller.formatSelection(Attribute.rightAlignment);
              _editorFocusNode.requestFocus();
            }),
            VerticalDivider(thickness: 1, width: 8, color: Colors.grey[300]),
            _buildToolbarButton(Icons.format_list_bulleted, () {
              _controller.formatSelection(Attribute.ul);
              _editorFocusNode.requestFocus();
            }),
            _buildToolbarButton(Icons.format_list_numbered, () {
              _controller.formatSelection(Attribute.ol);
              _editorFocusNode.requestFocus();
            }),
            _buildToolbarButton(Icons.format_quote, () {
              _controller.formatSelection(Attribute.blockQuote);
              _editorFocusNode.requestFocus();
            }),
            VerticalDivider(thickness: 1, width: 8, color: Colors.grey[300]),
            _buildToolbarButton(Icons.link, () {
              _showLinkDialog();
              _editorFocusNode.requestFocus();
            }),
            _buildToolbarButton(Icons.image, () {
              _pickMedia();
              _editorFocusNode.requestFocus();
            }),
            _buildToolbarButton(Icons.code, () {
              _controller.formatSelection(Attribute.inlineCode);
              _editorFocusNode.requestFocus();
            }),
            VerticalDivider(thickness: 1, width: 8, color: Colors.grey[300]),
            _buildToolbarButton(Icons.undo, () {
              _controller.undo();
              _editorFocusNode.requestFocus();
            }),
            _buildToolbarButton(Icons.redo, () {
              _controller.redo();
              _editorFocusNode.requestFocus();
            }),
            _buildToolbarButton(Icons.format_clear, () {
              final selection = _controller.selection;
              if (selection.isValid) {
                _controller.formatSelection(Attribute.bold);
                _controller.formatSelection(Attribute.italic);
                _controller.formatSelection(Attribute.underline);
                _controller.formatSelection(Attribute.strikeThrough);
                _controller.formatSelection(Attribute.inlineCode);
                _controller.formatSelection(Attribute.link);
                _controller.formatSelection(Attribute.ul);
                _controller.formatSelection(Attribute.ol);
                _controller.formatSelection(Attribute.blockQuote);
                _controller.formatSelection(Attribute.leftAlignment);
                _controller.formatSelection(Attribute.centerAlignment);
                _controller.formatSelection(Attribute.rightAlignment);
              }
              _editorFocusNode.requestFocus();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: Colors.grey[800],
      splashRadius: 20,
      padding: EdgeInsets.symmetric(horizontal: 8),
      constraints: BoxConstraints(minWidth: 36, minHeight: 36),
      onPressed: onPressed,
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

  Future<void> _showLinkDialog() async {
    final TextEditingController urlController = TextEditingController();
    final TextEditingController textController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Insert Link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: 'URL',
                hintText: 'https://example.com',
              ),
              keyboardType: TextInputType.url,
            ),
            SizedBox(height: 8),
            TextField(
              controller: textController,
              decoration: InputDecoration(
                labelText: 'Text to display',
                hintText: 'Link text',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (urlController.text.isNotEmpty) {
                Navigator.pop(context, {
                  'url': urlController.text,
                  'text': textController.text.isNotEmpty ? textController.text : urlController.text,
                });
              }
            },
            child: Text('Insert'),
          ),
        ],
      ),
    );

    if (result != null) {
      final url = result['url']!;
      final text = result['text']!;

      final selection = _controller.selection;
      if (selection.isValid) {
        _controller.formatSelection(LinkAttribute(url));
      }
    }
  }
}

class VideoWidget extends StatefulWidget {
  final File file;

  const VideoWidget({super.key, required this.file});

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