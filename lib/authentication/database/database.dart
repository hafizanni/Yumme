import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Database? _database;

/// Returns the initialized database, creating/upgrading as needed
Future<Database> getDatabase() async {
  if (_database != null) return _database!;

  final String path = join(await getDatabasesPath(), 'user_database.db');
  _database = await openDatabase(
    path,
    version: 10,  // bump this to trigger onUpgrade
    onCreate: (db, version) async {
      // Users table
      await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT,
          email TEXT UNIQUE,
          password TEXT,
          is_blocked INTEGER DEFAULT 0
        )
      ''');

      // Search history table
      await db.execute('''
        CREATE TABLE search_history(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          query TEXT,
          timestamp INTEGER,
          user_id INTEGER,
          FOREIGN KEY(user_id) REFERENCES users(id)
        )
      ''');

      // Restaurants table
      await db.execute('''
        CREATE TABLE restaurants(
          id TEXT PRIMARY KEY,
          CompleteStoreName TEXT,
          FoodType TEXT,
          Dietary TEXT,
          AverageRating REAL,
          price TEXT,
          address TEXT,
          OperationHours TEXT,
          osm_tile_url TEXT,
          status INTEGER,
          Latitude REAL,
          Longitude REAL
        )
      ''');

      // Favorites table
      await db.execute('''
        CREATE TABLE favorites(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          restaurant_id TEXT,
          FOREIGN KEY(user_id) REFERENCES users(id),
          FOREIGN KEY(restaurant_id) REFERENCES restaurants(id)
        )
      ''');

      // Feedback table
      await db.execute('''
        CREATE TABLE feedback(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          content TEXT NOT NULL,
          rating INTEGER NOT NULL,
          timestamp INTEGER NOT NULL,
          user_id INTEGER
        )
      ''');

      // Navigation history table
      await db.execute('''
        CREATE TABLE navigation_history(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          restaurant_id TEXT,
          restaurant_name TEXT,
          distance REAL,
          timestamp INTEGER
        )
      ''');
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      // Create search_history table if upgrading from version < 8
      if (oldVersion < 8) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS search_history(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            query TEXT,
            timestamp INTEGER,
            user_id INTEGER,
            FOREIGN KEY(user_id) REFERENCES users(id)
          )
        ''');
      }
      
      if (oldVersion < 4) {
        await db.execute('DROP TABLE IF EXISTS restaurants');
        await db.execute('''
          CREATE TABLE restaurants(
            id TEXT PRIMARY KEY,
            CompleteStoreName TEXT,
            FoodType TEXT,
            Dietary TEXT,
            AverageRating REAL,
            price TEXT,
            address TEXT,
            OperationHours TEXT,
            osm_tile_url TEXT,
            status INTEGER,
            Latitude REAL,
            Longitude REAL
          )
        ''');
      }
      if (oldVersion < 5) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS feedback(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT NOT NULL,
            rating INTEGER NOT NULL,
            timestamp INTEGER NOT NULL,
            user_id INTEGER
          )
        ''');
      }
      if (oldVersion < 9) {
        // Add username and is_blocked columns if they don't exist
        await db.execute('ALTER TABLE users ADD COLUMN username TEXT;');
        await db.execute('ALTER TABLE users ADD COLUMN is_blocked INTEGER DEFAULT 0;');
      }
    },
  );

  return _database!;
}

/// Shortcut getter
Future<Database> get database async => await getDatabase();

/// Load and insert restaurants data from JSON asset
Future<void> loadAndInsertRestaurants() async {
  final db = await database;
  final rawJson = await rootBundle.loadString('assets/data/top_rated_restaurants_with_osm.json');
  final List<dynamic> jsonList = json.decode(rawJson);

  final batch = db.batch();
  for (var item in jsonList) {
    batch.insert(
      'restaurants',
      {
        'id': item['CompleteStoreName'],
        'CompleteStoreName': item['CompleteStoreName'],
        'FoodType': item['FoodType'],
        'Dietary': item['Dietary'],
        'AverageRating': (item['AverageRating'] as num).toDouble(),
        'price': item['price'],
        'address': item['address'],
        'OperationHours': item['OperationHours'],
        'osm_tile_url': item['osm_tile_url'],
        'status': item['status'] ? 1 : 0,
        'Latitude': (item['Latitude'] as num).toDouble(),
        'Longitude': (item['Longitude'] as num).toDouble(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  await batch.commit(noResult: true);
}

/// Restaurant queries
Future<List<Map<String, dynamic>>> getAllRestaurants() async {
  final db = await database;
  return db.query('restaurants');
}

Future<List<Map<String, dynamic>>> searchRestaurants(String query) async {
  final db = await database;
  final q = '%${query.toLowerCase()}%';
  return db.query(
    'restaurants',
    where: 'LOWER(CompleteStoreName) LIKE ? OR LOWER(FoodType) LIKE ? OR LOWER(Dietary) LIKE ?',
    whereArgs: [q, q, q],
  );
}

/// Search history
Future<void> addSearchHistory(String query, int userId) async {
  final db = await database;
  await db.insert(
    'search_history',
    {
      'query': query,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'user_id': userId
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<List<Map<String, dynamic>>> getSearchHistory(int userId) async {
  final db = await database;
  return db.query(
    'search_history',
    where: 'user_id = ?',
    whereArgs: [userId],
    orderBy: 'timestamp DESC',
  );
}

Future<List<Map<String, dynamic>>> getSearchHistoryByDate(int userId) async {
  final db = await database;
  return db.query(
    'search_history',
    where: 'user_id = ?',
    whereArgs: [userId],
    orderBy: 'timestamp DESC',
  );
}

Future<void> deleteSearchHistory(int id) async {
  final db = await getDatabase();
  await db.delete('search_history', where: 'id = ?', whereArgs: [id]);
}

Future<void> clearSearchHistory(int userId) async {
  final db = await getDatabase();
  await db.delete('search_history', where: 'user_id = ?', whereArgs: [userId]);
}

/// Favorites
Future<void> addToFavorites(int userId, String restaurantId) async {
  final db = await database;
  await db.insert(
    'favorites',
    {'user_id': userId, 'restaurant_id': restaurantId},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<void> removeFromFavorites(int userId, String restaurantId) async {
  final db = await database;
  await db.delete('favorites', where: 'user_id = ? AND restaurant_id = ?', whereArgs: [userId, restaurantId]);
}

Future<List<Map<String, dynamic>>> getFavorites(int userId) async {
  final db = await database;
  return db.rawQuery(
    '''
    SELECT r.*, f.id AS favorite_id
    FROM restaurants r
    JOIN favorites f ON r.id = f.restaurant_id
    WHERE f.user_id = ?
    ''',
    [userId],
  );
}

/// Feedback methods
Future<void> addFeedback(String content, int rating, {int userId = 1}) async {
  final db = await database;
  await db.insert(
    'feedback',
    {
      'content': content,
      'rating': rating,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'user_id': userId
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<List<Map<String, dynamic>>> getAllFeedback() async {
  final db = await database;
  return db.query('feedback', orderBy: 'timestamp DESC');
}

Future<void> submitFeedback(String content, int? selectedEmoji, {int userId = 1}) async {
  if (selectedEmoji == null) return;
  await addFeedback(content, selectedEmoji, userId: userId);
}

/// Helper: insert a new navigation‐history row
Future<void> insertNavigationHistory(String restId, String name, double distance) async {
  final db = await getDatabase();
  await db.insert(
    'navigation_history',
    {
      'restaurant_id':    restId,
      'restaurant_name':  name,
      'distance':         distance,
      'timestamp':        DateTime.now().millisecondsSinceEpoch,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

/// Helper: fetch all saved navigation entries, newest first
Future<List<Map<String, dynamic>>> getNavigationHistory() async {
  final db = await getDatabase();
  return db.query(
    'navigation_history',
    orderBy: 'timestamp DESC',
  );
}

Future<void> saveNavigationHistory(Map<String, dynamic> entry) async {
  final db = await getDatabase();
  await db.insert(
    'navigation_history',
    entry,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}