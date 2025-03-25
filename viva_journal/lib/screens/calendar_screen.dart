import 'package:intl/intl.dart';
import 'package:viva_journal/screens/trackerlog_screen.dart';
import 'package:flutter/material.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late int selectedMonth;
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = now.month;
    selectedYear = now.year;
  }

  /// Helper to get the full month name (e.g., "March").
  String get monthName {
    return DateFormat('MMMM').format(DateTime(selectedYear, selectedMonth));
  }

  /// Go to previous month (handle December -> January).
  void _goToPreviousMonth() {
    setState(() {
      if (selectedMonth == 1) {
        selectedMonth = 12;
        selectedYear--;
      } else {
        selectedMonth--;
      }
    });
  }

  /// Go to next month (handle December -> January).
  void _goToNextMonth() {
    setState(() {
      if (selectedMonth == 12) {
        selectedMonth = 1;
        selectedYear++;
      } else {
        selectedMonth++;
      }
    });
  }

  /// Detect swipe direction: left swipe -> next month, right swipe -> previous month.
  void _onHorizontalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity == null) return;
    if (details.primaryVelocity! > 0) {
      _goToPreviousMonth();
    } else if (details.primaryVelocity! < 0) {
      _goToNextMonth();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the number of days in the selected month.
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
    // Calculate the first weekday offset (Sun=0, Mon=1, ..., Sat=6).
    final firstWeekday = DateTime(selectedYear, selectedMonth, 1).weekday % 7;

    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: Container(
          // Use Background_Calendar.png as the background.
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/Background_Calendar.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),
                // Row with arrow buttons and the month & year display.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      onPressed: _goToPreviousMonth,
                      icon: const ImageIcon(
                        AssetImage('assets/images/Left_arrow.png'),
                        color: Colors.black,
                        size: 70,
                      ),
                    ),
                    // Display month and year together.
                    Column(
                      children: [
                        Text(
                          monthName,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '$selectedYear',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: _goToNextMonth,
                      icon: const ImageIcon(
                        AssetImage('assets/images/Right_arrow.png'),
                        color: Colors.black,
                        size: 70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Layout for day names and day cells.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Column(
                      children: [
                        // Row of day names.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                              .map(
                                (day) => Text(
                              day,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          )
                              .toList(),
                        ),
                        // Grid of day cells.
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.only(top: 30),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: daysInMonth + firstWeekday,
                            itemBuilder: (context, index) {
                              // Create blank cells for days before the first weekday.
                              if (index < firstWeekday) {
                                return const SizedBox.shrink();
                              }
                              // Calculate the actual day number.
                              final day = index - firstWeekday + 1;

                              return GestureDetector(
                                onTap: () {
                                  // Create the selected date.
                                  final selectedDate = DateTime(selectedYear, selectedMonth, day);
                                  // Navigate to TrackerLogScreen with the selected date.
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TrackerLogScreen(
                                        // date: selectedDate,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.all(4.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$day',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
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
      ),
    );
  }
}
