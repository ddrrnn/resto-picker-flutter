import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Database? _database;

class LocalDatabase {
  static const String _tableName = 'restaurants';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initializeDB('local.db');
    return _database!;
  }

  Future<Database> _initializeDB(String filepath) async {
    final dbpath = await getDatabasesPath();
    final path = join(dbpath, filepath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        menu TEXT NOT NULL
      )
    ''');

    // Insert initial 5 restaurants
    await _insertInitialRestaurants(db);
  }

  Future<void> _insertInitialRestaurants(Database db) async {
    final restaurants = [
      {
        'name': 'Vineyard',
        'address': '123 Main St, City',
        'menu': 'Pizza, Pasta, Salad',
      },
      {
        'name': 'Burger Palace',
        'address': '456 Oak Ave, Town',
        'menu': 'Burgers, Fries, Shakes',
      },
      {
        'name': 'Sushi World',
        'address': '789 Pine Rd, Village',
        'menu': 'Sushi, Sashimi, Tempura',
      },
      {
        'name': 'Taco Fiesta',
        'address': '321 Elm Blvd, District',
        'menu': 'Tacos, Burritos, Quesadillas',
      },
      {
        'name': 'Pasta Heaven',
        'address': '654 Maple Ln, Borough',
        'menu': 'Spaghetti, Lasagna, Ravioli',
      },
    ];

    for (final restaurant in restaurants) {
      await db.insert(_tableName, restaurant);
    }
  }

  Future<List<Map<String, dynamic>>> getAllRestaurants() async {
    final db = await database;
    return await db.query(_tableName);
  }

  // fetch restaurants names for wheel and edit
  Future<List<String>> getRestaurantNames() async {
    final db = await database;
    final allnames = await db.query(_tableName, columns: ['name']);
    return allnames.map((e) => e['name'] as String).toList();
  }
}
