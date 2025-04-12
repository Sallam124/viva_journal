import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:viva_journal/database/database.dart';
import 'package:viva_journal/screens/trackerlog_screen.dart';
import 'package:viva_journal/widgets/widgets.dart';
import 'package:viva_journal/screens/home.dart';

// MonthSelector widget: Displays navigation arrows and current month/year.
class MonthSelector extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;

  const MonthSelector({
    Key? key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onMonthChanged,
    required this.onYearChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left arrow button to navigate to the previous month.
        IconButton(
          icon: const Icon(Icons.arrow_left, size: 40),
          onPressed: () {
            int newMonth = selectedMonth == 1 ? 12 : selectedMonth - 1;
            int newYear = selectedMonth == 1 ? selectedYear - 1 : selectedYear;
            onMonthChanged(newMonth);
            onYearChanged(newYear);
          },
        ),
        // Displays the current month name and year.
        Column(
          children: [
            Text(
              "${_getMonthName(selectedMonth - 1)}",
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              " $selectedYear",
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        // Right arrow button to navigate to the next month.
        IconButton(
          icon: const Icon(Icons.arrow_right, size: 40),
          onPressed: () {
            int newMonth = selectedMonth == 12 ? 1 : selectedMonth + 1;
            int newYear = selectedMonth == 12 ? selectedYear + 1 : selectedYear;
            onMonthChanged(newMonth);
            onYearChanged(newYear);
          },
        ),
      ],
    );
  }

  // Helper function: Returns month name based on the index.
  String _getMonthName(int monthIndex) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[monthIndex];
  }
}

// DayGrid widget: Displays a grid of day numbers for the month.
class DayGrid extends StatefulWidget {
  final int daysInMonth;

  const DayGrid({Key? key, required this.daysInMonth}) : super(key: key);

  @override
  _DayGridState createState() => _DayGridState();
}

class _DayGridState extends State<DayGrid> {
  // Track today's date.
  final DateTime _today = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      // Use 7 columns (days in a week) with a fixed child aspect ratio.
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.3,
      ),
      itemCount: widget.daysInMonth,
      itemBuilder: (context, index) {
        int day = index + 1;
        // Check if this day is today.
        final bool isToday = (day == _today.day &&
            _today.month == _today.month &&
            _today.year == _today.year);

        return Container(
          margin: const EdgeInsets.all(10.0),
          child: Center(
            // If this day is today, add a subtle circular highlight behind the number.
            child: Container(
              padding: const EdgeInsets.all(6.0),
              decoration: isToday
                  ? BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.3),
              )
                  : null,
              child: Text(
                '$day',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// CalendarScreen widget: Displays the full calendar (month name, navigation, days with mood stars).
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // Define mood progression tiers.
  final List<List<String>> emotionProgressions = [
    ["Ecstatic", "Cheerful", "Excited", "Thrilled", "Overjoyed"],
    ["Happy", "Content", "Pleasant", "Cheerful", "Delighted"],
    ["Neutral", "Fine", "Satisfied", "Meh", "Indifferent"],
    ["Angry", "Irritated", "Stressed", "Frustrated", "Fuming"],
    ["Down", "Distressed", "Anxious", "Defeated", "Exhausted"],
  ];

  // Returns the current month name.
  String get monthName {
    return DateFormat('MMMM').format(DateTime(_selectedYear, _selectedMonth));
  }

  // Returns the total number of days for the given month and year.
  int _getDaysInMonth(int month, int year) {
    return DateTime(year, month + 1, 0).day;
  }

  // Moves to the previous month.
  void _goToPreviousMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
    });
  }

  // Moves to the next month.
  void _goToNextMonth() {
    setState(() {
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth++;
      }
    });
  }

  // Retrieves the mood for a specific day from the database.
  Future<String> getMoodForDayFromDb(int day) async {
    final dateStr =
    DateFormat('d-M-yyyy').format(DateTime(_selectedYear, _selectedMonth, day));
    final moodEntry = await DatabaseHelper().getMoodForDay(dateStr);
    if (moodEntry != null) {
      return moodEntry.mood;
    }
    return 'NoMood';
  }

  // Returns the corresponding star asset based on the mood string.
  String getMoodForDay(String mood) {
    if (mood == 'NoMood') {
      return 'assets/images/Star0.png';
    }
    if (emotionProgressions[0].contains(mood)) {
      return 'assets/images/Star1.png';
    } else if (emotionProgressions[1].contains(mood)) {
      return 'assets/images/Star2.png';
    } else if (emotionProgressions[2].contains(mood)) {
      return 'assets/images/Star3.png';
    } else if (emotionProgressions[3].contains(mood)) {
      return 'assets/images/Star4.png';
    } else if (emotionProgressions[4].contains(mood)) {
      return 'assets/images/Star5.png';
    }
    return 'assets/images/Star0.png';
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total days in the selected month.
    final daysInMonth = _getDaysInMonth(_selectedMonth, _selectedYear);
    // Determine starting weekday for the month to insert blank cells.
    final firstWeekday = DateTime(_selectedYear, _selectedMonth, 1).weekday % 7;
    final DateTime now = DateTime.now();

    return Scaffold(
      // Enable horizontal swipe gesture for month navigation.
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! > 0) {
            _goToPreviousMonth();
          } else if (details.primaryVelocity! < 0) {
            _goToNextMonth();
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            // Set background image for calendar.
            image: DecorationImage(
              image: AssetImage('assets/images/Background_Calendar.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 0),
                // Top row with large arrows and month/year display.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Big left arrow for previous month.
                    IconButton(
                      onPressed: _goToPreviousMonth,
                      icon: const ImageIcon(
                        AssetImage('assets/images/Left_arrow.png'),
                        color: Colors.white,
                        size: 70,
                      ),
                    ),
                    // Center column: month name and year.
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
                          '$_selectedYear',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    // Big right arrow for next month.
                    IconButton(
                      onPressed: _goToNextMonth,
                      icon: const ImageIcon(
                        AssetImage('assets/images/Right_arrow.png'),
                        color: Colors.white,
                        size: 70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7.9),
                // Second row with small navigation arrows and month name.
                Padding(
                  padding: const EdgeInsets.only(right: 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const ImageIcon(
                          AssetImage('assets/images/small_left_arrow.png'),
                          size: 30,
                        ),
                        onPressed: _goToPreviousMonth,
                      ),
                      Text(
                        monthName,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const ImageIcon(
                          AssetImage('assets/images/small_right_arrow.png'),
                          size: 30,
                        ),
                        onPressed: _goToNextMonth,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                // Row for weekday labels.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                      .map(
                        (day) => Text(
                      day,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  )
                      .toList(),
                ),
                // Calendar grid displaying day numbers and mood stars.
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Column(
                        children: [
                          // Removed fixed-height container.
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(top: 10),
                            gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              childAspectRatio: 1.0,
                              mainAxisSpacing: 12.0,
                              crossAxisSpacing: 2.0,
                            ),
                            itemCount: daysInMonth + firstWeekday,
                            itemBuilder: (context, index) {
                              if (index < firstWeekday) {
                                return const SizedBox.shrink();
                              }
                              final day = index - firstWeekday + 1;
                              return FutureBuilder<String>(
                                future: getMoodForDayFromDb(day),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (snapshot.hasData) {
                                    final moodOfDay = snapshot.data!;
                                    final moodStar = getMoodForDay(moodOfDay);

                                    // Check if the current cell represents today's date.
                                    final bool isToday = (_selectedYear == now.year &&
                                        _selectedMonth == now.month &&
                                        day == now.day);

                                    return GestureDetector(
                                      onTap: () {
                                        final selectedDate = DateTime(
                                          _selectedYear,
                                          _selectedMonth,
                                          day,
                                        );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => TrackerLogScreen(),
                                          ),
                                        );
                                      },
                                      // Build cell: display day number (highlighted if today) with extra spacing before the mood star.
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Day number container with circular highlight if today.
                                          Container(
                                            padding: const EdgeInsets.all(2.0),
                                            decoration: isToday
                                                ? BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white
                                                  .withOpacity(0.4),
                                            )
                                                : null,
                                            child: Text(
                                              '$day',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          // Display the mood star image.
                                          Image.asset(moodStar),
                                        ],
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              );
                            },
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
    );
  }
}
