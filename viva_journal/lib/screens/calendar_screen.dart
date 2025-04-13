import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:viva_journal/database/database.dart';
import 'package:viva_journal/screens/trackerlog_screen.dart';
import 'package:viva_journal/widgets/widgets.dart';
import 'package:viva_journal/screens/home_screen.dart';
import 'package:viva_journal/screens/settings_screen.dart';
import 'package:viva_journal/screens/dashboard_screen.dart';

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
        IconButton(
          icon: const Icon(Icons.arrow_left, size: 40),
          onPressed: () {
            int newMonth = selectedMonth == 1 ? 12 : selectedMonth - 1;
            int newYear = selectedMonth == 1 ? selectedYear - 1 : selectedYear;
            onMonthChanged(newMonth);
            onYearChanged(newYear);
          },
        ),
        Column(
          children: [
            Text(
              _getMonthName(selectedMonth - 1),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              "$selectedYear",
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
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

  String _getMonthName(int monthIndex) {
    const List<String> monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December'
    ];
    if (monthIndex < 0 || monthIndex > 11) return '';
    return monthNames[monthIndex];
  }
}

class DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final String moodAsset;
  final VoidCallback onTap;

  const DayCell({
    Key? key,
    required this.day,
    required this.isToday,
    required this.moodAsset,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: isToday
                ? BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.withOpacity(0.8),
            )
                : null,
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 18,
                color: isToday ? Colors.white : Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Image.asset(moodAsset, height: 22, width: 22),
        ],
      ),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  CalendarScreen({Key? key}) : super(key: key);

  @override
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

  Future<String> getMoodForDayFromDb(int day, {required int month, required int year}) async {
    final String dateStr = DateFormat('d-M-yyyy').format(DateTime(year, month, day));
    final moodEntry = await DatabaseHelper().getMoodForDay(dateStr);
    if (moodEntry != null) {
      return moodEntry.mood;
    }
    return 'NoMood';
  }

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

  Future<void> _fetchMoods() async {
    final data = await _getMoodsForMonthData(month: _selectedMonth, year: _selectedYear);
    setState(() {
      _cachedMoodData[currentKey] = data;
    });
  }

  Future<void> _fetchMoodsForCurrentMonthIfNeeded() async {
    if (!_cachedMoodData.containsKey(currentKey)) {
      await _fetchMoods();
    }
  }

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

  Future<void> _fetchAndPrefetch() async {
    await _fetchMoodsForCurrentMonthIfNeeded();
    await _prefetchAdjacentMonths();
  }

  void _updateCacheForDay(int day, String mood) {
    setState(() {
      _cachedMoodData.putIfAbsent(currentKey, () => {})[day] = mood;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final int daysInMonth = _getDaysInMonth(_selectedMonth, _selectedYear);
    final int firstWeekday = DateTime(_selectedYear, _selectedMonth, 1).weekday % 7;
    final DateTime now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.white,
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
            color: Colors.white,
            image: DecorationImage(
              image: AssetImage('assets/images/Background_2.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 0),
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
                const SizedBox(height: 60),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glassmorphic Blur Background (centered behind both widgets)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            width: MediaQuery.of(context).size.width ,
                            height: MediaQuery.of(context).size.height * 0.56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color.fromARGB(100, 255, 255, 255),
                                  Color.fromARGB(20, 0, 0, 0),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.6),
                                width: 2.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Actual Month Traversal + Calendar Days
                    Column(
                      children: [
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
                        const SizedBox(height: 5),
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
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: GridView.builder(

                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(top: 10),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                              final int day = index - firstWeekday + 1;
                              if (_cachedMoodData[currentKey]?.containsKey(day) ?? false) {
                                final String mood = _cachedMoodData[currentKey]![day]!;
                                final String moodAsset = getMoodForDay(mood);
                                final bool isToday = (_selectedYear == now.year &&
                                    _selectedMonth == now.month &&
                                    day == now.day);
                                return DayCell(
                                  day: day,
                                  isToday: isToday,
                                  moodAsset: moodAsset,
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => TrackerLogScreen()),
                                    );
                                    if (result == true) {
                                      await _fetchMoods();
                                    }
                                  },
                                );
                              } else {
                                return FutureBuilder<String>(
                                  future: getMoodForDayFromDb(day,
                                      month: _selectedMonth, year: _selectedYear),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2.0));
                                    } else if (snapshot.hasError) {
                                      return const Center(
                                          child: Icon(Icons.error, color: Colors.red));
                                    } else if (snapshot.hasData) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        _updateCacheForDay(day, snapshot.data!);
                                      });
                                      final String moodAsset =
                                      getMoodForDay(snapshot.data!);
                                      final bool isToday = (_selectedYear == now.year &&
                                          _selectedMonth == now.month &&
                                          day == now.day);
                                      return DayCell(
                                        day: day,
                                        isToday: isToday,
                                        moodAsset: moodAsset,
                                        onTap: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) => TrackerLogScreen()),
                                          );
                                          if (result == true) {
                                            await _fetchMoods();
                                          }
                                        },
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
