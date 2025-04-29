import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }
  Future<List<Map<String, dynamic>>> getEntriesPastWeek() async {
    final db = await database;
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    final oneWeekAgoStr = oneWeekAgo.toIso8601String();

    final result = await db.query(
      'entries', // your table name
      where: 'date >= ?',
      whereArgs: [oneWeekAgoStr],
      orderBy: 'date DESC',
    );

    return result;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'journal.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE journal_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            mood TEXT,
            tags TEXT,
            text TEXT,
            drawings TEXT,
            attachments TEXT,
            voice_note TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertEntry(Map<String, dynamic> entry) async {
    final db = await database;
    return await db.insert('journal_entries', entry);
  }

  Future<List<Map<String, dynamic>>> getEntries() async {
    final db = await database;
    return await db.query('journal_entries', orderBy: "date DESC");
  }
}
