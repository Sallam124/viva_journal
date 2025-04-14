import 'package:flutter/material.dart';
import '../database/database.dart'; // Import DatabaseHelper

class EntryScreen extends StatefulWidget {
  final DateTime date;

  const EntryScreen({Key? key, required this.date}) : super(key: key);

  @override
  _EntryScreenState createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final TextEditingController _contentController = TextEditingController();
  String _selectedMood = "Happy"; // Default mood

  // Method to save the mood entry to the database
  void _saveEntry() async {
    // Create a MoodEntry object from the user's input
    final moodEntry = MoodEntry(
      date: "${widget.date.year}-${widget.date.month}-${widget.date.day}", // Date in 'yyyy-MM-dd' format
      mood: _selectedMood,
      input: _contentController.text, // Text content entered by the user
    );

    try {
      // Insert the new mood entry into the database using insertMood from DatabaseHelper
      await DatabaseHelper().insertMood(moodEntry);

      // Once saved, pop the screen (return to the previous screen)
      Navigator.pop(context);
    } catch (e) {
      print('Error saving mood entry: $e');
      // Handle any errors here, like showing a toast or dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Entry")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Mood:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _selectedMood,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedMood = newValue!;
                });
              },
              items: ["Happy", "Sad", "Angry", "Calm", "Excited"]
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Text("Write about your day:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Type here...",
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveEntry, // Calls the _saveEntry method to save to DB
              child: Text("Save Entry"),
            ),
          ],
        ),
      ),
    );
  }
}
