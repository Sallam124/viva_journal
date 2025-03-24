import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date manipulation
import 'package:viva_journal/widgets/widgets.dart';

// MonthSelector widget to display the current month and year with navigation buttons
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

  // Function to get the number of days in the selected month
  int _getDaysInMonth(int month, int year) {
    return DateTime(year, month + 1, 0).day; // Get last day of the month
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _getDaysInMonth(_selectedMonth, _selectedYear);

    return Scaffold(
      body: Stack(
        children: [
          // Background image positioned to cover the entire screen
          Positioned.fill(
            child: Image.asset(
              'assets/images/Background_Calendar.png', // Your glassy background
              fit: BoxFit.cover,
            ),
          ),
          // Content on top of the background
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(50.0),
                child: MonthSelector(
                  selectedMonth: _selectedMonth,
                  selectedYear: _selectedYear,
                  onMonthChanged: (month) {
                    setState(() {
                      _selectedMonth = month;
                    });
                  },
                  onYearChanged: (year) {
                    setState(() {
                      _selectedYear = year;
                    });
                  },
                ),
              ),
              // Move the grid down inside the box
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 90), // Add padding to move the grid down
                  child: DayGrid(daysInMonth: daysInMonth), // Display days grid
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
