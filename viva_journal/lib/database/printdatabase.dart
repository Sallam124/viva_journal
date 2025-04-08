// database/printdatabase.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// This function retrieves the database and prints all its contents.
Future<void> printEntireDatabase() async {
  try {
    // Open the database located at the given path
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'mood_tracker.db'); // Replace with your database name

    // Open the database
    final db = await openDatabase(path);

    // Retrieve all the tables from the database
    List<Map<String, dynamic>> tables = await db.rawQuery('SELECT name FROM sqlite_master WHERE type="table"');

    // Iterate through each table and print its contents
    for (var table in tables) {
      String tableName = table['name'];
      print('Printing data from table: $tableName');
      List<Map<String, dynamic>> tableData = await db.query(tableName);
      for (var row in tableData) {
        print(row);
      }
    }

    // Close the database
    await db.close();
  } catch (e) {
    print("Error occurred while printing the database: $e");
  }
}

void main() async {
  // Run the function to print the entire database
  await printEntireDatabase();
}
