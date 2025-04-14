// This file handles all local database operations using SQLite (sqflite package).
// It manages restaurant data including CRUD operations and database initialization.

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/* 
Singleton Class that manages the local database for restaurant information.

This class provides:
- Database initialization
- CRUD operations for restaurants
- Pre-populated restaurant data
*/
class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;

  static Database? _database;
  // database table name
  static const String _tableName = 'restaurants';

  // private constructor
  LocalDatabase._internal();

  // getter for the database instance, if database is not yet initialized.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initializeDB('local.db');
    return _database!;
  }

  // Initializes database
  Future<Database> _initializeDB(String filepath) async {
    final dbpath = await getDatabasesPath();
    final path = join(dbpath, filepath); // create path

    // Uncomment if you want to delete DB and recreate
    //await deleteDatabase(path);

    return await openDatabase(
      path,
      version: 2, // Incremented version
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        // handle database schema
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS $_tableName');
          await _createDB(db, newVersion);
        }
      },
    );
  }

  // creates the restaurant table in the database
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        menu TEXT NOT NULL,
        delivery TEXT NOT NULL,
        meal TEXT NOT NULL,
        cuisine TEXT NOT NULL,
        location TEXT NOT NULL,
        website TEXT NOT NULL
      )
    ''');
    // insert initial set of restaurants
    await _insertInitialRestaurants(db);
  }

  // insert initial restaurants into the database
  Future<void> _insertInitialRestaurants(Database db) async {
    final restaurants = [
      {
        'name': 'Vineyard',
        'menu': 'Pizza, Pasta, Salad, Tenderloin, Lumpia, Sinigang, Borgz',
        'delivery': 'yes',
        'meal': 'lunch, dinner, snacks',
        'cuisine': 'filipino',
        'location': 'banwa',
        'website': 'https://www.facebook.com/VineyardMiagaoPhil',
      },
      {
        'name': 'Hello Burger',
        'menu':
            'Kamusta Burger, Fries, Namaste Burger, Bonjour Burger, Ciao Burger, Ohayo Burger',
        'delivery': 'yes',
        'meal': 'breakfast, lunch, dinner, snacks',
        'cuisine': 'italian, filipino',
        'location': 'banwa',
        'website': 'https://www.facebook.com/HelloBurgerPH',
      },
      {
        'name': 'Sulu Garden',
        'menu': 'Sushi, Sashimi, Tempura, Gyudon, Ramen, Udon',
        'delivery': 'no',
        'meal': 'lunch, dinner',
        'cuisine': 'japanese, filipino',
        'location': 'banwa',
        'website': 'https://www.facebook.com/sulugardenmiagao',
      },
      {
        'name': 'Pickers',
        'menu': 'Tacos, Burritos, Quesadillas, Nachos, Burritos',
        'delivery': 'no',
        'meal': 'snacks',
        'cuisine': 'mexican',
        'location': 'banwa',
        'website': 'https://www.facebook.com/pickerspitaNdough',
      },
      {
        'name': 'El Garaje',
        'menu':
            'Spaghetti, Aglio e Olio, Carbonara, Lasagna, Corned Beef, Fries, Chicken Solo',
        'delivery': 'yes',
        'meal': 'breakfast, lunch, snacks',
        'cuisine': 'italian, filipino',
        'location': 'malagyan',
        'website': 'https://www.facebook.com/elgarajemiagao',
      },
      {
        'name': 'Spharks',
        'menu': 'Tortang Talong, Adobo, Sinigang, Lumpia',
        'delivery': 'no',
        'meal': 'breakfast, lunch, dinner',
        'cuisine': 'filipino',
        'location': 'hollywood',
        'website': 'https://www.facebook.com/profile.php?id=100045734126189',
      },
      {
        'name': 'Susans',
        'menu': 'Adobo, Sinigang, Lumpia, Pancit',
        'delivery': 'no',
        'meal': 'breakfast, lunch, dinner',
        'cuisine': 'filipino',
        'location': 'hollywood',
        'website': 'None',
      },
      {
        'name': 'CLS',
        'menu':
            'Pizza, Fries, Shake, Burger, Sisig, Burger Steak, Chicken Meal',
        'delivery': 'yes',
        'meal': 'breakfast, lunch, dinner',
        'cuisine': 'italian, filipino',
        'location': 'hollywood',
        'website': 'https://www.facebook.com/clssuperfood',
      },
      {
        'name': 'Manang Betch',
        'menu':
            'Lumpiang Toge, Pancit, Adobo, Dinuguan, Porkchop, Nuttered Chicken',
        'delivery': 'no',
        'meal': 'breakfast, lunch',
        'cuisine': 'filipino',
        'location': 'upv',
        'website': 'https://www.facebook.com/profile.php?id=100040564886551',
      },
      {
        'name': 'Callies',
        'menu':
            'Taro Milktea, Juice, Fries, Brown Sugar Milktea, Vanilla Latte',
        'delivery': 'no',
        'meal': 'snacks',
        'cuisine': 'filipino',
        'location': 'upv',
        'website': 'None',
      },
      {
        'name': 'Waffle Time',
        'menu':
            'Iced Tea, Belgian Waffle, German Cheese Franks, Bavarian Cream, Ham n Cheese, Tuna Salad',
        'delivery': 'no',
        'meal': 'snacks',
        'cuisine': 'filipino',
        'location': 'upv',
        'website': 'None',
      },
    ];
    // insert each restaurant into the databse
    for (final restaurant in restaurants) {
      await db.insert(_tableName, restaurant);
    }
  }

  /*
  Insert a new restaurant into the database

  If the restaurant with the same name exists, it will be replaced. 
  */
  Future<void> insertResto(
    // parameters
    String name,
    String menu,
    String delivery,
    String meal,
    String cuisine,
    String location,
    String website,
  ) async {
    final db = await database;
    await db.insert(_tableName, {
      'name': name,
      'menu': menu,
      'delivery': delivery,
      'meal': meal,
      'cuisine': cuisine,
      'location': location,
      'website': website,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // retrieves all restaurants from the database.
  // returns a list of restaurant as String, dynamic
  Future<List<Map<String, dynamic>>> getAllRestaurants() async {
    final db = await database;
    return await db.query(_tableName);
  }

  // retreives only the names of all the restaurants.
  Future<List<String>> getRestaurantNames() async {
    final db = await database;
    final allnames = await db.query(_tableName, columns: ['name']);
    return allnames.map((e) => e['name'] as String).toList();
  }

  // deletes a restaurant through it ID
  // deletes the row of deleted restaurant
  Future<int> deleteRestaurantById(int id) async {
    final db = await database;
    return await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  // updates an existing restaurant's information
  Future<void> updateResto(
    int id,
    String name,
    String menu,
    String delivery,
    String meal,
    String cuisine,
    String location,
    String website,
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
        'website': website,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
