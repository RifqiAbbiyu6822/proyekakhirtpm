import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import 'dart:io';
import 'package:logger/logger.dart';
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static bool _isInitializing = false;
  static final logger = Logger();

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Prevent multiple simultaneous initializations
    if (_isInitializing) {
      // Wait until initialization is complete
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_database != null) return _database!;
    }
    
    _isInitializing = true;
    logger.d('Initializing database...'); // Debug log
    
    try {
      _database = await _initDB('history_quiz.db');
      logger.i('Database initialized successfully'); // Info log
      return _database!;
    } catch (e) {
      logger.e('Error initializing database: $e'); // Error log
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      
      logger.d('Database path: $path'); // Debug log

      // Make sure the directory exists
      await Directory(dirname(path)).create(recursive: true);

      return await openDatabase(
        path,
        version: 4,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
        onOpen: (db) async {
          // Verify database structure
          await _verifyDatabaseStructure(db);
        },
      );
    } catch (e) {
      logger.e('Error in _initDB: $e'); // Error log
      rethrow;
    }
  }

  Future<void> _verifyDatabaseStructure(Database db) async {
    try {
      // Check if users table exists and has correct structure
      final tables = await db.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', 'users'],
      );

      if (tables.isEmpty) {
        logger.w('Users table not found, creating...'); // Warning log
        await _createDB(db, 4);
      } else {
        // Verify columns
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
          logger.w('Missing columns found: $missingColumns'); // Warning log
          // Handle missing columns by upgrading the database
          await _upgradeDB(db, 3, 4);
        }
      }
    } catch (e) {
      logger.e('Error verifying database structure: $e'); // Error log
      rethrow;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    logger.i('Creating database tables...'); // Info log
    
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
    
    logger.i('Database tables created successfully'); // Info log
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
      // Remove old columns that are no longer needed
      await db.execute('CREATE TABLE users_temp AS SELECT id, username, hashed_password, salt, email, profile_image_path, created_at, total_quizzes, high_score, last_quiz_date FROM users');
      await db.execute('DROP TABLE users');
      await db.execute('ALTER TABLE users_temp RENAME TO users');
    }
  }

  // User operations
  Future<User> createUser(User user) async {
    final db = await database;
    logger.d('Creating new user: ${user.username}'); // Debug log
    
    try {
      // Start a transaction
      return await db.transaction((txn) async {
        // Check if username exists within transaction
        final existingUser = await txn.query(
          'users',
          where: 'username = ?',
          whereArgs: [user.username],
        );

        if (existingUser.isNotEmpty) {
          throw Exception('Username already exists');
        }

        final id = await txn.insert('users', user.toMap());
        logger.i('User created with ID: $id'); // Info log
        return user.id == null ? User.fromMap({...user.toMap(), 'id': id}) : user;
      });
    } catch (e) {
      logger.e('Error creating user: $e'); // Error log
      rethrow;
    }
  }

  Future<User?> getUser(String username) async {
    final db = await database;
    logger.d('Fetching user: $username'); // Debug log
    
    try {
      final maps = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      if (maps.isEmpty) {
        logger.w('User not found: $username'); // Warning log
        return null;
      }
      
      logger.i('User found: $username'); // Info log
      return User.fromMap(maps.first);
    } catch (e) {
      logger.e('Error fetching user: $e'); // Error log
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
    // Get the current user data to ensure we have the latest high score
    final currentUser = await getUserById(user.id!);
    if (currentUser == null) throw Exception('User not found');

    // Calculate new values
    final newTotalQuizzes = currentUser.totalQuizzes + 1;
    final newHighScore = quizScore > currentUser.highScore ? quizScore : currentUser.highScore;

    // Create updated user
    final updatedUser = currentUser.copyWith(
      highScore: newHighScore,
      totalQuizzes: newTotalQuizzes,
      lastQuizDate: DateTime.now(),
    );

    // Update in database
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

    // Add search functionality
    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClause = 'username LIKE ?';
      whereArgs = ['%$searchQuery%'];
    }

    // Validate sort column
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