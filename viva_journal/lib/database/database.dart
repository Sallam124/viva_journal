import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/painting.dart';
import 'package:logger/logger.dart';

final logger = Logger();

// Define the model for the entry
class Entry {
  int? id;
  String type; // 'mood' or 'journal'
  String? mood;
  DateTime date;
  String? input;
  List<String>? tags;
  String? title;
  List<Map<String, dynamic>>? content;
  List<Map<String, dynamic>>? drawingPoints;
  List<String>? mediaPaths;
  Color? color;

  Entry({
    this.id,
    required this.type,
    this.mood,
    required this.date,
    this.input,
    this.tags,
    this.title,
    this.content,
    this.drawingPoints,
    this.mediaPaths,
    this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'mood': mood,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'input': input,
      'tags': tags != null ? jsonEncode(tags) : null,
      'title': title,
      'content': content != null ? jsonEncode(content) : null,
      'drawingPoints': drawingPoints != null ? jsonEncode(drawingPoints) : null,
      'mediaPaths': mediaPaths != null ? jsonEncode(mediaPaths) : null,
      'color': color?.toARGB32(),
    };
  }

  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id: map['id'],
      type: map['type'],
      mood: map['mood'],
      date: DateFormat('yyyy-MM-dd').parse(map['date']),
      input: map['input'],
      tags: map['tags'] != null ? List<String>.from(jsonDecode(map['tags'])) : null,
      title: map['title'],
      content: map['content'] != null ? List<Map<String, dynamic>>.from(jsonDecode(map['content'])) : null,
      drawingPoints: map['drawingPoints'] != null ? List<Map<String, dynamic>>.from(jsonDecode(map['drawingPoints'])) : null,
      mediaPaths: map['mediaPaths'] != null ? List<String>.from(jsonDecode(map['mediaPaths'])) : null,
      color: map['color'] != null ? Color(map['color']) : null,
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
      version: 5, // Increment version to force migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        mood TEXT,
        date TEXT,
        input TEXT,
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
    if (oldVersion < 5) {
      // Drop old tables if they exist
      await db.execute('DROP TABLE IF EXISTS moods');
      await db.execute('DROP TABLE IF EXISTS journals');

      // Create new table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS entries(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          mood TEXT,
          date TEXT,
          input TEXT,
          tags TEXT,
          title TEXT,
          content TEXT,
          drawingPoints TEXT,
          mediaPaths TEXT,
          color INTEGER
        )
      ''');

      // Migrate data from old tables if they exist
      try {
        // Migrate moods data
        final List<Map<String, dynamic>> oldMoods = await db.query('moods');
        for (var mood in oldMoods) {
          await db.insert('entries', {
            'type': 'mood',
            'mood': mood['mood'],
            'date': mood['date'],
            'input': mood['input'],
          });
        }

        // Migrate journals data
        final List<Map<String, dynamic>> oldJournals = await db.query('journals');
        for (var journal in oldJournals) {
          await db.insert('entries', {
            'type': 'journal',
            'mood': journal['mood'],
            'date': journal['date'],
            'tags': journal['tags'],
            'title': journal['title'],
            'content': journal['content'],
            'drawingPoints': journal['drawingPoints'],
            'mediaPaths': journal['mediaPaths'],
            'color': journal['color'],
          });
        }
      } catch (e) {
        logger.e('Error during migration: $e');
      }
    }
  }

  Future<List<Entry>> getEntriesPastWeek() async {
    try {
      final db = await database;
      DateTime currentDate = DateTime.now();
      DateTime sevenDaysAgo = currentDate.subtract(Duration(days: 7));
      String formattedCurrentDate = DateFormat('yyyy-MM-dd').format(currentDate);
      String formattedSevenDaysAgo = DateFormat('yyyy-MM-dd').format(sevenDaysAgo);

      final List<Map<String, dynamic>> maps = await db.query(
        'entries',
        where: 'date BETWEEN ? AND ?',
        whereArgs: [formattedSevenDaysAgo, formattedCurrentDate],
        orderBy: 'date DESC',
      );

      return List.generate(maps.length, (i) => Entry.fromMap(maps[i]));
    } catch (e) {
      logger.e('Error fetching entries for the past week: $e');
      return [];
    }
  }

  Future<Entry?> getEntryForDate(DateTime date) async {
    try {
      final db = await database;
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final List<Map<String, dynamic>> maps = await db.query(
        'entries',
        where: 'date = ?',
        whereArgs: [formattedDate],
      );

      if (maps.isNotEmpty) {
        return Entry.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      logger.e('Error getting entry: $e');
      return null;
    }
  }

  Future<int> insertEntry(Entry entry) async {
    try {
      final db = await database;
      Map<String, dynamic> entryMap = entry.toMap();
      entryMap['date'] = DateFormat('yyyy-MM-dd').format(entry.date);
      return await db.insert('entries', entryMap);
    } catch (e) {
      logger.e('Error inserting entry: $e');
      rethrow;
    }
  }

  Future<int> updateEntry(Entry entry) async {
    try {
      final db = await database;
      Map<String, dynamic> entryMap = entry.toMap();
      entryMap.remove('id');
      entryMap['date'] = DateFormat('yyyy-MM-dd').format(entry.date);
      return await db.update(
        'entries',
        entryMap,
        where: 'date = ?',
        whereArgs: [DateFormat('yyyy-MM-dd').format(entry.date)],
      );
    } catch (e) {
      logger.e('Error updating entry: $e');
      return 0;
    }
  }

  Future<int> deleteEntry(DateTime date) async {
    try {
      final db = await database;
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      logger.i('Attempting to delete entry for date: $formattedDate');

      // First check if the entry exists using date-only comparison
      final List<Map<String, dynamic>> existing = await db.query(
        'entries',
        where: "date(date) = date(?)",
        whereArgs: [formattedDate],
      );

      logger.i('Found ${existing.length} entries matching the date');

      if (existing.isEmpty) {
        // Let's see what dates are actually in the database
        final allEntries = await db.query('entries');
        logger.i('All entries in database:');
        for (var entry in allEntries) {
          logger.i('Entry date: ${entry['date']}, type: ${entry['type']}');
        }
        logger.w('No entry found for date: $formattedDate');
        return 0;
      }

      final result = await db.delete(
        'entries',
        where: "date(date) = date(?)",
        whereArgs: [formattedDate],
      );

      logger.i('Delete operation result: $result');
      return result;
    } catch (e) {
      logger.e('Error deleting entry: $e');
      return 0;
    }
  }

  Future<List<Entry>> getAllEntries() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('entries');
      return List.generate(maps.length, (i) => Entry.fromMap(maps[i]));
    } catch (e) {
      logger.e('Error getting all entries: $e');
      return [];
    }
  }
}