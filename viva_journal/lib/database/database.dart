import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

// Define the model for the mood entry
class MoodEntry {
  int? id;
  String mood;
  String date; // Format: 'day-month-year'
  String input; // Text or Path to image/audio

  MoodEntry({
    this.id,
    required this.mood,
    required this.date,
    required this.input,
  });

  // Convert a MoodEntry into a map for storing in the database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mood': mood,
      'date': date,
      'input': input,
    };
  }

  // Convert a map into a MoodEntry
  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      id: map['id'],
      mood: map['mood'],
      date: map['date'],
      input: map['input'],
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  // Get the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/mood_tracker.db';

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Create the mood table if it doesn't exist
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE moods(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mood TEXT,
        date TEXT,
        input TEXT
      )
    ''');
  }

  // Insert a new mood entry
  Future<int> insertMood(MoodEntry moodEntry) async {
    final db = await database;
    return await db.insert('moods', moodEntry.toMap());
  }

  // Get all mood entries
  Future<List<MoodEntry>> getAllMoods() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('moods');
    return List.generate(maps.length, (i) {
      return MoodEntry.fromMap(maps[i]);
    });
  }

  // Get mood for a specific day
  Future<MoodEntry?> getMoodForDay(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'moods',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (maps.isNotEmpty) {
      return MoodEntry.fromMap(maps.first);
    }
    return null;
  }

  // Update mood for a specific day
  Future<int> updateMood(MoodEntry moodEntry) async {
    final db = await database;
    return await db.update(
      'moods',
      moodEntry.toMap(),
      where: 'date = ?',
      whereArgs: [moodEntry.date],
    );
  }

  // Delete mood entry for a specific day
  Future<int> deleteMood(String date) async {
    final db = await database;
    return await db.delete(
      'moods',
      where: 'date = ?',
      whereArgs: [date],
    );
  }
}
