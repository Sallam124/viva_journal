import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:viva_journal/database/database.dart';
import 'package:viva_journal/screens/trackerlog_screen.dart';
import 'dart:async';

class MiniCalendar extends StatefulWidget {
  const MiniCalendar({super.key});

  @override
  MiniCalendarState createState() => MiniCalendarState();
}

class MiniCalendarState extends State<MiniCalendar> {
  late List<DateTime> _weekDates;
  final Map<DateTime, Entry> _entryData = {};
  final DatabaseHelper _db = DatabaseHelper();
  late Timer _rotationTimer;
  double _rotationAngle = 0.0;

  final List<List<String>> emotionProgressions = [
    ["Ecstatic", "Cheerful", "Excited", "Thrilled", "Overjoyed"],
    ["Happy", "Content", "Pleasant", "Cheerful", "Delighted"],
    ["Neutral", "Fine", "Satisfied", "Meh", "Indifferent"],
    ["Angry", "Irritated", "Stressed", "Frustrated", "Fuming"],
    ["Down", "Distressed", "Anxious", "Defeated", "Exhausted"],
  ];

  @override
  void initState() {
    super.initState();
    _initializeWeekDates();
    _fetchEntriesForWeek();

    _rotationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _rotationAngle += 0.01;
          if (_rotationAngle >= 2 * pi) {
            _rotationAngle = 0;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _rotationTimer.cancel();
    super.dispose();
  }

  void _initializeWeekDates() {
    DateTime now = DateTime.now();
    int currentWeekday = now.weekday;
    DateTime sunday = now.subtract(Duration(days: currentWeekday % 7));
    _weekDates = List.generate(7, (index) => sunday.add(Duration(days: index)));
  }

  Future<void> _fetchEntriesForWeek() async {
    try {
      for (DateTime date in _weekDates) {
        final entry = await _db.getEntryForDate(date);
        if (mounted) {
          setState(() {
            if (entry != null) {
              _entryData[date] = entry;
            } else {
              _entryData.remove(date);
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching entries: $e');
    }
  }

  String getMoodAsset(DateTime date) {
    final entry = _entryData[date];
    if (entry == null || entry.mood == null) return 'assets/images/Star0.png';

    final mood = entry.mood!;
    if (emotionProgressions[0].contains(mood)) return 'assets/images/Star1.png';
    if (emotionProgressions[1].contains(mood)) return 'assets/images/Star2.png';
    if (emotionProgressions[2].contains(mood)) return 'assets/images/Star3.png';
    if (emotionProgressions[3].contains(mood)) return 'assets/images/Star4.png';
    if (emotionProgressions[4].contains(mood)) return 'assets/images/Star5.png';
    return 'assets/images/Star0.png';
  }

  Color getMoodColor(DateTime date) {
    final entry = _entryData[date];
    if (entry == null || entry.mood == null) return const Color(0xFF2F2F2F);

    final mood = entry.mood!;
    if (emotionProgressions[0].contains(mood)) return const Color(0xFFFFE100);
    if (emotionProgressions[1].contains(mood)) return const Color(0xFFFFC917);
    if (emotionProgressions[2].contains(mood)) return const Color(0xFFF8650C);
    if (emotionProgressions[3].contains(mood)) return const Color(0xFFF00000);
    if (emotionProgressions[4].contains(mood)) return const Color(0xFF8C0000);
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          DateTime date = _weekDates[index];
          bool isToday = date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
          bool isFuture = date.isAfter(now);
          final entry = _entryData[date];
          final hasEntry = entry != null;
          Color moodColor = getMoodColor(date);

          Widget calendarDay = !hasEntry && !isFuture
              ? Container(
            width: 45,
            height: 80,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: !isToday ? const Color(0xFF2F2F2F) : null,
              borderRadius: BorderRadius.circular(12),
              gradient: isToday
                  ? SweepGradient(
                colors: [
                  const Color(0xFFFFE100),
                  const Color(0xFFFFC917),
                  const Color(0xFFF8650C),
                  const Color(0xFFF00000),
                  const Color(0xFF8C0000),
                  const Color(0xFFFFE100),
                ],
                stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                center: Alignment.center,
                transform: GradientRotation(_rotationAngle),
              )
                  : null,
              boxShadow: isToday
                  ? [
                BoxShadow(
                  color: moodColor.withAlpha(153),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                )
              ]
                  : [],
            ),
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: Colors.white,
                strokeWidth: 1.8,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('E').format(date)[0],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${date.day}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Image.asset(
                      getMoodAsset(date),
                      width: 18,
                      height: 18,
                      color: isFuture ? Colors.transparent : null,
                    ),
                  ],
                ),
              ),
            ),
          )
              : Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Container(
                width: 45,
                height: 80,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: !isToday ? const Color(0xFF2F2F2F) : Colors.transparent,
                  gradient: isToday
                      ? SweepGradient(
                    colors: [
                      const Color(0xFFFFE100),
                      const Color(0xFFFFC917),
                      const Color(0xFFF8650C),
                      const Color(0xFFF00000),
                      const Color(0xFF8C0000),
                      const Color(0xFFFFE100),
                    ],
                    stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                    center: Alignment.center,
                    transform: GradientRotation(_rotationAngle),
                  )
                      : null,
                  border: Border.all(
                    color: isFuture ? Colors.white24 : moodColor,
                    width: 1.8,
                  ),
                  boxShadow: isToday
                      ? [
                    BoxShadow(
                      color: moodColor.withAlpha(153),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    )
                  ]
                      : [],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(date)[0],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${date.day}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Image.asset(
                        getMoodAsset(date),
                        width: 18,
                        height: 18,
                        color: isFuture ? Colors.transparent : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );

          return GestureDetector(
            onTap: () {
              if (!isFuture) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrackerLogScreen(
                      date: date,
                      initialEntry: entry,
                    ),
                  ),
                ).then((_) {
                  // Refresh the data when returning from TrackerLogScreen
                  _fetchEntriesForWeek();
                });
              }
            },
            child: calendarDay,
          );
        },
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _DashedBorderPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Create a slightly smaller rectangle to ensure the border is fully visible
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(12 - strokeWidth / 2),
    );

    final path = Path()..addRRect(rect);
    final dashedPath = _createDashedPath(path, dashWidth, dashSpace);
    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(Path source, double dashWidth, double dashSpace) {
    final Path dashed = Path();
    for (final PathMetric pathMetric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final next = distance + dashWidth;
        dashed.addPath(pathMetric.extractPath(distance, next), Offset.zero);
        distance = next + dashSpace;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}