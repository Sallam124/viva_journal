import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class EntryScreen extends StatefulWidget {
  final DateTime date;

  const EntryScreen({Key? key, required this.date}) : super(key: key);

  @override
  _EntryScreenState createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final TextEditingController _contentController = TextEditingController();
  String _selectedMood = "Happy"; // Default mood

  void _saveEntry() async {
    await DatabaseHelper.instance.insertEntry({
      'date': "${widget.date.year}-${widget.date.month}-${widget.date.day}",
      'mood': _selectedMood,
      'content': _contentController.text,
    });

    Navigator.pop(context); // Return to the previous screen
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
              onPressed: _saveEntry,
              child: Text("Save Entry"),
            ),
          ],
        ),
      ),
    );
  }
}
