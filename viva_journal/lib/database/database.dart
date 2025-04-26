import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';  // For date formatting

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

  // Get entries from the past week
  Future<List<MoodEntry>> getEntriesPastWeek() async {
    try {
      final db = await database;

      // Get the current date and the date from 7 days ago
      DateTime currentDate = DateTime.now();
      DateTime sevenDaysAgo = currentDate.subtract(Duration(days: 7));

      // Format the dates to ISO 8601 strings for comparison
      String formattedCurrentDate = DateFormat('yyyy-MM-dd').format(currentDate);
      String formattedSevenDaysAgo = DateFormat('yyyy-MM-dd').format(sevenDaysAgo);

      // Query the database for moods within the past 7 days
      final List<Map<String, dynamic>> maps = await db.query(
        'moods',
        where: 'date BETWEEN ? AND ?',
        whereArgs: [formattedSevenDaysAgo, formattedCurrentDate],
        orderBy: 'date DESC',  // Optionally order by date (most recent first)
      );

      // Convert the list of maps into a list of MoodEntry objects
      return List.generate(maps.length, (i) => MoodEntry.fromMap(maps[i]));
    } catch (e) {
      return []; // Return an empty list in case of error
    }
  }
// Get mood entry for a specific date
  Future<MoodEntry?> getMoodForDay(String date) async {
    try {
      final db = await database;

      // Query the database for mood entry for the specified date
      final List<Map<String, dynamic>> maps = await db.query(
        'moods',
        where: 'date = ?',
        whereArgs: [date],
      );

      // If the result is not empty, return the first matching mood entry
      if (maps.isNotEmpty) {
        return MoodEntry.fromMap(maps.first);
      } else {
        return null; // Return null if no entry found for the date
      }
    } catch (e) {
      return null; // Return null in case of error
    }
  }

  // Insert a new mood entry
  Future<int> insertMood(MoodEntry moodEntry) async {
    try {
      final db = await database;
      return await db.insert('moods', moodEntry.toMap());
    } catch (e) {
      rethrow; // Rethrow the error or return a custom error code
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
      return 0; // Return 0 if no rows were deleted
    }
  }

  // Convert DateTime to ISO 8601 format (for consistent date storage)
  String formatDate(DateTime dateTime) {
    return dateTime.toIso8601String();
  }
}
