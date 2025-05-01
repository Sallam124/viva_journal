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
<<<<<<< Updated upstream
=======
  Entry? highlightEntry;
>>>>>>> Stashed changes
  final List<String> emojiLabels = ['😟', '🤬', '😐', '😊', '😁'];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMoodData();
  }

  Future<void> loadMoodData() async {
    try {
      final allEntries = await dbHelper.getEntriesPastWeek();

<<<<<<< Updated upstream
      setState(() {
        moodData = allEntries.map((entry) {
          // Map the mood string to a number (ensure it's a valid double)
          return double.tryParse(entry.mood) ?? 3; // Default to 3 if parsing fails
        }).toList();

        moodDates = allEntries.map((entry) {
          // Parse date (ensure the date format is consistent with your data)
          return DateTime.tryParse(entry.date) ?? DateTime.now();
        }).toList();
=======
      if (allEntries.isEmpty) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      List<double> tempMoodData = allEntries.map((entry) {
        if (entry.mood == null) return 3.0;

        final List<List<String>> emotionProgressions = [
          ["Down", "Distressed", "Anxious", "Defeated", "Exhausted"],
          ["Angry", "Irritated", "Stressed", "Frustrated", "Fuming"],
          ["Neutral", "Fine", "Satisfied", "Meh", "Indifferent"],
          ["Happy", "Content", "Pleasant", "Cheerful", "Delighted"],
          ["Ecstatic", "Cheerful", "Excited", "Thrilled", "Overjoyed"],
        ];

        for (int i = 0; i < emotionProgressions.length; i++) {
          if (emotionProgressions[i].contains(entry.mood)) {
            return (i + 1).toDouble();
          }
        }

        return 3.0;
      }).toList();
>>>>>>> Stashed changes

      List<DateTime> tempDates = allEntries.map((e) => e.date).toList();

      int maxIndex = 0;
      for (int i = 1; i < tempMoodData.length; i++) {
        if (tempMoodData[i] > tempMoodData[maxIndex]) {
          maxIndex = i;
        }
      }

      setState(() {
        moodData = tempMoodData;
        moodDates = tempDates;
        highlightEntry = allEntries[maxIndex];
        isLoading = false;
      });
    } catch (e) {
      print("Error loading mood data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

<<<<<<< Updated upstream
  /// Method to calculate the average mood
  double _calculateAverageMood() {
    return moodData.isNotEmpty
        ? moodData.reduce((a, b) => a + b) / moodData.length
        : 3; // Default to 3 if no data
  }

  /// Method to get the best day of the week based on mood
  String _bestDayOfWeek() {
    if (moodDates.isEmpty) return "N/A";

    Map<int, List<double>> dayMoodMap = {};

    for (int i = 0; i < moodDates.length; i++) {
      int weekday = moodDates[i].weekday;
      dayMoodMap.putIfAbsent(weekday, () => []);
      dayMoodMap[weekday]!.add(moodData[i]);
    }

    int bestDay = 1;
    double bestAvg = 0;

    dayMoodMap.forEach((day, moods) {
      double avg = moods.reduce((a, b) => a + b) / moods.length;
      if (avg > bestAvg) {
        bestAvg = avg;
        bestDay = day;
      }
    });

    return DateFormat.E().format(DateTime.utc(2020, 1, bestDay + 5)); // Return the day of the week with the best mood
  }

  @override
  Widget build(BuildContext context) {
    final double avg = _calculateAverageMood();
=======
  @override
  Widget build(BuildContext context) {
    final double avg =
    moodData.isNotEmpty ? moodData.reduce((a, b) => a + b) / moodData.length : 3.0;
>>>>>>> Stashed changes
    final int avgMood = avg.round().clamp(1, 5);
    final String avgEmoji = emojiLabels[avgMood - 1];

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
                                getTitlesWidget: (value, _) {
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
                                getTitlesWidget: (value, _) {
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
                                    (index) => FlSpot(
                                  index.toDouble(),
                                  moodData[index],
                                ),
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
              /// Highlights: Weekly Average + Best Day
=======
              /// Weekly Avg Mood
>>>>>>> Stashed changes
              Expanded(
                flex: 1,
                child: Row(
                  children: [
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
                              Text(avgEmoji, style: const TextStyle(fontSize: 48)),
                              const SizedBox(height: 8),
                              const Text("Weekly Avg", style: TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

<<<<<<< Updated upstream
                    /// Best Day Highlight
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
                              const Icon(Icons.star, size: 48, color: Colors.amber),
                              const SizedBox(height: 8),
                              Text(
                                "Best Day:\n${_bestDayOfWeek()}",
                                style: const TextStyle(fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ],
=======
              /// Highlights Section
              Expanded(
                flex: 1, // Reduced size here for highlights section
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Happiest Day of the Week",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
>>>>>>> Stashed changes
                          ),
                          const SizedBox(height: 8),
                          if (highlightEntry == null)
                            const Text("No data available for highlights."),
                          if (highlightEntry != null) ...[
                            Text(
                              "Date: ${DateFormat('yyyy-MM-dd').format(highlightEntry!.date)}",
                              style: const TextStyle(fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 8),
                            Text("Mood: ${highlightEntry!.mood ?? 'No Mood'}"),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
