import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart'; // Ditambahkan untuk anotasi @visibleForTesting

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _isInitializing = false;
  static final logger = Logger();

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Mencegah inisialisasi ganda secara bersamaan
    if (_isInitializing) {
      // Tunggu hingga inisialisasi selesai
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_database != null) return _database!;
    }
    
    _isInitializing = true;
    logger.d('Initializing database...'); // Log debug
    
    try {
      _database = await _initDB('history_quiz.db');
      logger.i('Database initialized successfully'); // Log info
      return _database!;
    } catch (e) {
      logger.e('Error initializing database: $e'); // Log error
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  // Metode ini ditambahkan untuk keperluan testing agar bisa di-reset
  @visibleForTesting
  void setTestDatabase(Database db) {
    _database = db;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      
      logger.d('Database path: $path'); // Log debug

      // Pastikan direktori ada
      await Directory(dirname(path)).create(recursive: true);

      return await openDatabase(
        path,
        version: 4,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
        onOpen: (db) async {
          // Verifikasi struktur database
          await _verifyDatabaseStructure(db);
        },
      );
    } catch (e) {
      logger.e('Error in _initDB: $e'); // Log error
      rethrow;
    }
  }

  Future<void> _verifyDatabaseStructure(Database db) async {
    try {
      // Periksa apakah tabel users ada dan memiliki struktur yang benar
      final tables = await db.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', 'users'],
      );

      if (tables.isEmpty) {
        logger.w('Users table not found, creating...'); // Log peringatan
        await _createDB(db, 4);
      } else {
        // Verifikasi kolom
        final tableInfo = await db.query('pragma_table_info("users")');
        final columns = tableInfo.map((col) => col['name'] as String).toList();
        
        final requiredColumns = [
          'id',
          'username',
          'hashed_password',
          'salt',
          'email',
          'created_at',
          'total_quizzes',
          'high_score',
          'last_quiz_date'
        ];

        final missingColumns = requiredColumns.where((col) => !columns.contains(col)).toList();
        
        if (missingColumns.isNotEmpty) {
          logger.w('Missing columns found: $missingColumns'); // Log peringatan
          // Tangani kolom yang hilang dengan melakukan upgrade database
          await _upgradeDB(db, 3, 4);
        }
      }
    } catch (e) {
      logger.e('Error verifying database structure: $e'); // Log error
      rethrow;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    logger.i('Creating database tables...'); // Log info
    
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        hashed_password TEXT NOT NULL,
        salt TEXT NOT NULL,
        email TEXT,
        profile_image_path TEXT,
        created_at TEXT NOT NULL,
        total_quizzes INTEGER DEFAULT 0,
        high_score INTEGER DEFAULT 0,
        last_quiz_date TEXT
      )
    ''');
    
    logger.i('Database tables created successfully'); // Log info
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE users ADD COLUMN total_quizzes INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE users ADD COLUMN correct_answers INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE users ADD COLUMN total_score INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE users ADD COLUMN last_quiz_date TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE users ADD COLUMN high_score INTEGER DEFAULT 0');
      await db.execute('UPDATE users SET high_score = total_score WHERE high_score < total_score OR high_score IS NULL');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE users ADD COLUMN profile_image_path TEXT');
      // Hapus kolom-kolom lama yang tidak lagi diperlukan
      await db.execute('CREATE TABLE users_temp AS SELECT id, username, hashed_password, salt, email, profile_image_path, created_at, total_quizzes, high_score, last_quiz_date FROM users');
      await db.execute('DROP TABLE users');
      await db.execute('ALTER TABLE users_temp RENAME TO users');
    }
  }

  // Operasi Pengguna
  Future<User> createUser(User user) async {
    final db = await database;
    logger.d('Creating new user: ${user.username}'); // Log debug
    
    try {
      // Mulai transaksi
      return await db.transaction((txn) async {
        // Periksa apakah username sudah ada di dalam transaksi
        final existingUser = await txn.query(
          'users',
          where: 'username = ?',
          whereArgs: [user.username],
        );

        if (existingUser.isNotEmpty) {
          throw Exception('Username already exists');
        }

        final id = await txn.insert('users', user.toMap());
        logger.i('User created with ID: $id'); // Log info
        return user.id == null ? User.fromMap({...user.toMap(), 'id': id}) : user;
      });
    } catch (e) {
      logger.e('Error creating user: $e'); // Log error
      rethrow;
    }
  }

  Future<User?> getUser(String username) async {
    final db = await database;
    logger.d('Fetching user: $username'); // Log debug
    
    try {
      final maps = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      if (maps.isEmpty) {
        logger.w('User not found: $username'); // Log peringatan
        return null;
      }
      
      logger.i('User found: $username'); // Log info
      return User.fromMap(maps.first);
    } catch (e) {
      logger.e('Error fetching user: $e'); // Log error
      rethrow;
    }
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<bool> usernameExists(String username, {int? excludeId}) async {
    final db = await database;
    String whereClause = 'username = ?';
    List<dynamic> whereArgs = [username];
    
    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }
    
    final result = await db.query(
      'users',
      where: whereClause,
      whereArgs: whereArgs,
    );
    return result.isNotEmpty;
  }

  Future<User> updateUser(User user) async {
    final db = await database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
    return user;
  }

  Future<User> updateUserScore(User user, int quizScore) async {
    // Ambil data pengguna saat ini untuk memastikan kita memiliki skor tertinggi terbaru
    final currentUser = await getUserById(user.id!);
    if (currentUser == null) throw Exception('User not found');

    // Hitung nilai baru
    final newTotalQuizzes = currentUser.totalQuizzes + 1;
    final newHighScore = quizScore > currentUser.highScore ? quizScore : currentUser.highScore;

    // Buat pengguna yang diperbarui
    final updatedUser = currentUser.copyWith(
      highScore: newHighScore,
      totalQuizzes: newTotalQuizzes,
      lastQuizDate: DateTime.now(),
    );

    // Perbarui di database
    await updateUser(updatedUser);
    return updatedUser;
  }

  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<User>> getLeaderboard({
    int limit = 10,
    String? searchQuery,
    String sortBy = 'high_score',
    bool ascending = false,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    // Tambahkan fungsionalitas pencarian
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause = 'username LIKE ?';
      whereArgs = ['%$searchQuery%'];
    }

    // Validasi kolom untuk pengurutan
    final validColumns = ['high_score', 'username', 'total_quizzes', 'last_quiz_date'];
    if (!validColumns.contains(sortBy)) {
      sortBy = 'high_score';
    }

    final maps = await db.query(
      'users',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: '$sortBy ${ascending ? 'ASC' : 'DESC'}',
      limit: limit,
    );

    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}