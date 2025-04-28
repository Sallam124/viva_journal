import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../widgets/media.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Journal state management
class JournalState {
  static final Map<DateTime, JournalData> _journalData = {};

  static void saveJournalData(DateTime date, JournalData data) {
    _journalData[date] = data;
  }

  static Future<JournalData?> getJournalData(DateTime date) async {
    return _journalData[date];
  }
}

class JournalData {
  final String title;
  final List<Map<String, dynamic>> content;
  final List<Map<String, dynamic>> drawingPoints;
  final List<InteractiveMedia> attachments;

  JournalData({
    required this.title,
    required this.content,
    required this.drawingPoints,
    required this.attachments,
  });
}

class JournalScreen extends StatefulWidget {
  final DateTime date;
  final Color color;

  const JournalScreen({
    super.key,
    required this.date,
    required this.color,
  });

  @override
  State<JournalScreen> createState() => _JournalScreenState();
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
  final TextEditingController _titleController = TextEditingController();
  final List<DrawingPoint> _points = [];
  final List<List<DrawingPoint>> _drawingHistory = [];
  final List<List<DrawingPoint>> _redoHistory = [];
  final List<InteractiveMedia> _attachments = [];
  FlutterSoundRecorder? _recorder;
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
  final QuillController _quillController = QuillController.basic();
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = '';

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
    _recorder = FlutterSoundRecorder();
    _recorder!.openRecorder();
    _initSpeech();
    _titleController.text = "Untitled Journal";
    _currentColor = widget.color;

    // Initialize with empty document
    _quillController.document = Document.fromJson([
      {"insert": "\n", "attributes": {"block": "normal"}}
    ]);

    // Load saved journal data if exists
    _loadJournalData();

    _initializeAnimations();
  }

  @override
  void dispose() {
    // Save journal data before disposing
    _saveJournalData();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    _titleController.dispose();
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
      _points.clear();
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
    if (!_isPencilActive && !_isEraserActive) return;

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

        _points.clear();
        _points.addAll(pointsToKeep);
      } else if (_isPencilActive) {
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
    if (!_isPencilActive && !_isEraserActive) return;

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

  void _initSpeech() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() {});
    }
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _text = result.recognizedWords;
              if (result.finalResult) {
                // Get the current selection
                final selection = _quillController.selection;
                // Insert the text at the current selection
                _quillController.document.insert(
                  selection.baseOffset,
                  _text + ' ',
                );
                _text = '';
              }
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = bottomInset > 0;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) {
          _saveJournalData();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: widget.color,
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: 'Back',
          ),
          title: TextField(
            controller: _titleController,
            style: TextStyle(
              color: Color(0xFF1E1E1E),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Enter title...',
              hintStyle: TextStyle(
                color: Color(0xFF1E1E1E).withAlpha(179), // 0.7 * 255 ≈ 179
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            textAlign: TextAlign.center,
            onChanged: (value) {
              setState(() {
                // Update title if needed
              });
            },
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
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26), // 0.1 * 255 ≈ 26
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Container(
                  key: _pageKey,
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        kToolbarHeight,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        padding: EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 20,
                          bottom: isKeyboardVisible ? bottomInset + 80 : 20,
                        ),
                        child: _isDrawingMode
                            ? QuillEditor(
                          controller: _quillController,
                          scrollController: _editorScrollController,
                          focusNode: _editorFocusNode,
                          config: QuillEditorConfig(
                            placeholder: 'Start writing your notes...',
                            padding: const EdgeInsets.all(16),
                          ),
                        )
                            : QuillEditor(
                          controller: _quillController,
                          scrollController: _editorScrollController,
                          focusNode: _editorFocusNode,
                          config: QuillEditorConfig(
                            placeholder: 'Start writing your notes...',
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        ignoring: !_isDrawingMode,
                        child: GestureDetector(
                          onPanStart: _handleDrawingStart,
                          onPanUpdate: _handleDrawingUpdate,
                          onPanEnd: _handleDrawingEnd,
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
                                )).toList(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!_isDrawingMode)
              Positioned(
                left: 0,
                right: 0,
                bottom: isKeyboardVisible ? bottomInset : 0,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26), // 0.1 * 255 ≈ 26
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
                        _buildToolbarButton(
                          _isListening ? Icons.mic : Icons.mic_none,
                              () {
                            _startListening();
                            _editorFocusNode.requestFocus();
                          },
                        ),
                        VerticalDivider(thickness: 1, width: 8, color: Colors.white24),
                        _buildToolbarButton(Icons.undo, () {
                          _quillController.undo();
                          _editorFocusNode.requestFocus();
                        }),
                        _buildToolbarButton(Icons.redo, () {
                          _quillController.redo();
                          _editorFocusNode.requestFocus();
                        }),
                        VerticalDivider(thickness: 1, width: 8, color: Colors.white24),
                        _buildToolbarButton(Icons.format_bold, () {
                          _quillController.formatSelection(Attribute.bold);
                          _editorFocusNode.requestFocus();
                        }),
                        _buildToolbarButton(Icons.format_italic, () {
                          _quillController.formatSelection(Attribute.italic);
                          _editorFocusNode.requestFocus();
                        }),
                        _buildToolbarButton(Icons.format_underline, () {
                          _quillController.formatSelection(Attribute.underline);
                          _editorFocusNode.requestFocus();
                        }),
                        _buildToolbarButton(Icons.format_strikethrough, () {
                          _quillController.formatSelection(Attribute.strikeThrough);
                          _editorFocusNode.requestFocus();
                        }),
                        VerticalDivider(thickness: 1, width: 8, color: Colors.white24),
                        _buildToolbarButton(Icons.format_align_left, () {
                          _quillController.formatSelection(Attribute.blockQuote);
                          _editorFocusNode.requestFocus();
                        }),
                        _buildToolbarButton(Icons.format_align_center, () {
                          _quillController.formatSelection(Attribute.centerAlignment);
                          _editorFocusNode.requestFocus();
                        }),
                        _buildToolbarButton(Icons.format_align_right, () {
                          _quillController.formatSelection(Attribute.rightAlignment);
                          _editorFocusNode.requestFocus();
                        }),
                        VerticalDivider(thickness: 1, width: 8, color: Colors.white24),
                        _buildToolbarButton(Icons.format_list_bulleted, () {
                          _quillController.formatSelection(Attribute.ul);
                          _editorFocusNode.requestFocus();
                        }),
                        _buildToolbarButton(Icons.format_list_numbered, () {
                          _quillController.formatSelection(Attribute.ol);
                          _editorFocusNode.requestFocus();
                        }),
                        VerticalDivider(thickness: 1, width: 8, color: Colors.white24),
                        _buildToolbarButton(Icons.link, () {
                          _showLinkDialog();
                          _editorFocusNode.requestFocus();
                        }),
                        _buildToolbarButton(Icons.image, () {
                          _pickMedia();
                          _editorFocusNode.requestFocus();
                        }),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: _isDrawingMode ? _buildDrawingToolbar() : null,
        resizeToAvoidBottomInset: false,
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
                            color: _isPencilActive ? Colors.white.withAlpha(51) : Colors.transparent, // 0.2 * 255 ≈ 51
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
                            color: _isEraserActive ? Colors.white.withAlpha(51) : Colors.transparent, // 0.2 * 255 ≈ 51
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

  Widget _buildToolbarButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: Colors.white,
      splashRadius: 20,
      padding: EdgeInsets.symmetric(horizontal: 8),
      constraints: BoxConstraints(minWidth: 36, minHeight: 36),
      onPressed: onPressed,
    );
  }

  Future<void> _showLinkDialog() async {
    final link = await showDialog<String>(
      context: context,
      builder: (context) {
        String url = '';
        return AlertDialog(
          title: Text('Insert Link'),
          content: TextField(
            decoration: InputDecoration(hintText: 'Enter URL'),
            onChanged: (value) => url = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, url),
              child: Text('Insert'),
            ),
          ],
        );
      },
    );

    if (link != null && link.isNotEmpty) {
      final index = _quillController.selection.baseOffset;
      final length = _quillController.selection.extentOffset - index;
      _quillController.formatText(index, length, LinkAttribute(link));
    }
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

  void _undo() {
    if (_drawingHistory.isNotEmpty) {
      setState(() {
        _redoHistory.add(List.from(_points));
        _points.clear();
        _points.addAll(_drawingHistory.removeLast());
      });
    }
  }

  void _redo() {
    if (_redoHistory.isNotEmpty) {
      setState(() {
        _drawingHistory.add(List.from(_points));
        _points.clear();
        _points.addAll(_redoHistory.removeLast());
      });
    }
  }

  void _saveJournalData() {
    JournalState.saveJournalData(
      widget.date,
      JournalData(
        title: _titleController.text,
        content: _quillController.document.toDelta().toJson(),
        drawingPoints: _points.map((point) => {
          'position': {'dx': point.position.dx, 'dy': point.position.dy},
          'color': point.color.value,
          'isEraser': point.isEraser,
          'strokeWidth': point.strokeWidth,
          'isRainbow': point.isRainbow,
        }).toList(),
        attachments: _attachments,
      ),
    );
  }

  Future<void> _loadJournalData() async {
    final savedData = await JournalState.getJournalData(widget.date);
    if (savedData != null) {
      setState(() {
        _quillController.document = Document.fromDelta(Delta.fromJson(savedData.content));
        _points.clear();
        _points.addAll(savedData.drawingPoints.map((point) => DrawingPoint(
          position: Offset(point['position']['dx'], point['position']['dy']),
          color: Color(point['color']),
          isEraser: point['isEraser'],
          strokeWidth: point['strokeWidth'],
          isRainbow: point['isRainbow'],
        )).toList());
        _attachments.clear();
        _attachments.addAll(savedData.attachments);
        _titleController.text = savedData.title;
      });
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