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

  static Future<void> saveJournalData(DateTime date, JournalData data) async {
    _journalData[date] = data;
    await _saveToPrefs();
  }

  static Future<JournalData?> getJournalData(DateTime date) async {
    if (_journalData.containsKey(date)) {
      return _journalData[date];
    }
    await _loadFromPrefs();
    return _journalData[date];
  }

  static Future<void> deleteJournalData(DateTime date) async {
    _journalData.remove(date);
    await _saveToPrefs();
  }

  static Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedData = _journalData.map((key, value) => MapEntry(
      key.toIso8601String(),
      jsonEncode({
        'title': value.title,
        'content': value.content,
        'drawingPoints': value.drawingPoints,
        'attachments': value.attachments.map((a) {
          print('Saving media: ${a.file.path}, position: ${a.position}, size: ${a.size}, angle: ${a.angle}');
          return a.toJson();
        }).toList(),
      }),
    ));
    await prefs.setString('journalData', jsonEncode(encodedData));
  }

  static Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('journalData');
    if (data != null) {
      final decodedData = jsonDecode(data) as Map<String, dynamic>;
      _journalData.clear();
      decodedData.forEach((key, value) {
        final entry = jsonDecode(value);
        final attachments = List<Map<String, dynamic>>.from(entry['attachments'])
            .map((a) {
          final media = InteractiveMedia.fromJson(a);
          print('Loading media: ${media.file.path}, position: ${media.position}, size: ${media.size}, angle: ${media.angle}');
          return media;
        })
            .toList();
        _journalData[DateTime.parse(key)] = JournalData(
          title: entry['title'],
          content: entry['content'],
          drawingPoints: List<Map<String, dynamic>>.from(entry['drawingPoints']),
          attachments: attachments,
        );
      });
    }
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
  final JournalData? initialData;

  const JournalScreen({
    super.key,
    required this.date,
    required this.color,
    this.initialData,
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

  Map<String, dynamic> toJson() {
    return {
      'filePath': file.path,
      'isVideo': isVideo,
      'position': {'dx': position.dx, 'dy': position.dy},
      'size': size,
      'angle': angle,
    };
  }

  factory InteractiveMedia.fromJson(Map<String, dynamic> json) {
    return InteractiveMedia(
      file: File(json['filePath']),
      isVideo: json['isVideo'],
      position: Offset(json['position']['dx'], json['position']['dy']),
      size: json['size'],
      angle: json['angle'],
    );
  }
}

class _JournalScreenState extends State<JournalScreen> with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final List<DrawingPoint> _points = [];
  final List<List<DrawingPoint>> _drawingHistory = [];
  final List<List<DrawingPoint>> _redoHistory = [];
  List<InteractiveMedia> _attachments = [];
  FlutterSoundRecorder? _recorder;
  bool _showLines = false;
  Color _currentColor = Colors.black;
  int _pencilIndex = 0;
  bool _isEraserActive = false;
  double _strokeWidth = 3.0;
  double _minStrokeWidth = 1.0;
  double _maxStrokeWidth = 20.0;
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
  late QuillController _controller;
  bool _isControllerInitialized = false; // Add this line
  String _title = '';
  List<Map<String, dynamic>> _content = [];
  List<Map<String, dynamic>> _drawingPoints = [];
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

    // Initialize with empty controller first
    _controller = QuillController(
      document: Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );

    _loadInitialData(); // This will load the real data
    _initializeAnimations();
  }

  @override
  void dispose() {
    _saveJournal();
    _controller.dispose();
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

  void _loadInitialData() async {
    try {
      if (widget.initialData != null) {
        await _initializeWithData(widget.initialData!);
        return;
      }

      final journalData = await JournalState.getJournalData(widget.date);
      if (journalData != null) {
        await _initializeWithData(journalData);
      } else {
        setState(() {
          _titleController.text = "Untitled Journal";
          _isControllerInitialized = true;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isControllerInitialized = true;
      });
    }
  }

  Future<void> _initializeWithData(JournalData data) async {
    try {
      final doc = Document.fromJson(data.content);
      setState(() {
        _title = data.title;
        _titleController.text = data.title;
        _content = data.content;
        _attachments = data.attachments;

        // Load drawing points
        _points.clear();
        for (var pointData in data.drawingPoints) {
          _points.add(DrawingPoint(
            position: Offset(pointData['x'], pointData['y']),
            color: Color(pointData['color']),
            isEraser: pointData['isEraser'],
            strokeWidth: pointData['strokeWidth'],
            isRainbow: pointData['isRainbow'],
          ));
        }

        _controller = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
        _isControllerInitialized = true;
      });
    } catch (e) {
      print('Error initializing: $e');
      setState(() {
        _isControllerInitialized = true;
      });
    }
  }

  void _saveJournal() {
    final drawingPoints = _points.map((point) => {
      'x': point.position.dx,
      'y': point.position.dy,
      'color': point.color.value,
      'isEraser': point.isEraser,
      'strokeWidth': point.strokeWidth,
      'isRainbow': point.isRainbow,
    }).toList();

    final journalData = JournalData(
      title: _title,
      content: _controller.document.toDelta().toJson(),
      drawingPoints: drawingPoints,
      attachments: _attachments,
    );

    JournalState.saveJournalData(widget.date, journalData);
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

  void _deleteSelectedMedia() {
    if (_selectedMedia != null) {
      setState(() {
        _attachments.remove(_selectedMedia);
        _selectedMedia = null;
      });
    }
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
                final selection = _controller.selection;
                _controller.document.insert(
                  selection.baseOffset,
                  '$_text ',
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

  Future<void> _pickMedia() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      try {
        final file = File(pickedFile.path);

        if (!file.existsSync()) {
          throw Exception('Selected image does not exist');
        }

        setState(() {
          _attachments.add(InteractiveMedia(
            file: file,
            isVideo: false,
            position: Offset(
              MediaQuery.of(context).size.width / 2 - 100,
              MediaQuery.of(context).size.height / 2 - 100,
            ),
            size: 200.0,
            angle: 0.0,
          ));
        });
      } catch (e) {
        print('Error picking image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickVideo(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      try {
        final file = File(pickedFile.path);

        if (!file.existsSync()) {
          throw Exception('Selected video does not exist');
        }

        // Verify the video can be played
        final videoController = VideoPlayerController.file(file);
        try {
          await videoController.initialize();
          videoController.dispose();
        } catch (e) {
          throw Exception('Invalid video file');
        }

        setState(() {
          _attachments.add(InteractiveMedia(
            file: file,
            isVideo: true,
            position: Offset(
              MediaQuery.of(context).size.width / 2 - 100,
              MediaQuery.of(context).size.height / 2 - 100,
            ),
            size: 200.0,
            angle: 0.0,
          ));
        });
      } catch (e) {
        print('Error picking video: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading video: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      final index = _controller.selection.baseOffset;
      final length = _controller.selection.extentOffset - index;
      _controller.formatText(index, length, LinkAttribute(link));
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

  @override
  Widget build(BuildContext context) {
    if (!_isControllerInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = bottomInset > 0;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) {
          _saveJournal();
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
                color: Color(0xFF1E1E1E).withAlpha(179),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            textAlign: TextAlign.center,
            onChanged: (value) {
              setState(() {
                _title = value;
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
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: () {
                _saveJournal();
                Navigator.pop(context);
              },
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
                    color: Colors.black.withAlpha(26),
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
                            controller: _controller,
                            scrollController: _editorScrollController,
                            focusNode: _editorFocusNode,
                            config: QuillEditorConfig(
                              placeholder: 'Start writing your notes...',
                              padding: const EdgeInsets.all(16),
                            ),
                          ):
                          _isControllerInitialized
                              ? QuillEditor(
                            controller: _controller,
                            scrollController: _editorScrollController,
                            focusNode: _editorFocusNode,
                            config: QuillEditorConfig(
                              placeholder: 'Start writing your notes...',
                              padding: const EdgeInsets.all(16),
                            ),
                          )
                              : const Center(child: CircularProgressIndicator())
                      ),
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
                                _selectedMedia = _attachments[index];
                              }
                            }
                          });
                        },
                        isEditingMode: true,
                      )),
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
                        color: Colors.black.withAlpha(26),
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
                          _controller.undo();
                          _editorFocusNode.requestFocus();
                        }),
                        _buildToolbarButton(Icons.redo, () {
                          _controller.redo();
                          _editorFocusNode.requestFocus();
                        }),
                        _buildToolbarButton(Icons.image, () {
                          _pickMedia();
                          _editorFocusNode.requestFocus();
                        }),
                        _buildToolbarButton(Icons.video_library, () {
                          _pickVideo();
                          _editorFocusNode.requestFocus();
                        }),
                        _buildToolbarButton(Icons.link, () {
                          _showLinkDialog();
                          _editorFocusNode.requestFocus();
                        }),
                        VerticalDivider(thickness: 1, width: 8, color: Colors.white24),
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
                        VerticalDivider(thickness: 1, width: 8, color: Colors.white24),
                        _buildToolbarButton(Icons.format_align_left, () {
                          _controller.formatSelection(Attribute.blockQuote);
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
                        VerticalDivider(thickness: 1, width: 8, color: Colors.white24),
                        _buildToolbarButton(Icons.format_list_bulleted, () {
                          _controller.formatSelection(Attribute.ul);
                          _editorFocusNode.requestFocus();
                        }),
                        _buildToolbarButton(Icons.format_list_numbered, () {
                          _controller.formatSelection(Attribute.ol);
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
                  child: AnimatedBuilder(
                    animation: _pencilAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, -_pencilAnimation.value),
                        child: Container(
                          padding: EdgeInsets.all(toolbarHeight * 0.05),
                          decoration: BoxDecoration(
                            color: _isPencilActive ? Colors.white.withAlpha(51) : Colors.transparent,
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
                            color: _isEraserActive ? Colors.white.withAlpha(51) : Colors.transparent,
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
                Container(
                  width: toolbarHeight * 1.5,
                  height: toolbarHeight * 0.4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.brush,
                        color: Colors.white,
                        size: toolbarHeight * 0.25,
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white.withOpacity(0.3),
                            thumbColor: Colors.white,
                            overlayColor: Colors.white.withOpacity(0.1),
                            trackHeight: 2.0,
                            thumbShape: RoundSliderThumbShape(
                              enabledThumbRadius: toolbarHeight * 0.1,
                            ),
                            overlayShape: RoundSliderOverlayShape(
                              overlayRadius: toolbarHeight * 0.15,
                            ),
                          ),
                          child: Slider(
                            value: _strokeWidth,
                            min: _minStrokeWidth,
                            max: _maxStrokeWidth,
                            onChanged: (value) {
                              setState(() {
                                _strokeWidth = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
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
                border: _isInEditMode
                    ? Border.all(
                    color: Colors.green,
                    width: 2)
                    : null,
              ),
              child: widget.media.isVideo
                  ? VideoWidget(file: widget.media.file)
                  : Image.file(
                widget.media.file,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.error, color: Colors.red),
                  );
                },
              ),
            ),
          ),
        ),
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
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      if (!widget.file.existsSync()) {
        throw Exception('Video file does not exist');
      }

      _controller = VideoPlayerController.file(widget.file)
        ..addListener(() {
          if (mounted) {
            setState(() {});
          }
        });

      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _isInitialized = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Center(
        child: Icon(Icons.error, color: Colors.red),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          if (!_controller.value.isPlaying)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, size: 50, color: Colors.white),
            ),
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
    // Draw dot grid background if showLines is true
    if (showLines) {
      final dotPaint = Paint()
        ..color = Colors.grey.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      const dotSpacing = 20.0; // Space between dots
      const dotSize = 2.0; // Size of each dot

      // Draw dots in a grid pattern
      for (double x = 0; x < size.width; x += dotSpacing) {
        for (double y = 0; y < size.height; y += dotSpacing) {
          canvas.drawCircle(Offset(x, y), dotSize, dotPaint);
        }
      }
    }

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