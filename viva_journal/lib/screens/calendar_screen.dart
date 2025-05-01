// ignore_for_file: deprecated_member_use

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
        IconButton(
          icon: const Icon(Icons.arrow_left, size: 40),
          onPressed: () {
            int newYear = selectedYear - 1;
            onYearChanged(newYear);
          },
        ),
        Column(
          children: [
            Text(
              "$selectedMonth - $selectedYear",
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.arrow_right, size: 40),
          onPressed: () {
            int newYear = selectedYear + 1;
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
  final bool isWeekend;

  const DayCell({
    super.key,
    required this.day,
    required this.isToday,
    required this.moodAsset,
    required this.onTap,
    this.isWeekend = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: isToday
                ? BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.withOpacity(0.5),
            )
                : isWeekend
                ? const BoxDecoration(
              shape: BoxShape.circle,
              color: Color.fromARGB(102, 255, 255, 255),
            )
                : null,
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 16,
                color: isToday ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Image.asset(moodAsset, height: 22, width: 22),
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
  bool _isLoading = false;

  final List<List<String>> emotionProgressions = [
    ["Ecstatic", "Cheerful", "Excited", "Thrilled", "Overjoyed"],
    ["Happy", "Content", "Pleasant", "Cheerful", "Delighted"],
    ["Neutral", "Fine", "Satisfied", "Meh", "Indifferent"],
    ["Angry", "Irritated", "Stressed", "Frustrated", "Fuming"],
    ["Down", "Distressed", "Anxious", "Defeated", "Exhausted"],
  ];

  late AnimationController _controller;

  String get monthName => DateFormat('MMMM').format(DateTime(_selectedYear, _selectedMonth));

  int _getDaysInMonth(int month, int year) => DateTime(year, month + 1, 0).day;

  String get currentKey => '$_selectedYear-$_selectedMonth';

  String _cacheKey(int month, int year) => '$year-$month';

  Future<void> _forceRefresh() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _cachedMoodData.clear();
    });

    try {
      await _fetchAndPrefetch();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    _forceRefresh();
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
    _forceRefresh();
  }

  Future<String> getMoodForDayFromDb(int day, {required int month, required int year}) async {
    try {
      DateTime date = DateTime(year, month, day);
      final entry = await DatabaseHelper().getEntryForDate(date);
      return entry?.mood ?? 'NoMood';
    } catch (e) {
      debugPrint('Error fetching mood: $e');
      return 'NoMood';
    }
  }

  String getMoodAsset(String mood) {
    if (mood == 'NoMood') return 'assets/images/Star0.png';
    if (emotionProgressions[0].contains(mood)) return 'assets/images/Star1.png';
    if (emotionProgressions[1].contains(mood)) return 'assets/images/Star2.png';
    if (emotionProgressions[2].contains(mood)) return 'assets/images/Star3.png';
    if (emotionProgressions[3].contains(mood)) return 'assets/images/Star4.png';
    if (emotionProgressions[4].contains(mood)) return 'assets/images/Star5.png';
    return 'assets/images/Star0.png';
  }

  Future<Map<int, String>> _getMoodsForMonthData({required int month, required int year}) async {
    final int days = _getDaysInMonth(month, year);
    List<Future<MapEntry<int, String>>> futures = [];

    for (int day = 1; day <= days; day++) {
      futures.add(
          getMoodForDayFromDb(day, month: month, year: year)
              .then((mood) => MapEntry(day, mood))
              .catchError((e) {
            debugPrint('Error loading day $day: $e');
            return MapEntry(day, 'NoMood');
          })
      );
    }

    final entries = await Future.wait(futures);
    return Map.fromEntries(entries);
  }

  Future<void> _fetchMoods() async {
    if (!mounted) return;

    try {
      final monthData = await _getMoodsForMonthData(
        month: _selectedMonth,
        year: _selectedYear,
      );

      if (mounted) {
        setState(() {
          _cachedMoodData[currentKey] = monthData;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cachedMoodData[currentKey] = {};
        });
      }
    }
  }

  Future<void> _prefetchAdjacentMonths() async {
    int prevMonth = _selectedMonth == 1 ? 12 : _selectedMonth - 1;
    int prevYear = _selectedMonth == 1 ? _selectedYear - 1 : _selectedYear;
    int nextMonth = _selectedMonth == 12 ? 1 : _selectedMonth + 1;
    int nextYear = _selectedMonth == 12 ? _selectedYear + 1 : _selectedYear;

    final String prevKey = _cacheKey(prevMonth, prevYear);
    if (!_cachedMoodData.containsKey(prevKey)) {
      _getMoodsForMonthData(month: prevMonth, year: prevYear).then((data) {
        if (mounted) {
          setState(() {
            _cachedMoodData[prevKey] = data;
          });
        }
      }).catchError((e) {
        debugPrint('Error prefetching previous month: $e');
      });
    }

    final String nextKey = _cacheKey(nextMonth, nextYear);
    if (!_cachedMoodData.containsKey(nextKey)) {
      _getMoodsForMonthData(month: nextMonth, year: nextYear).then((data) {
        if (mounted) {
          setState(() {
            _cachedMoodData[nextKey] = data;
          });
        }
      }).catchError((e) {
        debugPrint('Error prefetching next month: $e');
      });
    }
  }

  Future<void> _fetchAndPrefetch() async {
    await _fetchMoodsForCurrentMonthIfNeeded();
    await _prefetchAdjacentMonths();
  }

  Future<void> _fetchMoodsForCurrentMonthIfNeeded() async {
    if (!_cachedMoodData.containsKey(currentKey)) {
      await _fetchMoods();
    }
  }

  void _goHome() {
    setState(() {
      _selectedMonth = DateTime.now().month;
      _selectedYear = DateTime.now().year;
    });
    _forceRefresh();
  }

  Future<void> _fetchMoodForDate(DateTime date) async {
    try {
      final entry = await DatabaseHelper().getEntryForDate(date);
      if (mounted) {
        setState(() {
          final key = '${date.year}-${date.month}';
          _cachedMoodData.remove(key); // Clear cache for this month
          _cachedMoodData[key] ??= {};
          _cachedMoodData[key]![date.day] = entry?.mood ?? 'NoMood';
        });
      }
    } catch (e) {
      debugPrint('Error fetching mood for date: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _forceRefresh();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showFutureDateMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("You can't change journals for future dates."),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int daysInMonth = _getDaysInMonth(_selectedMonth, _selectedYear);
    final int firstWeekday = DateTime(_selectedYear, _selectedMonth, 1).weekday % 7;
    final DateTime now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! > 0) {
            setState(() => _selectedYear++);
            _forceRefresh();
          } else if (details.primaryVelocity! < 0) {
            setState(() => _selectedYear--);
            _forceRefresh();
          }
        },
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          if (details.primaryVelocity! > 0) {
            _goToPreviousMonth();
          } else if (details.primaryVelocity! < 0) {
            _goToNextMonth();
          }
        },
        child: Stack(
          children: [
            Container(
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
                                monthName,
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
                                icon: const ImageIcon(AssetImage('assets/images/small_left_arrow.png'), size: 34),
                                onPressed: () => setState(() => _selectedYear--),
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
                                icon: const ImageIcon(AssetImage('assets/images/small_right_arrow.png'), size: 34),
                                onPressed: () => setState(() => _selectedYear++),
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
                      child: _isLoading
                          ? const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                          : GridView.builder(
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
                          if (index < firstWeekday) return const SizedBox.shrink();
                          final int day = index - firstWeekday + 1;
                          final date = DateTime(_selectedYear, _selectedMonth, day);
                          final isWeekend = date.weekday == DateTime.friday || date.weekday == DateTime.saturday;
                          final isToday = _selectedYear == now.year && _selectedMonth == now.month && day == now.day;

                          return DayCell(
                            day: day,
                            isToday: isToday,
                            moodAsset: getMoodAsset(_cachedMoodData[currentKey]?[day] ?? 'NoMood'),
                            onTap: () async {
                              if (date.isAfter(DateTime.now())) {
                                _showFutureDateMessage();
                                return;
                              }
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => TrackerLogScreen(date: date)),
                              );
                              if (result == true) {
                                await _fetchMoodForDate(date);
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
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}