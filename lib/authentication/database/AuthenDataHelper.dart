// lib/authentication/database/AuthenDataHelper.dart

import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AuthenDataHelper {
  // 1) Database and table definitions
  static const _dbName       = 'yumme.db';
  static const _dbVersion    = 1;
  static const _tableName    = 'users';

  // Column names:
  static const columnId        = 'id';
  static const columnUsername  = 'username';
  static const columnEmail     = 'email';
  static const columnPassword  = 'password';
  static const columnIsBlocked = 'isBlocked';

  // 2) Make this a singleton class
  AuthenDataHelper._privateConstructor();
  static final AuthenDataHelper instance = AuthenDataHelper._privateConstructor();

  // 3) Only allow a single reference to the database
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    // Lazily instantiate the DB the first time it’s accessed
    _database = await _initDatabase();
    return _database!;
  }

  // 4) Open (or create) the database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  // 5) Called only once: create the “users” table
  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        $columnId        INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnUsername  TEXT NOT NULL,
        $columnEmail     TEXT NOT NULL UNIQUE,
        $columnPassword  TEXT NOT NULL,
        $columnIsBlocked INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // ---------------------------------------------------------
  // Public helper methods for CRUD on the “users” table:
  // ---------------------------------------------------------

  /// 6) Insert a new user.
  ///    Expects a map containing at least:
  ///      { 'username': 'someName', 'email': 'a@b.com', 'password': 'plainOrHashed', 'isBlocked': 0 }
  Future<int> insertUser(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert(_tableName, row);
  }

  /// 7) Fetch all users, ordered by username ascending
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await instance.database;
    return await db.query(
      _tableName,
      columns: [
        columnId,
        columnUsername,
        columnEmail,
        columnIsBlocked,
      ],
      orderBy: '$columnUsername COLLATE NOCASE ASC',
    );
  }

  /// 8) Delete a user given its primary‐key `id`
  Future<int> deleteUser(int id) async {
    final db = await instance.database;
    return await db.delete(
      _tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  /// 9) Toggle or set the “isBlocked” flag (0 or 1) for a given user id
  Future<int> updateUserBlockStatus(int id, int isBlocked) async {
    final db = await instance.database;
    return await db.update(
      _tableName,
      { columnIsBlocked: isBlocked },
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  /// 10) (Optional) Fetch a single user by email (e.g. for login‐validation)
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await instance.database;
    final results = await db.query(
      _tableName,
      where: '$columnEmail = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  /// 11) (Optional) Fetch a single user by username
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await instance.database;
    final results = await db.query(
      _tableName,
      where: '$columnUsername = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  /// 12) (Optional) Update arbitrary fields for a user by id
  Future<int> updateUser(int id, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      _tableName,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
}
