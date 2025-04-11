  import 'package:flutter/material.dart';
  import 'package:intl/intl.dart'; // For date manipulation
  import 'package:viva_journal/database/database.dart';
  import 'package:viva_journal/screens/trackerlog_screen.dart';
  import 'package:viva_journal/widgets/widgets.dart'; // Import your widgets

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
          // Left Arrow Button to move to the previous month
          IconButton(
            icon: const Icon(Icons.arrow_left, size: 40),  // Bigger arrows
            onPressed: () {
              // Navigate to the previous month, and adjust the year if needed
              int newMonth = selectedMonth == 1 ? 12 : selectedMonth - 1;
              int newYear = selectedMonth == 1 ? selectedYear - 1 : selectedYear;
              onMonthChanged(newMonth);
              onYearChanged(newYear);
            },
          ),
          // Month Title with Year in the middle (e.g., "March 2025")
          Column(
            children: [
              Text(
                "${_getMonthName(selectedMonth - 1)}", // Month in black
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,  // Month text color black
                ),
              ),
              Text(
                " $selectedYear", // Year in grey
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,  // Year text color grey
                ),
              ),
            ],
          ),
          // Right Arrow Button to move to the next month
          IconButton(
            icon: const Icon(Icons.arrow_right, size: 40),  // Bigger arrows
            onPressed: () {
              // Navigate to the next month, and adjust the year if needed
              int newMonth = selectedMonth == 12 ? 1 : selectedMonth + 1;
              int newYear = selectedMonth == 12 ? selectedYear + 1 : selectedYear;
              onMonthChanged(newMonth);
              onYearChanged(newYear);
            },
          ),
        ],
      );
    }

    String _getMonthName(int monthIndex) {
      const monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June', 'July',
        'August', 'September', 'October', 'November', 'December'
      ];
      return monthNames[monthIndex];
    }
  }

  // DayGrid widget to display days in a grid format
  class DayGrid extends StatefulWidget {
    final int daysInMonth;

    const DayGrid({Key? key, required this.daysInMonth}) : super(key: key);

    @override
    _DayGridState createState() => _DayGridState();
  }

  class _DayGridState extends State<DayGrid> {
    int? _hoveredDay; // Track which day is hovered

    @override
    Widget build(BuildContext context) {
      return GridView.builder(
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7, // 7 days of the week
          childAspectRatio: 1.3, // Adjust width to make the boxes smaller
        ),
        itemCount: widget.daysInMonth,
        itemBuilder: (context, index) {
          int day = index + 1; // Day number

          return MouseRegion(
            onEnter: (_) {
              setState(() {
                _hoveredDay = day; // Set hovered day
              });
            },
            onExit: (_) {
              setState(() {
                _hoveredDay = null; // Reset hovered day
              });
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hoveredDay == day ? Colors.blue.withOpacity(0.5) : Colors.transparent, // Highlight circle when hovered
              ),
              child: Center(
                child: Text(
                  day.toString(), // Display day number
                  style: const TextStyle(
                    color: Colors.black, // Black text for the day number
                    fontSize: 18, // Adjust the font size to fit inside the cell
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  // CalendarScreen widget to display the whole calendar view
  class CalendarScreen extends StatefulWidget {
    const CalendarScreen({super.key});

    @override
    _CalendarScreenState createState() => _CalendarScreenState();
  }

  class _CalendarScreenState extends State<CalendarScreen> {
    int _selectedMonth = DateTime.now().month; // Initial selected month
    int _selectedYear = DateTime.now().year;   // Initial selected year

    final List<List<String>> emotionProgressions = [
      ["Ecstatic", "Cheerful", "Excited", "Thrilled", "Overjoyed"], // Yellow Star
      ["Happy", "Content", "Pleasant", "Cheerful", "Delighted"],    // Yellow Star 1
      ["Neutral", "Fine", "Satisfied", "Meh", "Indifferent"],        // Mid Star
      ["Angry", "Irritated", "Stressed", "Frustrated", "Fuming"],    // Red Star
      ["Down", "Distressed", "Anxious", "Defeated", "Exhausted"],    // Red Star 1
    ];

    String get monthName {
      return DateFormat('MMMM').format(DateTime(_selectedYear, _selectedMonth));
    }

    // Function to get the number of days in the selected month
    int _getDaysInMonth(int month, int year) {
      return DateTime(year, month + 1, 0).day; // Get last day of the month
    }

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

    Future<String> getMoodForDayFromDb(int day) async {
      final dateStr = DateFormat('d-M-yyyy').format(DateTime(_selectedYear, _selectedMonth, day));

      // Ensure that the date format matches the format used in the database
      final moodEntry = await DatabaseHelper().getMoodForDay(dateStr);

      if (moodEntry != null) {
        return moodEntry.mood;
      }
      return 'NoMood';  // Return 'NoMood' if not found
    }

    String getMoodForDay(String mood) {
      if (mood == 'NoMood') {
        return 'assets/images/empty_star.png';  // Empty star for no mood entry
      }

      // Check mood and map it to the appropriate star image
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
      return 'assets/images/Star0.png';  // Default to empty star if mood doesn't match any category
    }

    @override
    Widget build(BuildContext context) {
      final daysInMonth = _getDaysInMonth(_selectedMonth, _selectedYear);
      final firstWeekday = DateTime(_selectedYear, _selectedMonth, 1).weekday % 7;

      return Scaffold(
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
              image: DecorationImage(
                image: AssetImage('assets/images/Background_Calendar.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 29),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _goToPreviousMonth,
                        icon: const ImageIcon(
                          AssetImage('assets/images/Left_arrow.png'),
                          color: Colors.white,
                          size: 70,
                        ),
                      ),
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
                  const SizedBox(height: 15),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        child: Column(
                          children: [
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
                            SizedBox(
                              height: 300,
                              child: GridView.builder(
                                padding: const EdgeInsets.only(top: 30),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  childAspectRatio: 1.0,
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
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator());
                                      }
                                      if (snapshot.hasData) {
                                        final moodOfDay = snapshot.data!;
                                        final moodStar = getMoodForDay(moodOfDay);

                                        return GestureDetector(
                                          onTap: () {
                                            final selectedDate = DateTime(_selectedYear, _selectedMonth, day);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => TrackerLogScreen(),
                                              ),
                                            );
                                          },
                                          child: Column(
                                            children: [
                                              Text(
                                                '$day',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white,
                                                ),
                                              ),
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
