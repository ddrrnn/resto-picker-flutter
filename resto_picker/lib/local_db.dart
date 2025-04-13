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

    // Uncomment if you want to delete DB and recreate
    // await deleteDatabase(path);

    return await openDatabase(
      path,
      version: 2, // Incremented version
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
        menu TEXT NOT NULL,
        delivery TEXT NOT NULL,
        meal TEXT NOT NULL,
        cuisine TEXT NOT NULL,
        location TEXT NOT NULL
      )
    ''');

    await _insertInitialRestaurants(db);
  }

  Future<void> _insertInitialRestaurants(Database db) async {
    final restaurants = [
      {
        'name': 'Vineyard',
        'menu': 'Pizza, Pasta, Salad, Tenderloin, Lumpia, Sinigang, Borgz',
        'delivery': 'yes',
        'meal': 'lunch, dinner, snacks',
        'cuisine': 'filipino',
        'location': 'banwa',
      },
      {
        'name': 'Hello Burger',
        'menu':
            'Kamusta Burger, Fries, Namaste Burger, Bonjour Burger, Ciao Burger, Ohayo Burger',
        'delivery': 'yes',
        'meal': 'breakfast, lunch, dinner, snacks',
        'cuisine': 'italian, filipino',
        'location': 'banwa',
      },
      {
        'name': 'Sulu Garden',
        'menu': 'Sushi, Sashimi, Tempura, Gyudon, Ramen, Udon',
        'delivery': 'no',
        'meal': 'lunch, dinner',
        'cuisine': 'japanese, filipino',
        'location': 'banwa',
      },
      {
        'name': 'Pickers',
        'menu': 'Tacos, Burritos, Quesadillas, Nachos, Burritos',
        'delivery': 'no',
        'meal': 'snacks',
        'cuisine': 'mexican',
        'location': 'banwa',
      },
      {
        'name': 'El Garaje',
        'menu':
            'Spaghetti, Aglio e Olio, Carbonara, Lasagna, Corned Beef, Fries, Chicken Solo',
        'delivery': 'yes',
        'meal': 'breakfast, lunch, snacks',
        'cuisine': 'italian, filipino',
        'location': 'malagyan',
      },
      {
        'name': 'Spharks',
        'menu': 'Tortang Talong, Adobo, Sinigang, Lumpia',
        'delivery': 'no',
        'meal': 'breakfast, lunch, dinner',
        'cuisine': 'filipino',
        'location': 'upv',
      },
      {
        'name': 'Susans',
        'menu': 'Adobo, Sinigang, Lumpia, Pancit',
        'delivery': 'no',
        'meal': 'breakfast, lunch, dinner',
        'cuisine': 'filipino',
        'location': 'upv',
      },
      {
        'name': 'CLS',
        'menu':
            'Pizza, Fries, Shake, Burger, Sisig, Burger Steak, Chicken Meal',
        'delivery': 'no',
        'meal': 'breakfast, lunch, dinner',
        'cuisine': 'filipino',
        'location': 'upv, italian',
      },
    ];

    for (final restaurant in restaurants) {
      await db.insert(_tableName, restaurant);
    }
  }

  Future<void> insertResto(
    String name,
    String menu,
    String delivery,
    String meal,
    String cuisine,
    String location,
  ) async {
    final db = await database;
    await db.insert(_tableName, {
      'name': name,
      'menu': menu,
      'delivery': delivery,
      'meal': meal,
      'cuisine': cuisine,
      'location': location,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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

  Future<void> updateResto(
    int id,
    String name,
    String menu,
    String delivery,
    String meal,
    String cuisine,
    String location,
  ) async {
    final db = await database;
    await db.update(
      _tableName,
      {
        'name': name,
        'menu': menu,
        'delivery': delivery,
        'meal': meal,
        'cuisine': cuisine,
        'location': location,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
