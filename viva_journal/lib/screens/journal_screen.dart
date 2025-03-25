import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

class JournalScreen extends StatefulWidget {
  final String mood;
  final List<String> tags;

  JournalScreen({required this.mood, required this.tags});

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  TextEditingController _textController = TextEditingController();
  List<List<Offset>> _drawings = [];
  List<Color> _colors = [Colors.black, Colors.blue, Colors.red, Colors.green];
  Color _selectedColor = Colors.black;
  List<File> _attachments = [];
  FlutterSoundRecorder? _recorder;
  String? _voiceNotePath;
  final FlutterTts _flutterTts = FlutterTts();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _recorder!.openRecorder();
    _drawings.add([]); // Initialize with an empty stroke
  }

  @override
  void dispose() {
    _textController.dispose();
    _recorder!.closeRecorder();
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

  void _changePenColor(Color color) {
    setState(() {
      _selectedColor = color;
      _drawings.add([]); // Start a new stroke when color changes
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Journal'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _textController,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: "Type something...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _drawings.last.add(details.localPosition);
                    });
                  },
                  onPanEnd: (_) => _drawings.add([]),
                  child: CustomPaint(
                    painter: DrawingPainter(_drawings, _colors),
                    child: Container(),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Row(
                    children: _colors.map((color) {
                      return GestureDetector(
                        onTap: () => _changePenColor(color),
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedColor == color ? Colors.black : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.image),
                  onPressed: _pickImage,
                ),
                IconButton(
                  icon: Icon(_isRecording ? Icons.mic_off : Icons.mic),
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                ),
                IconButton(
                  icon: Icon(Icons.play_arrow),
                  onPressed: _speakText,
                ),
                IconButton(
                  icon: Icon(Icons.save),
                  onPressed: () {
                    // Implement save logic
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for drawing with multiple colors
class DrawingPainter extends CustomPainter {
  final List<List<Offset>> drawings;
  final List<Color> colors;

  DrawingPainter(this.drawings, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < drawings.length; i++) {
      Paint paint = Paint()
        ..color = colors[i % colors.length]
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      for (int j = 0; j < drawings[i].length - 1; j++) {
        if (drawings[i][j] != Offset.zero && drawings[i][j + 1] != Offset.zero) {
          canvas.drawLine(drawings[i][j], drawings[i][j + 1], paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDaelegate) => true;
}
