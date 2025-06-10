import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:historyquizapp/services/auth_service.dart';
import 'package:historyquizapp/services/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  
  group('AuthService', () {
    Database? database;

    setUpAll(() async {
      databaseFactory = databaseFactoryFfi;
      database = await openDatabase(inMemoryDatabasePath, version: 4,
          onCreate: (db, version) async {
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
      });
      DatabaseHelper.instance.setTestDatabase(database!);
    });

    tearDownAll(() {
      database?.close();
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await database?.delete('users');
      await AuthService.logout();
    });

    test('Harusnya berhasil mendaftarkan pengguna baru', () async {
      final user = await AuthService.register(
        username: 'pengguna_tes',
        password: 'password123',
        email: 'tes@contoh.com',
      );
      expect(user, isNotNull);
      expect(user?.username, 'pengguna_tes');
    });

    test('Login harusnya berhasil dengan kredensial yang benar', () async {
      await AuthService.register(username: 'pengguna_tes', password: 'password123');
      final success = await AuthService.login('pengguna_tes', 'password123');
      expect(success, isTrue);
      expect(AuthService.currentUser, isNotNull);
    });
    
    // ================== PERBAIKAN DI SINI ==================
    test('Login harusnya gagal dengan password yang salah', () async {
      // Arrange: Daftarkan pengguna
      await AuthService.register(username: 'pengguna_tes', password: 'password123');
      // Arrange: Logout untuk membersihkan state currentUser setelah registrasi
      await AuthService.logout(); 
      
      // Act: Coba login dengan password yang salah
      final success = await AuthService.login('pengguna_tes', 'password_salah');
      
      // Assert: Login harus gagal dan currentUser harus null
      expect(success, isFalse);
      expect(AuthService.currentUser, isNull);
    });
    // ========================================================
  });
}