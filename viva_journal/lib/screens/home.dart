import 'package:flutter/material.dart';
import 'package:viva_journal/screens/settings_screen.dart';
import 'package:viva_journal/screens/dashboard_screen.dart';
import 'package:viva_journal/screens/calendar_screen.dart';
import 'package:viva_journal/screens/trackerlog_screen.dart';
import 'package:viva_journal/widgets/mini_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:viva_journal/database/database.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:viva_journal/screens/journal_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Home screen with a bottom navigation bar and a floating action button.
class HomeScreen extends StatefulWidget {
  final int initialIndex;  // Add initialIndex parameter
  const HomeScreen({super.key, this.initialIndex = 0});  // Default to 0 if not provided

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  String _selectedMoodFilter = 'all';
  String _selectedTagFilter = 'all';
  late AnimationController _glowController;
  late AnimationController _splashController;
  late Animation<double> _glowAnimation;
  late Animation<double> _splashAnimation;
  late double homeBarHeight;
  bool _isSplashAnimating = false;
  Offset? _splashPosition;
  double _homeBarOpacity = 1.0;  // Add opacity control
  double _floatingButtonOpacity = 1.0;  // Add opacity control
  String? _username;
  String? _profilePictureUrl;  // Add profile picture URL
  bool _hasNotifications = false;  // Add notification state
  int _streakCount = 0;
  double _averageMoodPercentage = 0.0;
  int _totalEntries = 0;
  Color _averageMoodColor = const Color(0xFFF8650C); // Default to Neutral

  final List<Map<String, dynamic>> moodGroups = [
    {
      'name': 'Group',
      'moods': ["Ecstatic", "Cheerful", "Excited", "Thrilled", "Overjoyed"],
      'color': const Color(0xFFFFE100),
    },
    {
      'name': 'Group',
      'moods': ["Happy", "Content", "Pleasant", "Cheerful", "Delighted"],
      'color': const Color(0xFFFFC917),
    },
    {
      'name': 'Group',
      'moods': ["Neutral", "Fine", "Satisfied", "Meh", "Indifferent"],
      'color': const Color(0xFFF8650C),
    },
    {
      'name': 'Group',
      'moods': ["Angry", "Irritated", "Stressed", "Frustrated", "Fuming"],
      'color': const Color(0xFFF00000),
    },
    {
      'name': 'Group',
      'moods': ["Down", "Distressed", "Anxious", "Defeated", "Exhausted"],
      'color': const Color(0xFF8C0000),
    },
  ];

  /// time-based greeting
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  /// Method to fetch username and profile picture from Firestore
  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _username = doc.data()?['username'] as String?;
          _profilePictureUrl = doc.data()?['profilePicture'] as String?;
          _hasNotifications = doc.data()?['hasNotifications'] as bool? ?? false;
        });
      }
    }
  }

  /// Method to build home content
  Widget _buildHomeContent() {
    final streakKey = GlobalKey();
    final totalEntriesKey = GlobalKey();
    final averageMoodKey = GlobalKey();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),  // Space for status bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: _profilePictureUrl != null
                              ? NetworkImage(_profilePictureUrl!)
                              : const AssetImage('assets/images/pfp.png') as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                              fontFamily: 'SF Pro Display',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_username != null)
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _username!,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      fontFamily: 'SF Pro Display',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Text(
                                  ' ✨',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _hasNotifications = false;
                  });
                },
                child: Stack(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      size: 28,
                      color: Colors.black,
                    ),
                    if (_hasNotifications)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          MiniCalendar(key: const ValueKey('mini_calendar')),
          const SizedBox(height: 32), // Increased space between calendar and blocks
          // Blocks Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBigBlock(
                key: streakKey,
                title: "Streak",
                color: const Color(0xFFF8650C),
                leftImage: Image.asset(
                  'assets/images/streak.gif',
                  width: 80,
                  height: 80,
                ),
                percentage: "$_streakCount",
                onTap: () {
                  // TODO: Handle Streak block tap
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildSmallBlock(
                      key: totalEntriesKey,
                      title: "Total Entries",
                      color: Colors.white,
                      iconPath: 'assets/images/your_calendar_icon.png',
                      subtitle: "$_totalEntries",
                      onTap: () {
                        // TODO: Handle Total Entries tap
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSmallBlock(
                      key: averageMoodKey,
                      title: "Average Mood",
                      color: _averageMoodColor,
                      iconPath: 'assets/images/your_mood_icon.png',
                      subtitle: "${_averageMoodPercentage.toStringAsFixed(0)}%",
                      onTap: () {
                        // TODO: Handle Average mood tap
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Add Entries List Section with Filters
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Entries',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'SF Pro Display',
                ),
              ),
              const SizedBox(height: 8),
              // Mood Group Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // All moods filter
                    GestureDetector(
                      onTap: () => setState(() => _selectedMoodFilter = 'all'),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedMoodFilter == 'all' ? Colors.black : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedMoodFilter == 'all' ? Colors.black : Colors.grey,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'All Moods',
                          style: TextStyle(
                            color: _selectedMoodFilter == 'all' ? Colors.white : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    // Mood group filters
                    ...moodGroups.map((group) => GestureDetector(
                      onTap: () => setState(() => _selectedMoodFilter = group['name']),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedMoodFilter == group['name']
                              ? group['color']
                              : group['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: group['color'],
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: SvgPicture.asset(
                                "assets/images/Star.svg",
                                colorFilter: ColorFilter.mode(
                                    _selectedMoodFilter == group['name'] ? Colors.white : group['color'],
                                    BlendMode.srcIn
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              group['name'],
                              style: TextStyle(
                                color: _selectedMoodFilter == group['name'] ? Colors.white : group['color'],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Tag Filter
              if (_selectedTagFilter != 'all')
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tag, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _selectedTagFilter,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => setState(() => _selectedTagFilter = 'all'),
                        child: const Icon(Icons.close, size: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: FutureBuilder<List<Entry>>(
                future: DatabaseHelper().getAllEntries(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No entries yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    );
                  }

                  // Apply filters
                  var filteredEntries = snapshot.data!;
                  if (_selectedMoodFilter != 'all') {
                    final selectedGroup = moodGroups.firstWhere(
                          (group) => group['name'] == _selectedMoodFilter,
                      orElse: () => {'moods': []},
                    );
                    filteredEntries = filteredEntries.where((entry) =>
                        selectedGroup['moods'].contains(entry.mood)
                    ).toList();
                  }
                  if (_selectedTagFilter != 'all') {
                    filteredEntries = filteredEntries.where((entry) =>
                    entry.tags != null && entry.tags!.contains(_selectedTagFilter)
                    ).toList();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100), // Add padding for the home bar
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      final entry = filteredEntries[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date, Mood, and Menu
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(entry.date),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      fontFamily: 'SF Pro Display',
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (entry.mood != null) ...[
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: SvgPicture.asset(
                                            "assets/images/Star.svg",
                                            colorFilter: ColorFilter.mode(
                                                entry.color ?? Colors.grey,
                                                BlendMode.srcIn
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          entry.mood!,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert),
                                        onSelected: (value) async {
                                          if (value == 'delete') {
                                            final confirmed = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Delete Entry'),
                                                content: const Text('Are you sure you want to delete this entry?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, true),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirmed == true) {
                                              try {
                                                await JournalState.deleteJournalData(entry.date);
                                                final formattedDate = DateFormat('yyyy-MM-dd').format(entry.date);
                                                logger.i('Deleting entry with formatted date: $formattedDate');
                                                final result = await DatabaseHelper().deleteEntry(entry.date);

                                                if (result > 0) {
                                                  if (mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Entry deleted successfully'),
                                                        duration: Duration(seconds: 2),
                                                      ),
                                                    );
                                                    setState(() {});
                                                  }
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Error deleting entry: $e'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          } else if (value == 'share') {
                                            await _shareJournalAsPDF(entry);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'share',
                                            child: Row(
                                              children: [
                                                Icon(Icons.share),
                                                SizedBox(width: 8),
                                                Text('Share as PDF'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Delete', style: TextStyle(color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (entry.title != null && entry.title!.isNotEmpty)
                                Text(
                                  entry.title!,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                ),
                              if (entry.content != null && entry.content!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  entry.content!.first['insert'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                ),
                              ],
                              if (entry.tags != null && entry.tags!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: entry.tags!.map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: (entry.color ?? Colors.grey).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: entry.color ?? Colors.grey,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _fetchUserData();
    _loadStreakData();
    _loadAverageMood();
    _loadTotalEntries();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _splashController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );

    _splashAnimation = CurvedAnimation(
      parent: _splashController,
      curve: Curves.easeInOut,
    );

    _glowController.repeat();

    _splashController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Delay the navigation slightly to ensure smooth transition
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => TrackerLogScreen(date: DateTime.now()),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            ).then((_) {
              if (mounted) {
                setState(() {
                  _isSplashAnimating = false;
                  _homeBarOpacity = 1.0;
                  _floatingButtonOpacity = 1.0;
                });
              }
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _splashController.dispose();
    super.dispose();
  }

  /// Handles navigation bar item selection.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Triggers animation and navigates to the tracker log screen.
  void _onFloatingButtonPressed(TapDownDetails details) {
    setState(() {
      _isSplashAnimating = true;
      _splashPosition = details.globalPosition;
      _homeBarOpacity = 0.0;  // Start fade out
      _floatingButtonOpacity = 0.0;  // Start fade out
      _splashController.forward(from: 0);
    });
  }

  Color _getGlowColor(double value) {
    final colorCount = moodGroups.length;
    final position = (value * colorCount).floor();
    final nextPosition = (position + 1) % colorCount;
    final progress = (value * colorCount) - position;

    return Color.lerp(
      moodGroups[position]['color'],
      moodGroups[nextPosition]['color'],
      progress,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Calculate responsive dimensions
    homeBarHeight = screenWidth * 0.2;  // Slightly smaller for better proportions
    double floatingButtonSize = screenWidth * 0.20;  // Proportional to screen width
    double horizontalPadding = screenWidth * 0.05;
    double floatingButtonBottomPadding = homeBarHeight * 0.4;
    double bottomPadding = screenHeight * 0.01;

    // Calculate icon sizes based on screen width
    double iconSize = screenWidth * 0.07;  // Responsive icon size
    double starSize = screenWidth * 0.04;  // Responsive star indicator size
    double iconTopPadding = homeBarHeight * 0.2;  // Proportional top padding

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          _selectedIndex == 0 ? _buildHomeContent() :
          _selectedIndex == 1 ? CalendarScreen() :
          _selectedIndex == 2 ? DashboardScreen() :
          const SettingsScreen(),

          if (_isSplashAnimating && _splashPosition != null)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _splashAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: SplashPainter(
                      position: _splashPosition!,
                      progress: _splashAnimation.value,
                      color: _getGlowColor(_glowController.value),
                    ),
                  );
                },
              ),
            ),

          // Bottom Navigation Bar
          Positioned(
            bottom: bottomPadding,
            left: horizontalPadding,
            right: horizontalPadding,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _homeBarOpacity,
              child: Container(
                height: homeBarHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(screenWidth * 0.05),  // Responsive border radius
                  image: DecorationImage(
                    image: AssetImage('assets/images/HomeBarBG.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: homeBarHeight * 0.1
                  ),
                  child: Row(
                    children: [
                      _buildNavItem(Icons.home, 0, iconSize, starSize, iconTopPadding),
                      const Spacer(),
                      _buildNavItem(Icons.calendar_today, 1, iconSize, starSize, iconTopPadding),
                      const Spacer(flex: 4),
                      _buildNavItem(Icons.bar_chart, 2, iconSize, starSize, iconTopPadding),
                      const Spacer(),
                      _buildNavItem(Icons.settings, 3, iconSize, starSize, iconTopPadding),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: floatingButtonBottomPadding),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _floatingButtonOpacity,
          child: _buildFloatingButton(floatingButtonSize),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// Builds navigation bar items with responsive sizes
  Widget _buildNavItem(IconData icon, int index, double iconSize, double starSize, double topPadding) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: SizedBox(
        height: homeBarHeight * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: Icon(
                icon,
                size: iconSize,
                color: _selectedIndex == index ? Colors.white : const Color(0xFF3C3C3C),
              ),
            ),
            if (_selectedIndex == index)
              Padding(
                padding: EdgeInsets.only(top: homeBarHeight * 0.02),
                child: Image.asset(
                  'assets/images/HBstar.png',
                  width: starSize,
                  height: starSize,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButton(double size) {
    return GestureDetector(
      onTapDown: _onFloatingButtonPressed,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          final glowColor = _getGlowColor(_glowController.value);

          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  glowColor.withAlpha(76),
                  glowColor.withAlpha(153),
                  glowColor.withAlpha(255),
                  glowColor.withAlpha(153),
                  glowColor.withAlpha(76),
                ],
                stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                transform: GradientRotation(_glowController.value * 2 * 3.14159),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(size * 0.05),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withAlpha(153),
                      blurRadius: size * 0.25,  // Responsive blur
                      spreadRadius: size * 0.04,  // Responsive spread
                    ),
                    BoxShadow(
                      color: glowColor.withAlpha(102),
                      blurRadius: size * 0.3,  // Responsive blur
                      spreadRadius: size * 0.06,  // Responsive spread
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/float_button.png',
                    width: size * 0.7,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper widget for big block
  Widget _buildBigBlock({
    required String title,
    required Color color,
    Widget? leftImage,
    required VoidCallback onTap,
    String? subtitle,
    String? percentage,
    required GlobalKey key,
  }) {
    return RepaintBoundary(
      key: key,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 160,
          width: 180,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(76, color.red, color.green, color.blue),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (leftImage != null)
                Positioned(
                  left: 16,
                  top: 50, // Moved down to center the GIF
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: leftImage,
                  ),
                ),
              Positioned(
                top: 16,
                left: 16,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
              ),
              if (percentage != null)
                Positioned(
                  left: 110,
                  top: 50,
                  child: Text(
                    percentage,
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                ),
              Positioned(
                top: 16,
                right: 16,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.open_in_new, color: Colors.white),
                  onSelected: (value) async {
                    if (value == 'share') {
                      final RenderBox box = key.currentContext!.findRenderObject() as RenderBox;
                      final image = await _captureWidget(box);
                      if (image != null) {
                        final tempDir = await getTemporaryDirectory();
                        final file = await File('${tempDir.path}/share.png').create();
                        await file.writeAsBytes(image);
                        await Share.shareXFiles(
                          [XFile(file.path)],
                          text: "Check out my ${title.toLowerCase()} on Viva Journal! 📝✨",
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share),
                          SizedBox(width: 8),
                          Text('Share Block'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for small block
  Widget _buildSmallBlock({
    required String title,
    required Color color,
    required String iconPath,
    required VoidCallback onTap,
    String? subtitle,
    required GlobalKey key,
  }) {
    return RepaintBoundary(
      key: key,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(76, color.red, color.green, color.blue),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 10,
                left: 12,
                right: 12,
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: color == Colors.white ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: color == Colors.white ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: color == Colors.white ? Colors.black : Colors.white,
                  ),
                  onSelected: (value) async {
                    if (value == 'share') {
                      final RenderBox box = key.currentContext!.findRenderObject() as RenderBox;
                      final image = await _captureWidget(box);
                      if (image != null) {
                        final tempDir = await getTemporaryDirectory();
                        final file = await File('${tempDir.path}/share.png').create();
                        await file.writeAsBytes(image);
                        await Share.shareXFiles(
                          [XFile(file.path)],
                          text: "Check out my ${title.toLowerCase()} on Viva Journal! 📝✨",
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share),
                          SizedBox(width: 8),
                          Text('Share Block'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Uint8List?> _captureWidget(RenderBox box) async {
    try {
      final boundary = box as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      logger.e('Error capturing widget: $e');
      return null;
    }
  }

  Future<void> _loadStreakData() async {
    final prefs = await SharedPreferences.getInstance();
    final lastOpened = prefs.getString('last_opened');
    final currentStreak = prefs.getInt('streak_count') ?? 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastOpened != null) {
      final lastDate = DateTime.parse(lastOpened);
      final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);

      if (lastDay.isBefore(today)) {
        // If last opened was yesterday, increment streak
        if (lastDay.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
          setState(() {
            _streakCount = currentStreak + 1;
          });
          await prefs.setInt('streak_count', _streakCount);
        } else {
          // If more than one day has passed, reset streak
          setState(() {
            _streakCount = 1;
          });
          await prefs.setInt('streak_count', 1);
        }
      } else {
        setState(() {
          _streakCount = currentStreak;
        });
      }
    } else {
      setState(() {
        _streakCount = 1;
      });
      await prefs.setInt('streak_count', 1);
    }

    await prefs.setString('last_opened', today.toIso8601String());
  }

  Future<void> _loadAverageMood() async {
    final entries = await DatabaseHelper().getAllEntries();
    if (entries.isEmpty) return;

    int totalMoodValue = 0;
    for (var entry in entries) {
      final moodIndex = moodGroups.indexWhere((group) =>
          group['moods'].contains(entry.mood)
      );
      if (moodIndex != -1) {
        totalMoodValue += moodIndex;
      }
    }

    final averageMoodIndex = totalMoodValue / entries.length;
    setState(() {
      _averageMoodPercentage = (averageMoodIndex / (moodGroups.length - 1)) * 100;
      _averageMoodColor = moodGroups[averageMoodIndex.round()]['color'];
    });
  }

  Future<void> _loadTotalEntries() async {
    final entries = await DatabaseHelper().getAllEntries();
    setState(() {
      _totalEntries = entries.length;
    });
  }

  Future<void> _shareJournalAsPDF(Entry entry) async {
    try {
      // Create a PDF document
      final pdf = pw.Document();

      // Add a page to the PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with date and mood
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      DateFormat('MMM dd, yyyy').format(entry.date),
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey,
                      ),
                    ),
                    if (entry.mood != null)
                      pw.Row(
                        children: [
                          pw.Text(
                            entry.mood!,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Title
                if (entry.title != null && entry.title!.isNotEmpty)
                  pw.Text(
                    entry.title!,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                pw.SizedBox(height: 10),

                // Content
                if (entry.content != null && entry.content!.isNotEmpty)
                  pw.Text(
                    entry.content!.first['insert'] ?? '',
                    style: pw.TextStyle(
                      fontSize: 14,
                    ),
                  ),
                pw.SizedBox(height: 20),

                // Tags
                if (entry.tags != null && entry.tags!.isNotEmpty)
                  pw.Wrap(
                    spacing: 8,
                    children: entry.tags!.map((tag) =>
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.grey100,
                            borderRadius: pw.BorderRadius.circular(20),
                            border: pw.Border.all(
                              color: PdfColors.grey,
                              width: 1,
                            ),
                          ),
                          child: pw.Text(
                            tag,
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.black,
                            ),
                          ),
                        ),
                    ).toList(),
                  ),
              ],
            );
          },
        ),
      );

      // Save the PDF to a temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/journal_entry.pdf');
      await file.writeAsBytes(await pdf.save());

      // Share the PDF file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: "My journal entry from ${DateFormat('MMM dd, yyyy').format(entry.date)} 📝",
      );
    } catch (e) {
      logger.e('Error generating PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class SplashPainter extends CustomPainter {
  final Offset position;
  final double progress;
  final Color color;

  SplashPainter({
    required this.position,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final radius = size.width * 2 * progress;
    canvas.drawCircle(position, radius, paint);
  }

  @override
  bool shouldRepaint(SplashPainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.progress != progress;
  }
}