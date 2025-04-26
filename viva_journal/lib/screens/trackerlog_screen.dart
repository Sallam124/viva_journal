import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
// import 'calendar_screen.dart';
import 'package:viva_journal/screens/home.dart';  // Update import for HomeScreen

class TrackerLogScreen extends StatefulWidget {
  final DateTime date;
  TrackerLogScreen({super.key, DateTime? date}) : date = date ?? DateTime.now();

  @override
  _TrackerLogScreenState createState() => _TrackerLogScreenState();
}

class _TrackerLogScreenState extends State<TrackerLogScreen> {
  int _currentIndex = 0;
  Set<String> selectedTags = {};  // Changed from single String to Set for multiple selection
  List<int> emotionLevels = [1, 1, 1, 1, 1]; // Track intensity levels for each emotion

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
                      color: selectedColor.withOpacity(0.2),
                      boxShadow: [
                        BoxShadow(
                          color: selectedColor.withOpacity(0.4),
                          blurRadius: 50,
                          spreadRadius: 120,
                        ),
                      ],
                    ),
                  ),
                  CarouselSlider.builder(
                    itemCount: emotions.length,
                    options: CarouselOptions(
                      height: 220,
                      enlargeCenterPage: true,
                      autoPlay: false,
                      enableInfiniteScroll: true,
                      viewportFraction: 0.6,
                      enlargeStrategy: CenterPageEnlargeStrategy.zoom,
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
                    }).toList(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// **"Do you have something in mind?" Input**
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Do you have something in mind?", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const SizedBox(height: 10),

              SizedBox(
                height: 150,
                child: TextField(
                  maxLines: 6,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black,
                    hintText: "Type what's in your mind",
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: selectedColor, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: selectedColor, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: selectedColor, width: 2),
                    ),
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
                  onPressed: () {},
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