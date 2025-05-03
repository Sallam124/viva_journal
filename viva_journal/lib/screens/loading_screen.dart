import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final List<Color> colors = [
    const Color(0xFFFFE100),  // Yellow
    const Color(0xFFFFC917),  // Light Orange
    const Color(0xFFF8650C),  // Orange
    const Color(0xFFF00000),  // Red
    const Color(0xFF8C0000),  // Dark Red
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
        duration: const Duration(milliseconds: 600), // Faster animation
      );
    });

    _animations = List.generate(colors.length, (index) {
      return Tween<double>(
        begin: 0,
        end: 1,
      ).animate(
        CurvedAnimation(
          parent: _controllers[index],
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        ),
      );
    });

    _startSequentialPattern();
  }

  Future<void> _loadMessages() async {
    final String fileContent = await rootBundle.loadString('assets/on_screen_messages.txt');
    if (mounted) {
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
  }

  void _startMessageRotation() {
    Timer? messageTimer;
    messageTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        setState(() {
          _pickNewMessage();
        });
      } else {
        messageTimer?.cancel();
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
      Future.delayed(Duration(milliseconds: i * 200), () { // Faster sequence
        if (mounted && !_controllers[i].isAnimating) {
          _controllers[i].repeat(reverse: true);
        }
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
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(colors.length, (index) {
              return AnimatedBuilder(
                animation: _animations[index],
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -20 * _animations[index].value), // More pronounced bounce
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: SvgPicture.asset(
                          "assets/images/Star.svg",
                          colorFilter: ColorFilter.mode(
                              colors[index],
                              BlendMode.srcIn
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              currentMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}