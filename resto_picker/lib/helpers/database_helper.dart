import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'restos.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE restos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT
          )
        ''');
      },
      version: 1,
    );
  }

  Future<List<Map<String, dynamic>>> getRestos() async {
    final db = await database;
    return db.query('restos');
  }

  Future<void> insertRestos(List<String> names) async {
    final db = await database;
    final batch = db.batch();
    for (var name in names) {
      batch.insert('restos', {'name': name});
    }
    await batch.commit(noResult: true);
  }

  //insert a single resto
  Future<void> insertResto(String name) async {
    final db = await database;
    await db.insert('restos', {'name': name});
  }

  // Add this method to your DatabaseHelper class
  Future<void> clearRestosTemporarily() async {
    final db = await database;
    await db.delete('restos'); // Deletes all rows in the 'restos' table
  }
}
