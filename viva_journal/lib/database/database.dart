import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/painting.dart';
import 'package:logger/logger.dart';

final logger = Logger();

// Define the model for the mood entry
class MoodEntry {
  int? id;
  String mood;
  String date;
  String input;

  MoodEntry({
    this.id,
    required this.mood,
    required this.date,
    required this.input,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mood': mood,
      'date': date,
      'input': input,
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      id: map['id'],
      mood: map['mood'],
      date: map['date'],
      input: map['input'],
    );
  }
}

// Define the model for the journal entry
class JournalEntry {
  int? id;
  DateTime date;
  String mood;
  List<String> tags;
  String title;
  List<Map<String, dynamic>> content;
  List<Map<String, dynamic>> drawingPoints;
  List<String> mediaPaths;
  Color color;

  JournalEntry({
    this.id,
    required this.date,
    required this.mood,
    required this.tags,
    required this.title,
    required this.content,
    required this.drawingPoints,
    required this.mediaPaths,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mood': mood,
      'tags': jsonEncode(tags),
      'title': title,
      'content': jsonEncode(content),
      'drawingPoints': jsonEncode(drawingPoints),
      'mediaPaths': jsonEncode(mediaPaths),
      'color': color.toARGB32(),
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'],
      date: DateTime.parse(map['date']),
      mood: map['mood'],
      tags: List<String>.from(jsonDecode(map['tags'])),
      title: map['title'],
      content: List<Map<String, dynamic>>.from(jsonDecode(map['content'])),
      drawingPoints: List<Map<String, dynamic>>.from(jsonDecode(map['drawingPoints'])),
      mediaPaths: List<String>.from(jsonDecode(map['mediaPaths'])),
      color: Color(map['color']),
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    } else {
      _database = await _initDatabase();
      return _database!;
    }
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/journal.db';

    return await openDatabase(
      path,
      version: 4, // bumped from 3 to 4
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE moods(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mood TEXT,
        date TEXT,
        input TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE journals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        mood TEXT,
        tags TEXT,
        title TEXT,
        content TEXT,
        drawingPoints TEXT,
        mediaPaths TEXT,
        color INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE journals ADD COLUMN tags TEXT');
      await db.execute('ALTER TABLE journals ADD COLUMN drawingPoints TEXT');
    }
  }

  Future<List<MoodEntry>> getEntriesPastWeek() async {
    try {
      final db = await database;
      DateTime currentDate = DateTime.now();
      DateTime sevenDaysAgo = currentDate.subtract(Duration(days: 7));
      String formattedCurrentDate = DateFormat('yyyy-MM-dd').format(currentDate);
      String formattedSevenDaysAgo = DateFormat('yyyy-MM-dd').format(sevenDaysAgo);

      final List<Map<String, dynamic>> maps = await db.query(
        'moods',
        where: 'date BETWEEN ? AND ?',
        whereArgs: [formattedSevenDaysAgo, formattedCurrentDate],
        orderBy: 'date DESC',
      );

      return List.generate(maps.length, (i) => MoodEntry.fromMap(maps[i]));
    } catch (e) {
      logger.e('Error fetching entries for the past week: $e');
      return [];
    }
  }

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
      } else {
        return null;
      }
    } catch (e) {
      logger.e('Error fetching mood for day $date: $e');
      return null;
    }
  }

  Future<int> insertMood(MoodEntry moodEntry) async {
    try {
      final db = await database;
      return await db.insert('moods', moodEntry.toMap());
    } catch (e) {
      logger.e('Error inserting mood: $e');
      rethrow;
    }
  }

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
      logger.e('Error updating mood: $e');
      return 0;
    }
  }

  Future<int> deleteMood(String date) async {
    try {
      final db = await database;
      return await db.delete(
        'moods',
        where: 'date = ?',
        whereArgs: [date],
      );
    } catch (e) {
      logger.e('Error deleting mood: $e');
      return 0;
    }
  }

  Future<JournalEntry?> getJournalForDate(DateTime date) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'journals',
        where: 'date = ?',
        whereArgs: [date.toIso8601String()],
      );

      if (maps.isNotEmpty) {
        return JournalEntry.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      logger.e('Error getting journal: $e');
      return null;
    }
  }

  Future<int> insertJournal(JournalEntry entry) async {
    try {
      final db = await database;
      return await db.insert('journals', entry.toMap());
    } catch (e) {
      logger.e('Error inserting journal: $e');
      rethrow;
    }
  }

  Future<int> updateJournal(JournalEntry entry) async {
    try {
      final db = await database;
      return await db.update(
        'journals',
        entry.toMap(),
        where: 'date = ?',
        whereArgs: [entry.date.toIso8601String()],
      );
    } catch (e) {
      logger.e('Error updating journal: $e');
      return 0;
    }
  }

  Future<int> deleteJournal(DateTime date) async {
    try {
      final db = await database;
      return await db.delete(
        'journals',
        where: 'date = ?',
        whereArgs: [date.toIso8601String()],
      );
    } catch (e) {
      logger.e('Error deleting journal: $e');
      return 0;
    }
  }

  Future<List<JournalEntry>> getAllJournals() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('journals');
      return List.generate(maps.length, (i) => JournalEntry.fromMap(maps[i]));
    } catch (e) {
      logger.e('Error getting all journals: $e');
      return [];
    }
  }
}