import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _animations;
  final List<Color> colors = [
    Colors.yellow,
    Colors.orangeAccent,
    Colors.orange,
    Colors.redAccent,
    Colors.red[900]!,
  ];

  List<String> messages = [];
  late List<String> unseenMessages;
  String currentMessage = "";

  @override
  void initState() {
    super.initState();
    _loadMessages();

    _controllers = List.generate(colors.length, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200), // Slower animation
      );
    });

    _animations = List.generate(colors.length, (index) {
      return Tween<Offset>(
        begin: const Offset(0, 0),
        end: const Offset(0, -1), // Smaller jump height
      ).animate(
        CurvedAnimation(
          parent: _controllers[index],
          curve: Curves.easeInOut,
        ),
      );
    });

    _startSequentialPattern();
  }

  Future<void> _loadMessages() async {
    final String fileContent = await rootBundle.loadString('assets/on_screen_messages.txt');
    setState(() {
      messages = fileContent
          .split('\n')
          .map((msg) => msg.replaceAll(RegExp(r'[",]|on_screen_messages'), '').trim())
          .where((msg) => msg.isNotEmpty)
          .toList();
      unseenMessages = List.from(messages);
      _pickNewMessage();
      _startMessageRotation();
    });
  }

  void _startMessageRotation() {
    Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        setState(() {
          _pickNewMessage();
        });
      }
    });
  }

  void _pickNewMessage() {
    if (unseenMessages.isEmpty) {
      unseenMessages = List.from(messages);
    }
    currentMessage = unseenMessages.removeAt(Random().nextInt(unseenMessages.length));
  }

  void _startSequentialPattern() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 400), () { // Slower, consecutive movement
        _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(colors.length, (index) {
              return SlideTransition(
                position: _animations[index],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: CustomPaint(
                    size: const Size(40, 40),
                    painter: ConcaveStarPainter(colors[index]),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              currentMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class ConcaveStarPainter extends CustomPainter {
  final Color color;

  ConcaveStarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final Path path = Path();

    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width * 0.64, size.height * 0.36);
    path.lineTo(size.width, size.height * 0.5);
    path.lineTo(size.width * 0.64, size.height * 0.64);
    path.lineTo(size.width * 0.5, size.height);
    path.lineTo(size.width * 0.36, size.height * 0.64);
    path.lineTo(0, size.height * 0.5);
    path.lineTo(size.width * 0.36, size.height * 0.36);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
