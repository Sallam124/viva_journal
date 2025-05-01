import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:viva_journal/database/database.dart';
import 'package:viva_journal/screens/trackerlog_screen.dart';

class MonthSelector extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;

  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Button to go to the previous year
        IconButton(
          icon: const Icon(Icons.arrow_left, size: 40),
          onPressed: () {
            int newYear = selectedYear - 1; // Decrease the year
            onYearChanged(newYear);
          },
        ),
        Column(
          children: [
            // Display the selected year and month
            Text(
              "$selectedMonth - $selectedYear", // Display both month and year
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        // Button to go to the next year
        IconButton(
          icon: const Icon(Icons.arrow_right, size: 40),
          onPressed: () {
            int newYear = selectedYear + 1; // Increase the year
            onYearChanged(newYear);
          },
        ),
      ],
    );
  }
}

class DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final String moodAsset;
  final VoidCallback onTap;
  final bool isWeekend; // Added flag to highlight weekends

  const DayCell({
    super.key,
    required this.day,
    required this.isToday,
    required this.moodAsset,
    required this.onTap,
    this.isWeekend = false, // Default is false
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circle for the day number with fixed size
          Container(
            width: 30,  // Smaller width for the circle around the day (changed)
            height: 30, // Smaller height for the circle (changed)
            alignment: Alignment.center,
            decoration: isToday
                ? BoxDecoration(
              shape: BoxShape.circle,
              // ignore: deprecated_member_use
              color: Colors.grey.withOpacity(0.5),
            )
                : isWeekend // Highlight weekends with a different color
                ? BoxDecoration(
                shape: BoxShape.circle,
                color: const Color.fromARGB(102, 255, 255, 255)
            )//            )
                : null,
            child: Text(
              '$day', // Display the day number
              style: TextStyle(
                fontSize: 16, // Adjusted size to fit better in smaller circle (changed)
                color: isToday ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Image.asset(moodAsset, height: 22, width: 22), // Display mood icon (slightly smaller)
        ],
      ),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  final Map<String, Map<int, String>> _cachedMoodData = {};

  final List<List<String>> emotionProgressions = [
    ["Ecstatic", "Cheerful", "Excited", "Thrilled", "Overjoyed"],
    ["Happy", "Content", "Pleasant", "Cheerful", "Delighted"],
    ["Neutral", "Fine", "Satisfied", "Meh", "Indifferent"],
    ["Angry", "Irritated", "Stressed", "Frustrated", "Fuming"],
    ["Down", "Distressed", "Anxious", "Defeated", "Exhausted"],
  ];

  late AnimationController _controller;

  String get monthName {
    return DateFormat('MMMM').format(DateTime(_selectedYear, _selectedMonth));
  }

  int _getDaysInMonth(int month, int year) {
    return DateTime(year, month + 1, 0).day;
  }

  String get currentKey => '$_selectedYear-$_selectedMonth';

  String _cacheKey(int month, int year) => '$year-$month';

  // Function to navigate to the previous month
  void _goToPreviousMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
    });
    _fetchAndPrefetch();
  }

  // Function to navigate to the next month
  void _goToNextMonth() {
    setState(() {
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth++;
      }
    });
    _fetchAndPrefetch();
  }

  // Fetch mood for the day from the database
  Future<String> getMoodForDayFromDb(int day, {required int month, required int year}) async {
    DateTime date = DateTime(year, month, day);
    final entry = await DatabaseHelper().getEntryForDate(date);
    return entry?.mood ?? 'NoMood';
  }

  // Determine mood icon based on the stored mood
  String getMoodAsset(String mood) {
    if (mood == 'NoMood') return 'assets/images/Star0.png';
    if (emotionProgressions[0].contains(mood)) return 'assets/images/Star1.png';
    if (emotionProgressions[1].contains(mood)) return 'assets/images/Star2.png';
    if (emotionProgressions[2].contains(mood)) return 'assets/images/Star3.png';
    if (emotionProgressions[3].contains(mood)) return 'assets/images/Star4.png';
    if (emotionProgressions[4].contains(mood)) return 'assets/images/Star5.png';
    return 'assets/images/Star0.png';
  }

  // Get mood data for all days in a month from the database
  Future<Map<int, String>> _getMoodsForMonthData({required int month, required int year}) async {
    final int days = _getDaysInMonth(month, year);
    List<Future<MapEntry<int, String>>> futures = [];
    for (int day = 1; day <= days; day++) {
      futures.add(getMoodForDayFromDb(day, month: month, year: year)
          .then((mood) => MapEntry(day, mood)));
    }
    final List<MapEntry<int, String>> entries = await Future.wait(futures);
    return Map.fromEntries(entries);
  }

  // Fetch moods and store them in the cache
  Future<void> _fetchMoods() async {
    List<Future<String>> futures = [];
    for (int day = 1; day <= _getDaysInMonth(_selectedMonth, _selectedYear); day++) {
      futures.add(getMoodForDayFromDb(day, month: _selectedMonth, year: _selectedYear));
    }

    List<String> moods = await Future.wait(futures);
    if (mounted) {
      setState(() {
        String currentKey = '$_selectedYear-$_selectedMonth';
        _cachedMoodData[currentKey] = {};
        for (int day = 1; day <= _getDaysInMonth(_selectedMonth, _selectedYear); day++) {
          _cachedMoodData[currentKey]![day] = moods[day - 1];
        }
      });
    }
  }

  // Prefetch mood data for adjacent months
  Future<void> _prefetchAdjacentMonths() async {
    int prevMonth, prevYear, nextMonth, nextYear;
    if (_selectedMonth == 1) {
      prevMonth = 12;
      prevYear = _selectedYear - 1;
    } else {
      prevMonth = _selectedMonth - 1;
      prevYear = _selectedYear;
    }
    final String prevKey = _cacheKey(prevMonth, prevYear);
    if (!_cachedMoodData.containsKey(prevKey)) {
      _getMoodsForMonthData(month: prevMonth, year: prevYear).then((data) {
        setState(() {
          _cachedMoodData[prevKey] = data;
        });
      });
    }
    if (_selectedMonth == 12) {
      nextMonth = 1;
      nextYear = _selectedYear + 1;
    } else {
      nextMonth = _selectedMonth + 1;
      nextYear = _selectedYear;
    }
    final String nextKey = _cacheKey(nextMonth, nextYear);
    if (!_cachedMoodData.containsKey(nextKey)) {
      _getMoodsForMonthData(month: nextMonth, year: nextYear).then((data) {
        setState(() {
          _cachedMoodData[nextKey] = data;
        });
      });
    }
  }

  // Fetch moods and prefetch adjacent months
  Future<void> _fetchAndPrefetch() async {
    await _fetchMoodsForCurrentMonthIfNeeded();
    await _prefetchAdjacentMonths();
  }

  // Update the cache with the mood for the selected day

  // Check if the current month's mood data is already fetched, if not, fetch it
  Future<void> _fetchMoodsForCurrentMonthIfNeeded() async {
    if (!_cachedMoodData.containsKey(currentKey)) {
      await _fetchMoods();
    }
  }

  // Initialize the controller and fetch data
  @override
  void initState() {
    super.initState();
    _fetchAndPrefetch();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Bring the user back to the current month and year
  void _goHome() {
    setState(() {
      _selectedMonth = DateTime.now().month;
      _selectedYear = DateTime.now().year;
    });
    _fetchAndPrefetch();
  }

  Future<void> _fetchMoodForDate(DateTime date) async {
    final entry = await DatabaseHelper().getEntryForDate(date);
    if (mounted) {
      setState(() {
        String currentKey = '${date.year}-${date.month}';
        if (!_cachedMoodData.containsKey(currentKey)) {
          _cachedMoodData[currentKey] = {};
        }
        _cachedMoodData[currentKey]![date.day] = entry?.mood ?? 'NoMood';
      });
    }
  }

  // Build the UI
  @override
  Widget build(BuildContext context) {
    final int daysInMonth = _getDaysInMonth(_selectedMonth, _selectedYear);
    final int firstWeekday = DateTime(_selectedYear, _selectedMonth, 1).weekday % 7;
    final DateTime now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          // Handle vertical drag for year navigation (up for next year, down for previous year)
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! > 0) {
            setState(() {
              _selectedYear++; // Swipe up to go to next year
            });
            _fetchAndPrefetch();
          } else if (details.primaryVelocity! < 0) {
            setState(() {
              _selectedYear--; // Swipe down to go to previous year
            });
            _fetchAndPrefetch();
          }
        },
        onHorizontalDragEnd: (details) {
          // Handle horizontal drag for month navigation (left for next month, right for previous month)
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! > 0) {
            _goToPreviousMonth(); // Swipe left to go to previous month
          } else if (details.primaryVelocity! < 0) {
            _goToNextMonth(); // Swipe right to go to next month
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            image: DecorationImage(
              image: AssetImage('assets/images/Background_Calendar.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
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
                    Center(
                      child: Column(
                        children: [
                          Text(
                            monthName, // Display the month name
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
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
                const SizedBox(height: 5),

                Padding(
                  padding: const EdgeInsets.only(left: 13),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // FloatingActionButton on the left
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: FloatingActionButton(
                          onPressed: _goHome,
                          mini: true,
                          backgroundColor: Colors.blue,
                          child: const Icon(Icons.home, size: 20),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const ImageIcon(
                              AssetImage('assets/images/small_left_arrow.png'),
                              size: 34,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedYear--;
                              });
                            },
                          ),
                          Text(
                            "$_selectedYear",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          IconButton(
                            icon: const ImageIcon(
                              AssetImage('assets/images/small_right_arrow.png'),
                              size: 34,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedYear++;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                      .map((day) => Text(
                    day,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ))
                      .toList(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 1.0,
                      mainAxisSpacing: 14.0,
                      crossAxisSpacing: 0,
                    ),
                    itemCount: daysInMonth + firstWeekday,
                    itemBuilder: (context, index) {
                      if (index < firstWeekday) {
                        return const SizedBox.shrink();
                      }
                      final int day = index - firstWeekday + 1;
                      bool isWeekend = false;

                      // Highlight Friday and Saturday
                      if (DateTime(_selectedYear, _selectedMonth, day).weekday == DateTime.friday ||
                          DateTime(_selectedYear, _selectedMonth, day).weekday == DateTime.saturday) {
                        isWeekend = true;
                      }

                      bool isToday = (_selectedYear == now.year && _selectedMonth == now.month && day == now.day);
                      return DayCell(
                        day: day,
                        isToday: isToday,
                        moodAsset: getMoodAsset(_cachedMoodData[currentKey]?[day] ?? 'NoMood'),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TrackerLogScreen(date: DateTime(_selectedYear, _selectedMonth, day))),
                          );
                          if (result == true) {
                            await _fetchMoodForDate(DateTime(_selectedYear, _selectedMonth, day));
                          }
                        },
                        isWeekend: isWeekend,
                      );
                    },
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
