import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
<<<<<<< Updated upstream
import '../database/database.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
=======
import 'package:viva_journal/database_helper.dart'; // ✅ path based on your structure

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);
>>>>>>> Stashed changes

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
<<<<<<< Updated upstream
  final dbHelper = DatabaseHelper();
  final List<String> emojiLabels = ['😢', '😐', '😊', '😄', '🤩'];
  List<MoodEntry> moodEntries = [];
=======
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<double> moodData = [];
  List<DateTime> moodDates = [];
  final List<String> emojiLabels = ['😢', '😐', '😊', '😄', '🤩'];
  final String lastWeekPicPath = '/storage/emulated/0/Download/sample.jpg';
  bool isLoading = true;
>>>>>>> Stashed changes

  @override
  void initState() {
    super.initState();
<<<<<<< Updated upstream
    _loadData();
  }

  Future<void> _loadData() async {
    final now = DateTime.now();
    final List<MoodEntry> result = [];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final formattedDate = date.toIso8601String().substring(0, 10);
      final mood = await dbHelper.getMoodForDay(formattedDate);

      if (mood != null && double.tryParse(mood.mood) != null && double.parse(mood.mood) > 0) {
        result.add(mood);
      }
    }

    setState(() {
      moodEntries = result;
    });
=======
    loadMoodData();
  }

  Future<void> loadMoodData() async {
    try {
      final allEntries = await dbHelper.getEntries();
      final entries = allEntries.take(7).toList(); // last 7

      setState(() {
        moodData = entries
            .map((e) => double.tryParse(e['mood'] ?? '3') ?? 3)
            .toList();
        moodDates = entries
            .map((e) => DateTime.tryParse(e['date'] ?? '') ?? DateTime.now())
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error loading mood data: $e");
      setState(() {
        isLoading = false;
      });
    }
>>>>>>> Stashed changes
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
    if (moodEntries.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Dashboard'),
          backgroundColor: Colors.black87,
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/background.png',
                fit: BoxFit.cover,
              ),
            ),
            const Center(
              child: Text(
                'No mood data yet.\nAdd entries to view your chart.',
                style: TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    final moodValues = moodEntries.map((e) => double.parse(e.mood)).toList();
    final moodDates = moodEntries.map((e) => DateTime.parse(e.date)).toList();

    final avg = moodValues.fold(0.0, (a, b) => a + b) / moodValues.length;
    final avgEmoji = emojiLabels[avg.round().clamp(1, 5) - 1];

    final latestImage = moodEntries
        .lastWhere((e) => e.input.endsWith('.jpg') || e.input.endsWith('.png'), orElse: () => MoodEntry(mood: '0', date: '', input: ''))
        .input;
=======
    final double avg = moodData.isNotEmpty
        ? moodData.reduce((a, b) => a + b) / moodData.length
        : 3;
    final int avgMood = avg.round().clamp(1, 5);
    final String avgEmoji = emojiLabels[avgMood - 1];
>>>>>>> Stashed changes

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/background.png',
            fit: BoxFit.cover,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text("Dashboard"),
            backgroundColor: Colors.black87,
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              /// Mood Graph
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: LineChart(
                        LineChartData(
                          minY: 1,
                          maxY: 5,
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
<<<<<<< Updated upstream
                                  final index = value.toInt();
                                  if (index >= 0 && index < moodDates.length) {
                                    return Text(DateFormat('MM/dd').format(moodDates[index]));
=======
                                  final int index = value.toInt();
                                  if (index >= 0 &&
                                      index < moodDates.length) {
                                    return Text(DateFormat('MM/dd')
                                        .format(moodDates[index]));
>>>>>>> Stashed changes
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
<<<<<<< Updated upstream
                                  final mood = value.toInt().clamp(1, 5);
                                  return Text(emojiLabels[mood - 1], style: const TextStyle(fontSize: 20));
=======
                                  int mood =
                                  value.toInt().clamp(1, 5);
                                  return Text(
                                    emojiLabels[mood - 1],
                                    style: const TextStyle(fontSize: 20),
                                  );
>>>>>>> Stashed changes
                                },
                              ),
                            ),
                          ),
                          gridData: FlGridData(show: true),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(
<<<<<<< Updated upstream
                                moodValues.length,
                                    (i) => FlSpot(i.toDouble(), moodValues[i]),
=======
                                moodData.length,
                                    (index) => FlSpot(
                                    index.toDouble(), moodData[index]),
>>>>>>> Stashed changes
                              ),
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 3,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

<<<<<<< Updated upstream
              /// Bottom widgets
=======
              /// Bottom Half: Mood & Image
>>>>>>> Stashed changes
              Expanded(
                flex: 1,
                child: Row(
                  children: [
<<<<<<< Updated upstream
                    /// Emoji card
=======
                    /// Avg mood
>>>>>>> Stashed changes
                    Expanded(
                      child: Card(
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(avgEmoji,
                                  style:
                                  const TextStyle(fontSize: 48)),
                              const SizedBox(height: 8),
                              const Text("Weekly Avg",
                                  style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
<<<<<<< Updated upstream

                    /// Image card
=======
                    /// Image from last week
>>>>>>> Stashed changes
                    Expanded(
                      child: Card(
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: kIsWeb
<<<<<<< Updated upstream
                              ? const Center(child: Text("Image not supported on Web"))
                              : File(latestImage).existsSync()
                              ? Image.file(File(latestImage), fit: BoxFit.cover)
                              : const Center(child: Text("No image found")),
=======
                              ? const Center(
                              child:
                              Text('Image not supported on Web'))
                              : File(lastWeekPicPath).existsSync()
                              ? Image.file(File(lastWeekPicPath),
                              fit: BoxFit.cover)
                              : const Center(
                              child: Text('No image found')),
>>>>>>> Stashed changes
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
<<<<<<< Updated upstream
 
=======
>>>>>>> Stashed changes
