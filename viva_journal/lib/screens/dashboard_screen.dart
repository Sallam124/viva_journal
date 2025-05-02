import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:viva_journal/database/database.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  List<double> moodData = [];
  List<DateTime> moodDates = [];
  String mostUsedMood = '';
  final List<String> emojiLabels = ['😢', '😐', '😊', '😄', '🤩'];
  bool isLoading = true;

  final List<List<String>> moodGroups = [
    ["Ecstatic", "Cheerful", "Excited", "Thrilled", "Overjoyed"],
    ["Happy", "Content", "Pleasant", "Delighted"],
    ["Neutral", "Fine", "Satisfied", "Meh", "Indifferent"],
    ["Angry", "Irritated", "Stressed", "Frustrated", "Fuming"],
    ["Down", "Distressed", "Anxious", "Defeated", "Exhausted"],
  ];

  @override
  void initState() {
    super.initState();
    loadMoodData();
  }

  int getMoodLevel(String moodText) {
    for (int i = 0; i < moodGroups.length; i++) {
      if (moodGroups[i].contains(moodText)) {
        return 5 - i;
      }
    }
    return 3;
  }

  Future<void> loadMoodData() async {
    try {
      final allEntries = await dbHelper.getEntriesPastWeek();

      print("Total entries: \${allEntries.length}");
      for (var e in allEntries) {
        print("ENTRY → type: \${e.type}, input: \${e.input}, date: \${e.date}");
      }

      setState(() {
        moodData = allEntries.map((entry) {
          final moodText = entry.mood?.toString() ?? '';
          return getMoodLevel(moodText).toDouble();
        }).toList();

        moodDates = allEntries.map((entry) {
          return entry.date is DateTime
              ? entry.date
              : DateTime.tryParse(entry.date.toString()) ?? DateTime.now();
        }).toList();

        final moodCount = <String, int>{};
        for (var entry in allEntries) {
          final mood = entry.mood;
          if (mood != null && mood.isNotEmpty) {
            moodCount[mood] = (moodCount[mood] ?? 0) + 1;
          }
        }
        mostUsedMood = moodCount.entries.isNotEmpty
            ? moodCount.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : 'N/A';

        isLoading = false;
      });
    } catch (e) {
<<<<<<< HEAD

      print("Error loading mood data: $e");
      print("Error loading mood data: \$e");

      print("Error loading mood data: \$e");

      print("Error loading mood data: \$e");
=======
      print("Error loading mood data: \$e");
>>>>>>> 68e0b18927f958f12491b2918f23b526b4c7d67d
      setState(() {
        isLoading = false;
      });
    }
  }

  double _calculateAverageMood() {
    return moodData.isNotEmpty
        ? moodData.reduce((a, b) => a + b) / moodData.length
        : 3;
  }

  @override
  Widget build(BuildContext context) {
    final double avg = _calculateAverageMood();
    final int avgMood = avg.round().clamp(1, 5);
    final String avgEmoji = emojiLabels[avgMood - 1];
    final String moodDisplay = mostUsedMood;

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
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                              height: 300,
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
                                          final index = value.toInt();
                                          if (index >= 0 && index < moodDates.length) {
                                            return Text(DateFormat('MM/dd').format(moodDates[index]));
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
                                          int mood = value.toInt().clamp(1, 5);
                                          return Text(
                                            emojiLabels[mood - 1],
                                            style: const TextStyle(fontSize: 20),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  gridData: FlGridData(show: true),
                                  borderData: FlBorderData(show: true),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: List.generate(
                                        moodData.length,
                                        (index) => FlSpot(index.toDouble(), moodData[index]),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                elevation: 4,
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(avgEmoji, style: const TextStyle(fontSize: 48)),
                                      const SizedBox(height: 8),
                                      const Text("Weekly Avg", style: TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                elevation: 4,
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.text_snippet, size: 40, color: Colors.indigo),
                                      const SizedBox(height: 8),
                                      const Text("Most Frequent Mood", style: TextStyle(fontSize: 14)),
                                      const SizedBox(height: 8),
                                      Text('⭐ ' + moodDisplay,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
