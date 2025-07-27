import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'feedback_entry.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  static Database? _db;
  DatabaseHelper._();
  factory DatabaseHelper() => _instance;

  /// Single, versioned database getter.
  Future<Database> get db async {
    if (_db != null) return _db!;

    final docs = await getApplicationDocumentsDirectory();
    final path = join(docs.path, 'app.db');
    _db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        // 1) feedback table
        await db.execute('''
          CREATE TABLE feedback(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            rating INTEGER,
            comment TEXT,
            createdAt TEXT
          )
        ''');
        // 2) support_messages table
        await db.execute('''
          CREATE TABLE support_messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_email TEXT,
            message TEXT,
            timestamp INTEGER,
            is_read INTEGER DEFAULT 0
          )
        ''');
        // 3) navigation_history table
        await db.execute('''
          CREATE TABLE navigation_history(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            restaurant_name TEXT,
            distance REAL,
            timestamp INTEGER,
            polyline TEXT,
            restaurant TEXT,
            start TEXT,
            end TEXT
          )
        ''');
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          // add support_messages when upgrading from v1 ➔ v2
          await db.execute('''
            CREATE TABLE support_messages(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_email TEXT,
              message TEXT,
              timestamp INTEGER,
              is_read INTEGER DEFAULT 0
            )
          ''');
        }
        if (oldV < 3) {
          // add navigation_history when upgrading from v2 ➔ v3
          await db.execute('''
            CREATE TABLE navigation_history(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              restaurant_name TEXT,
              distance REAL,
              timestamp INTEGER,
              polyline TEXT,
              restaurant TEXT,
              start TEXT,
              end TEXT
            )
          ''');
        }
      },
    );
    return _db!;
  }

  // ────────────────────────────────────────────────
  // Feedback methods
  // ────────────────────────────────────────────────

  Future<int> insertFeedback(FeedbackEntry f) async {
    final database = await db;
    return database.insert('feedback', f.toMap());
  }

  Future<List<FeedbackEntry>> getAllFeedback({int? rating}) async {
    final database = await db;
    final where = rating != null ? 'WHERE rating = ?' : '';
    final args = rating != null ? [rating] : null;
    final maps = await database.rawQuery(
      'SELECT * FROM feedback $where ORDER BY createdAt DESC', args);
    return maps.map((m) => FeedbackEntry.fromMap(m)).toList();
  }

  Future<int> countByRating(int rating) async {
    final database = await db;
    final result = Sqflite.firstIntValue(await database.rawQuery(
      'SELECT COUNT(*) FROM feedback WHERE rating = ?', [rating]));
    return result ?? 0;
  }

  // ────────────────────────────────────────────────
  // Support‐messages methods
  // ────────────────────────────────────────────────

  Future<int> insertSupportMessage(String email, String message) async {
    final database = await db;
    return database.insert(
      'support_messages',
      {
        'user_email': email,
        'message': message,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'is_read': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> getUnreadSupportMessageCount() async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM support_messages WHERE is_read = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getAllSupportMessages() async {
    final database = await db;
    return database.query(
      'support_messages',
      orderBy: 'timestamp DESC',
    );
  }

  Future<void> markSupportMessageRead(int id) async {
    final database = await db;
    await database.update(
      'support_messages',
      { 'is_read': 1 },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ────────────────────────────────────────────────
  // Navigation history methods
  // ────────────────────────────────────────────────

  Future<void> insertNavigationHistory(Map<String, dynamic> entry) async {
    final database = await db;
    await database.insert(
      'navigation_history',
      entry,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getNavigationHistory() async {
    final database = await db;
    return await database.query(
      'navigation_history',
      orderBy: 'timestamp DESC',
    );
  }

  // ────────────────────────────────────────────────
  // (Optional) User management methods, if you still need them
  // ────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final database = await db;
    return database.query('users');
  }

  Future<void> updateUser(int id, String username, String email) async {
    final database = await db;
    await database.update(
      'users',
      { 'username': username, 'email': email },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteUser(int id) async {
    final database = await db;
    await database.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> blockUser(int id) async {
    final database = await db;
    await database.update(
      'users',
      { 'is_blocked': 1 },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> editUser(int id, String username, String email) async {
    final database = await db;
    await database.update(
      'users',
      { 'username': username, 'email': email },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
