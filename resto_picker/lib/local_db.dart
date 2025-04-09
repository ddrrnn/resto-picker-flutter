import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;

  static Database? _database;
  static const String _tableName = 'restaurants';

  LocalDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initializeDB('local.db');
    return _database!;
  }

  Future<Database> _initializeDB(String filepath) async {
    final dbpath = await getDatabasesPath();
    final path = join(dbpath, filepath);

    // Delete existing database if you want to force recreation
    // await deleteDatabase(path);

    return await openDatabase(
      path,
      version: 2, // Increment version number
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS $_tableName');
          await _createDB(db, newVersion);
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        menu TEXT NOT NULL
      )
    ''');

    await _insertInitialRestaurants(db);
  }

  Future<void> _insertInitialRestaurants(Database db) async {
    final restaurants = [
      {'name': 'Vineyard', 'menu': 'Pizza, Pasta, Salad'},
      {'name': 'Burger Palace', 'menu': 'Burgers, Fries, Shakes'},
      {'name': 'Sushi World', 'menu': 'Sushi, Sashimi, Tempura'},
      {'name': 'Taco Fiesta', 'menu': 'Tacos, Burritos, Quesadillas'},
      {'name': 'Pasta Heaven', 'menu': 'Spaghetti, Lasagna, Ravioli'},
    ];

    for (final restaurant in restaurants) {
      await db.insert(_tableName, restaurant);
    }
  }

  Future<void> insertResto(String name, String menu) async {
    final db = await database;
    await db.insert(_tableName, {'name': name, 'menu': menu});
  }

  Future<List<Map<String, dynamic>>> getAllRestaurants() async {
    final db = await database;
    return await db.query(_tableName);
  }

  Future<List<String>> getRestaurantNames() async {
    final db = await database;
    final allnames = await db.query(_tableName, columns: ['name']);
    return allnames.map((e) => e['name'] as String).toList();
  }

  Future<int> deleteRestaurantById(int id) async {
    final db = await database;
    return await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  // update resto when user edited it.
  Future<void> updateResto(int id, String name, String menu) async {
    final db = await database;
    await db.update(
      _tableName,
      {'name': name, 'menu': menu},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
