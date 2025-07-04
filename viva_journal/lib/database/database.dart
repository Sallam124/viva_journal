import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/painting.dart';
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';

final logger = Logger();

// Define constants to avoid duplication
const String dateFormat = "yyyy-MM-dd";
const String dateDisplayFormat = "MMM dd, yyyy";
const String fontName = "SF Pro Display";

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
  List<Map<String, dynamic>>? media;
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
    this.media,
    this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'mood': mood,
      'date': DateFormat(dateFormat).format(date),
      'input': input,
      'tags': tags != null ? jsonEncode(tags) : null,
      'title': title,
      'content': content != null ? jsonEncode(content) : null,
      'drawingPoints': drawingPoints != null ? jsonEncode(drawingPoints) : null,
      'media': media != null ? jsonEncode(media) : null,
      'color': color?.value,
    };
  }

  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id: map['id'],
      type: map['type'],
      mood: map['mood'],
      date: DateFormat(dateFormat).parse(map['date']),
      input: map['input'],
      tags: map['tags'] != null ? List<String>.from(jsonDecode(map['tags'])) : null,
      title: map['title'],
      content: map['content'] != null ? List<Map<String, dynamic>>.from(jsonDecode(map['content'])) : null,
      drawingPoints: map['drawingPoints'] != null ? List<Map<String, dynamic>>.from(jsonDecode(map['drawingPoints'])) : null,
      media: map['media'] != null ? List<Map<String, dynamic>>.from(jsonDecode(map['media'])) : null,
      color: map['color'] != null ? Color(map['color']) : null,
    );
  }
}

class DatabaseHelper {
  static final Map<String, DatabaseHelper> _instances = {};
  static final Map<String, Database> _databases = {};
  final String _userId;

  factory DatabaseHelper() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    return _instances.putIfAbsent(user.uid, () => DatabaseHelper._internal(user.uid));
  }

  DatabaseHelper._internal(this._userId);

  Future<Database> get database async {
    if (_databases.containsKey(_userId)) {
      return _databases[_userId]!;
    } else {
      final db = await _initDatabase();
      _databases[_userId] = db;
      return db;
    }
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/journal_$_userId.db';

    return await openDatabase(
      path,
      version: 6,
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
        media TEXT,
        color INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 6) {
      // Add new media column if it doesn't exist
      await db.execute('ALTER TABLE entries ADD COLUMN media TEXT');

      // Migrate existing mediaPaths to new media format
      try {
        final List<Map<String, dynamic>> entries = await db.query('entries');
        for (var entry in entries) {
          if (entry['mediaPaths'] != null) {
            List<String> mediaPaths = List<String>.from(jsonDecode(entry['mediaPaths']));
            List<Map<String, dynamic>> newMedia = mediaPaths.map((path) => {
              'filePath': path,
              'isVideo': path.toLowerCase().endsWith('.mp4'),
              'position': {'dx': 0.0, 'dy': 0.0},
              'size': 200.0,
              'angle': 0.0,
            }).toList();

            await db.update(
              'entries',
              {'media': jsonEncode(newMedia)},
              where: 'id = ?',
              whereArgs: [entry['id']],
            );
          }
        }

        // Drop the old mediaPaths column
        await db.execute('ALTER TABLE entries DROP COLUMN mediaPaths');
      } catch (e) {
        logger.e('Error during media migration: $e');
      }
    }
  }

  Future<List<Entry>> getEntriesPastWeek() async {
    try {
      final db = await database;
      DateTime currentDate = DateTime.now();
      DateTime sevenDaysAgo = currentDate.subtract(Duration(days: 7));
      String formattedCurrentDate = DateFormat(dateFormat).format(currentDate);
      String formattedSevenDaysAgo = DateFormat(dateFormat).format(sevenDaysAgo);

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
      String formattedDate = DateFormat(dateFormat).format(date);
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
      entryMap['date'] = DateFormat(dateFormat).format(entry.date);
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
      entryMap['date'] = DateFormat(dateFormat).format(entry.date);
      return await db.update(
        'entries',
        entryMap,
        where: 'date = ?',
        whereArgs: [DateFormat(dateFormat).format(entry.date)],
      );
    } catch (e) {
      logger.e('Error updating entry: $e');
      return 0;
    }
  }

  Future<int> deleteEntry(DateTime date) async {
    try {
      final db = await database;
      String formattedDate = DateFormat(dateFormat).format(date);
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

  // Add a method to clear the database when user logs out
  static Future<void> clearUserDatabase(String userId) async {
    if (_databases.containsKey(userId)) {
      await _databases[userId]?.close();
      _databases.remove(userId);
    }
    _instances.remove(userId);
  }
}