import 'dart:io';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'calendar_screen.dart';
import 'package:viva_journal/screens/home.dart';  // Update import for HomeScreen
import 'package:viva_journal/screens/journal_screen.dart';  // Added import for JournalScreen
import 'package:viva_journal/database/database.dart';

class TrackerLogScreen extends StatefulWidget {
  final DateTime date;
  final Entry? initialEntry;

  TrackerLogScreen({
    super.key,
    DateTime? date,
    this.initialEntry,
  }) : date = date ?? DateTime.now();

  @override
  TrackerLogScreenState createState() => TrackerLogScreenState();
}

class TrackerLogScreenState extends State<TrackerLogScreen> {
  int _currentIndex = 0;
  Set<String> selectedTags = {};
  List<int> emotionLevels = [1, 1, 1, 1, 1];
  String? _selectedMood;
  JournalData? _journalData;
  final CarouselSliderController _carouselController = CarouselSliderController();

  final List<List<String>> emotionProgressions = [
    ["Ecstatic", "Cheerful", "Excited", "Thrilled", "Overjoyed"],
    ["Happy", "Content", "Pleasant", "Cheerful", "Delighted"],
    ["Neutral", "Fine", "Satisfied", "Meh", "Indifferent"],
    ["Angry", "Irritated", "Stressed", "Frustrated", "Fuming"],
    ["Down", "Distressed", "Anxious", "Defeated", "Exhausted"],
  ];

  final List<Color> baseColors = [
    Color(0xFFFFE100), // Bright Yellow
    Color(0xFFFFC917), // Yellow
    Color(0xFFF8650C), // Orange
    Color(0xFFF00000), // Red
    Color(0xFF8C0000), // Dark Red
  ];

  List<String> get emotions {
    return List.generate(emotionProgressions.length, (index) {
      return emotionProgressions[index][emotionLevels[index] - 1]; // Changed to -1 to avoid index out of bounds
    });
  }

  List<Color> get colors {
    return baseColors.asMap().map((index, color) {
      // For yellow and light yellow, make it brighter instead of darker
      if (index == 0 || index == 1) {
        double factor = 0.15 * (emotionLevels[index] - 1);
        return MapEntry(index, Color.lerp(color, Colors.white, factor)!);
      } else {
        // For other colors, keep the darkening effect
        double factor = 0.15 * (emotionLevels[index] - 1);
        return MapEntry(index, Color.lerp(color, Colors.black, factor)!);
      }
    }).values.toList();
  }

  List<String> tags = ["Work", "Music", "Family Time", "Exercise"];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() async {
    if (widget.initialEntry != null) {
      final entry = widget.initialEntry!;
      _selectedMood = entry.mood;

      // Find the index of the mood in the emotion progressions
      for (int i = 0; i < emotionProgressions.length; i++) {
        if (emotionProgressions[i].contains(entry.mood)) {
          _currentIndex = i;
          // Find the level of the mood
          emotionLevels[i] = emotionProgressions[i].indexOf(entry.mood!) + 1;
          break;
        }
      }

      // Load tags
      if (entry.tags != null) {
        selectedTags = Set<String>.from(entry.tags!);
      }

      // Load journal data
      if (entry.content != null && entry.title != null) {
        _journalData = JournalData(
          title: entry.title!,
          content: entry.content!,
          drawingPoints: entry.drawingPoints ?? [],
          attachments: entry.mediaPaths?.map((path) => InteractiveMedia(
            file: File(path),
            isVideo: path.toLowerCase().endsWith('.mp4'),
            position: const Offset(100, 100),
            size: 200.0,
            angle: 0.0,
          )).toList() ?? [],
        );
        JournalState.saveJournalData(widget.date, _journalData!);
      }

      // Update the state to reflect the loaded data
      setState(() {});
    }
  }

  void _increaseEmotionLevel(int index) {
    setState(() {
      if (emotionLevels[index] < 5) {
        emotionLevels[index]++; // Increase level up to 5
      } else {
        emotionLevels[index] = 1; // Reset to 1 if it reaches 5
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat("d MMM, yy | E").format(widget.date);
    Color selectedColor = colors[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          formattedDate,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(initialIndex: 1),  // 1 is the calendar index
                ),
                    (route) => false,  // Remove all previous routes
              );
            },
            icon: const Icon(Icons.calendar_today, color: Colors.white),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                "How you feeling today",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 10),

              /// **Carousel Slider with Background Blur Circle**
              Stack(
                alignment: Alignment.center,
                children: [
                  // Big blur circle in the background
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    height: 1,
                    width: 1,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selectedColor.withAlpha(51),  // 0.2 * 255 ≈ 51
                      boxShadow: [
                        BoxShadow(
                          color: selectedColor.withAlpha(102),  // 0.4 * 255 ≈ 102
                          blurRadius: 50,
                          spreadRadius: 120,
                        ),
                      ],
                    ),
                  ),
                  CarouselSlider.builder(
                    carouselController: _carouselController,
                    itemCount: emotions.length,
                    options: CarouselOptions(
                      height: 220,
                      enlargeCenterPage: true,
                      autoPlay: false,
                      enableInfiniteScroll: true,
                      viewportFraction: 0.6,
                      enlargeStrategy: CenterPageEnlargeStrategy.zoom,
                      initialPage: _currentIndex,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                    ),
                    itemBuilder: (context, index, realIndex) {
                      return GestureDetector(
                        onTap: () {
                          if (_currentIndex == index) {
                            _increaseEmotionLevel(index);
                          } else {
                            setState(() {
                              _currentIndex = index;
                            });
                          }
                        },
                        child: EmotionStar(
                          emotion: emotions[index],
                          color: colors[index],
                          isSelected: _currentIndex == index,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text("Tap to increase emotion", style: TextStyle(color: Colors.white)),

              const SizedBox(height: 20),

              /// **"What were you doing?" Section**
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("What were you doing?", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const SizedBox(height: 10),

              /// **Scrollable Tags List with Custom Tag Option**
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    /// **"Add Custom Tag" Button** - Moved to the left
                    GestureDetector(
                      onTap: _showCustomTagDialog,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey, width: 2),
                        ),
                        child: Image.asset(
                          'assets/images/Add_tag.png',
                          height: 16,
                          width: 16,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),

                    ...tags.map((tag) {
                      bool isSelected = selectedTags.contains(tag);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedTags.remove(tag);
                            } else {
                              selectedTags.add(tag);
                            }
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? selectedColor : Colors.grey, width: 2),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(color: isSelected ? selectedColor : Colors.white),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// **"Do you have something in mind?" Input**
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Do you have something in mind?", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JournalScreen(
                        date: widget.date,
                        color: colors[_currentIndex],
                        initialData: _journalData,
                      ),
                    ),
                  ).then((_) async {
                    // Refresh journal data after returning from JournalScreen
                    _journalData = await JournalState.getJournalData(widget.date);
                    setState(() {});
                  });
                },
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selectedColor, width: 2),
                  ),
                  child: FutureBuilder<JournalData?>(
                    future: JournalState.getJournalData(widget.date),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }

                      final journalData = snapshot.data;
                      if (journalData == null || journalData.content.isEmpty) {
                        return Center(
                          child: Text(
                            "Tap to write in your journal",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }

                      // Show preview of the content
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              journalData.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                journalData.content.map((op) => op['insert']?.toString() ?? '').join(''),
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// **Submit Button**
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _handleSubmit,
                  child: const Text("Submit", style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// **Show Custom Tag Dialog**
  void _showCustomTagDialog() {
    TextEditingController customTagController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text("Add Custom Tag", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: customTagController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter a tag",
              hintStyle: TextStyle(color: Colors.grey.shade500),
              border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel", style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (customTagController.text.trim().isNotEmpty) {
                        tags.insert(0, customTagController.text.trim());
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Add", style: TextStyle(color: Colors.green)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _handleSubmit() async {
    final journalData = await JournalState.getJournalData(widget.date);
    if (journalData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something in your journal first')),
      );
      return;
    }

    final entry = Entry(
      type: 'journal',
      date: widget.date,
      mood: emotions[_currentIndex],
      tags: selectedTags.toList(),
      title: journalData.title,
      content: journalData.content,
      drawingPoints: journalData.drawingPoints,
      mediaPaths: journalData.attachments.map((a) => a.file.path).toList(),
      color: colors[_currentIndex],
    );

    final db = DatabaseHelper();

    // Check if an entry already exists for this date
    final existingEntry = await db.getEntryForDate(widget.date);
    if (existingEntry != null) {
      await db.updateEntry(entry);
    } else {
      await db.insertEntry(entry);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Journal entry saved successfully!')),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
    );
  }
}

/// **Emotion Star Widget**
class EmotionStar extends StatelessWidget {
  final String emotion;
  final Color color;
  final bool isSelected;

  const EmotionStar({super.key, required this.emotion, required this.color, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 10),
      curve: Curves.easeOut,
      width: isSelected ? 180 : 120,
      height: isSelected ? 180 : 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          /// **SVG Star Shape**
          SvgPicture.asset(
            "assets/images/Star.svg",
            height: isSelected ? 180 : 120,
            width: isSelected ? 180 : 120,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),

          /// **Emotion Label**
          Text(
            emotion.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: isSelected ? 22 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}