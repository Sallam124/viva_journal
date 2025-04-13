import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

// Define the model for the mood entry
class MoodEntry {
  int? id;
  String mood;
  String date; // ISO 8601 format for better date handling
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
    final path = '${directory.path}/journal.db';

    return await openDatabase(
      path,
      version: 2, // Increased version for schema migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Handle schema upgrades
    );
  }

  // Create the moods table if it doesn't exist
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

  // Handle schema upgrades (e.g., when you add new columns or tables)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Example: Adding a new column (if needed)
      await db.execute(''' 
        ALTER TABLE moods ADD COLUMN newColumn TEXT
      ''');
    }
  }

  // Insert a new mood entry
  Future<int> insertMood(MoodEntry moodEntry) async {
    try {
      final db = await database;
      return await db.insert('moods', moodEntry.toMap());
    } catch (e) {
      print('Error inserting mood: $e');
      rethrow; // Rethrow the error or return a custom error code
    }
  }

  // Get all mood entries with pagination (limit and offset)
  Future<List<MoodEntry>> getMoodsPage(int offset, int limit) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'moods',
        limit: limit,
        offset: offset,
      );
      return List.generate(maps.length, (i) => MoodEntry.fromMap(maps[i]));
    } catch (e) {
      print('Error fetching moods: $e');
      return []; // Return an empty list in case of error
    }
  }

  // Get mood for a specific day (by date)
  Future<MoodEntry?> getMoodForDay(String date) async {
    try {
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
    } catch (e) {
      print('Error fetching mood for day: $e');
      return null;
    }
  }

  // Update mood for a specific day
  Future<int> updateMood(MoodEntry moodEntry) async {
    try {
      final db = await database;
      return await db.update(
        'moods',
        moodEntry.toMap(),
        where: 'date = ?',
        whereArgs: [moodEntry.date],
      );
    } catch (e) {
      print('Error updating mood: $e');
      return 0; // Return 0 if no rows were updated
    }
  }

  // Delete mood entry for a specific day
  Future<int> deleteMood(String date) async {
    try {
      final db = await database;
      return await db.delete(
        'moods',
        where: 'date = ?',
        whereArgs: [date],
      );
    } catch (e) {
      print('Error deleting mood: $e');
      return 0; // Return 0 if no rows were deleted
    }
  }

  // Convert DateTime to ISO 8601 format (for consistent date storage)
  String formatDate(DateTime dateTime) {
    return dateTime.toIso8601String();
  }
}
