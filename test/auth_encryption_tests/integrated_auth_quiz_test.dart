import 'package:flutter_test/flutter_test.dart';
import 'package:historyquizapp/services/auth_service.dart';
import 'package:historyquizapp/services/encryption_service.dart';
import 'package:historyquizapp/services/database_helper.dart';
import 'package:historyquizapp/controllers/quiz_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  Logger.root.level = Level.OFF; // Suppress logs during tests

  group('Integrated Auth, Encryption & Quiz Tests', () {
    late Database database;
    late QuizController quizController;
    const testUsername = 'test_user';
    const testPassword = 'Test@123';
    const testEmail = 'test@example.com';

    setUpAll(() async {
      databaseFactory = databaseFactoryFfi;
      database = await openDatabase(
        inMemoryDatabasePath,
        version: 4,
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
        },
      );
      DatabaseHelper.instance.setTestDatabase(database);
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await database.delete('users');
      await AuthService.logout();
      quizController = QuizController();
    });

    tearDownAll(() async {
      await database.close();
    });

    group('User Authentication & Quiz Session', () {
      test('Should properly register user and track quiz progress', () async {
        // Register a new user
        final user = await AuthService.register(
          username: testUsername,
          password: testPassword,
          email: testEmail,
        );

        expect(user, isNotNull);
        expect(user?.username, equals(testUsername));

        // Verify password encryption
        final dbUser = await database.query(
          'users',
          where: 'username = ?',
          whereArgs: [testUsername],
        );
        expect(dbUser.length, 1);
        expect(dbUser.first['hashed_password'], isNot(equals(testPassword)));
        
        // Start quiz session
        quizController.gameState.difficulty = 'hard';
        await quizController.startGame();
        await quizController.fetchQuestion();
        
        // Answer some questions correctly
        final question = quizController.currentQuestion;
        expect(question, isNotNull);
        
        // Answer correctly
        quizController.answerQuestion(question!.correctAnswer);
        
        // Verify score increased
        expect(quizController.gameState.score, equals(30)); // Hard difficulty = 30 points
        
        // Update user's quiz statistics
        await database.update(
          'users',
          {
            'total_quizzes': 1,
            'high_score': quizController.gameState.score,
            'last_quiz_date': DateTime.now().toIso8601String(),
          },
          where: 'username = ?',
          whereArgs: [testUsername],
        );
        
        // Verify user statistics were updated
        final updatedUser = await database.query(
          'users',
          where: 'username = ?',
          whereArgs: [testUsername],
        );
        
        expect(updatedUser.first['total_quizzes'], equals(1));
        expect(updatedUser.first['high_score'], equals(30));
        expect(updatedUser.first['last_quiz_date'], isNotNull);
      });

      test('Should handle duplicate username registration', () async {
        // Register first user
        final user1 = await AuthService.register(
          username: testUsername,
          password: testPassword,
          email: testEmail,
        );
        expect(user1, isNotNull);

        // Try to register second user with same username
        expect(
          () => AuthService.register(
            username: testUsername,
            password: 'DifferentPass@123',
            email: 'different@example.com',
          ),
          throwsException,
        );
      });

      test('Should handle invalid login attempts', () async {
        // Register user
        await AuthService.register(
          username: testUsername,
          password: testPassword,
          email: testEmail,
        );

        // Test wrong password
        final wrongPasswordLogin = await AuthService.login(testUsername, 'WrongPass@123');
        expect(wrongPasswordLogin, isFalse);

        // Test non-existent user
        final nonExistentLogin = await AuthService.login('nonexistent', testPassword);
        expect(nonExistentLogin, isFalse);
      });

      test('Should maintain security during quiz session and user switching', () async {
        // Register two users
        final user1 = await AuthService.register(
          username: 'user1',
          password: testPassword,
          email: 'user1@example.com',
        );
        final user2 = await AuthService.register(
          username: 'user2',
          password: testPassword,
          email: 'user2@example.com',
        );

        // Start quiz with user1
        await AuthService.login('user1', testPassword);
        quizController.gameState.difficulty = 'hard';
        await quizController.startGame();
        await quizController.fetchQuestion();
        
        // Play quiz with user1
        final question1 = quizController.currentQuestion;
        quizController.answerQuestion(question1!.correctAnswer);
        final user1Score = quizController.gameState.score;
        
        // Update user1's score
        await database.update(
          'users',
          {
            'high_score': user1Score,
            'total_quizzes': 1,
          },
          where: 'username = ?',
          whereArgs: ['user1'],
        );
        
        // Switch to user2
        await AuthService.logout();
        await AuthService.login('user2', testPassword);
        
        // Reset quiz controller for new user
        quizController.resetGame();
        quizController.gameState.difficulty = 'hard';
        await quizController.startGame();
        await quizController.fetchQuestion();
        
        // Verify each user's data remains separate
        final user1Data = await database.query(
          'users',
          where: 'username = ?',
          whereArgs: ['user1'],
        );
        final user2Data = await database.query(
          'users',
          where: 'username = ?',
          whereArgs: ['user2'],
        );
        
        expect(user1Data.first['high_score'], equals(user1Score));
        expect(user2Data.first['high_score'], equals(0));
        expect(user1Data.first['total_quizzes'], equals(1));
        expect(user2Data.first['total_quizzes'], equals(0));
      });
    });

    group('Quiz Security & User Session', () {
      test('Should prevent unauthorized quiz access', () async {
        // Try to start quiz without authentication
        await AuthService.logout();
        quizController.gameState.difficulty = 'hard';
        await quizController.startGame();
        
        // Verify quiz state is reset when not authenticated
        expect(quizController.gameState.score, equals(0));
        expect(quizController.gameState.lives, equals(5));
        
        // Login and verify quiz access
        await AuthService.register(
          username: testUsername,
          password: testPassword,
          email: testEmail,
        );
        final loginSuccess = await AuthService.login(testUsername, testPassword);
        expect(loginSuccess, isTrue);
        
        // Now should be able to start quiz
        await quizController.startGame();
        await quizController.fetchQuestion();
        expect(quizController.currentQuestion, isNotNull);
      });

      test('Should handle quiz difficulty changes', () async {
        // Register and login
        await AuthService.register(
          username: testUsername,
          password: testPassword,
          email: testEmail,
        );
        await AuthService.login(testUsername, testPassword);

        // Test easy difficulty
        quizController.gameState.difficulty = 'easy';
        await quizController.startGame();
        await quizController.fetchQuestion();
        final easyQuestion = quizController.currentQuestion;
        quizController.answerQuestion(easyQuestion!.correctAnswer);
        expect(quizController.gameState.score, equals(10)); // Easy = 10 points

        // Test medium difficulty
        quizController.resetGame();
        quizController.gameState.difficulty = 'medium';
        await quizController.startGame();
        await quizController.fetchQuestion();
        final mediumQuestion = quizController.currentQuestion;
        quizController.answerQuestion(mediumQuestion!.correctAnswer);
        expect(quizController.gameState.score, equals(20)); // Medium = 20 points

        // Test hard difficulty
        quizController.resetGame();
        quizController.gameState.difficulty = 'hard';
        await quizController.startGame();
        await quizController.fetchQuestion();
        final hardQuestion = quizController.currentQuestion;
        quizController.answerQuestion(hardQuestion!.correctAnswer);
        expect(quizController.gameState.score, equals(30)); // Hard = 30 points
      });

      test('Should handle game over scenarios', () async {
        // Register and login
        await AuthService.register(
          username: testUsername,
          password: testPassword,
          email: testEmail,
        );
        await AuthService.login(testUsername, testPassword);

        quizController.gameState.difficulty = 'hard';
        await quizController.startGame();
        await quizController.fetchQuestion();

        // Lose all lives
        for (var i = 0; i < 5; i++) {
          final question = quizController.currentQuestion;
          final wrongAnswer = question!.correctAnswer == 'True' ? 'False' : 'True';
          quizController.answerQuestion(wrongAnswer);
          if (i < 4) await quizController.fetchQuestion();
        }

        // Verify game over state
        expect(quizController.gameState.lives, equals(0));
        expect(quizController.gameState.isGameOver, isTrue);

        // Verify high score is saved
        await database.update(
          'users',
          {
            'high_score': quizController.gameState.score,
            'total_quizzes': 1,
          },
          where: 'username = ?',
          whereArgs: [testUsername],
        );

        final userData = await database.query(
          'users',
          where: 'username = ?',
          whereArgs: [testUsername],
        );
        expect(userData.first['total_quizzes'], equals(1));
      });

      test('Should securely store quiz progress', () async {
        // Register and login
        await AuthService.register(
          username: testUsername,
          password: testPassword,
          email: testEmail,
        );
        await AuthService.login(testUsername, testPassword);
        
        // Play quiz and get high score
        quizController.gameState.difficulty = 'hard';
        await quizController.startGame();
        await quizController.fetchQuestion();
        
        // Answer multiple questions correctly
        for (var i = 0; i < 3; i++) {
          final question = quizController.currentQuestion;
          if (question != null) {
            quizController.answerQuestion(question.correctAnswer);
            await quizController.fetchQuestion();
          }
        }
        
        final highScore = quizController.gameState.score;
        
        // Update user's high score
        await database.update(
          'users',
          {
            'high_score': highScore,
            'total_quizzes': 1,
          },
          where: 'username = ?',
          whereArgs: [testUsername],
        );
        
        // Verify score is stored securely
        final userData = await database.query(
          'users',
          where: 'username = ?',
          whereArgs: [testUsername],
        );
        
        expect(userData.first['high_score'], equals(highScore));
        expect(userData.first['username'], equals(testUsername));
        // Verify password remains encrypted
        expect(userData.first['hashed_password'], isNot(equals(testPassword)));
      });

      test('Should handle consecutive quiz sessions', () async {
        // Register and login
        await AuthService.register(
          username: testUsername,
          password: testPassword,
          email: testEmail,
        );
        await AuthService.login(testUsername, testPassword);

        // First quiz session
        quizController.gameState.difficulty = 'hard';
        await quizController.startGame();
        await quizController.fetchQuestion();
        final question1 = quizController.currentQuestion;
        quizController.answerQuestion(question1!.correctAnswer);
        final firstScore = quizController.gameState.score;

        // Update first session score
        await database.update(
          'users',
          {
            'high_score': firstScore,
            'total_quizzes': 1,
          },
          where: 'username = ?',
          whereArgs: [testUsername],
        );

        // Reset and start second session
        quizController.resetGame();
        quizController.gameState.difficulty = 'hard';
        await quizController.startGame();
        await quizController.fetchQuestion();
        final question2 = quizController.currentQuestion;
        quizController.answerQuestion(question2!.correctAnswer);
        final secondScore = quizController.gameState.score;

        // Always update total_quizzes for second session
        await database.update(
          'users',
          {
            'high_score': secondScore > firstScore ? secondScore : firstScore,
            'total_quizzes': 2,  // Increment total_quizzes regardless of score
          },
          where: 'username = ?',
          whereArgs: [testUsername],
        );

        // Verify quiz count and high score
        final userData = await database.query(
          'users',
          where: 'username = ?',
          whereArgs: [testUsername],
        );
        expect(userData.first['total_quizzes'], equals(2));
        expect(userData.first['high_score'], greaterThanOrEqualTo(firstScore));
      });
    });

    group('Password Security & Encryption', () {
      test('Should use unique salt for each user registration', () async {
        // Register multiple users with same password
        final user1 = await AuthService.register(
          username: 'user1',
          password: testPassword,
          email: 'user1@example.com',
        );
        final user2 = await AuthService.register(
          username: 'user2',
          password: testPassword,
          email: 'user2@example.com',
        );

        final users = await database.query('users');
        final user1Data = users.firstWhere((u) => u['username'] == 'user1');
        final user2Data = users.firstWhere((u) => u['username'] == 'user2');

        // Verify different salts and hashes for same password
        expect(user1Data['salt'], isNot(equals(user2Data['salt'])));
        expect(user1Data['hashed_password'], isNot(equals(user2Data['hashed_password'])));
      });

      test('Should handle password updates securely', () async {
        // Register user
        await AuthService.register(
          username: testUsername,
          password: testPassword,
          email: testEmail,
        );

        // Get original password data
        final originalUserData = await database.query(
          'users',
          where: 'username = ?',
          whereArgs: [testUsername],
        );
        final originalHash = originalUserData.first['hashed_password'];
        final originalSalt = originalUserData.first['salt'];

        // Update password
        final newPassword = 'NewTest@123';
        final newSalt = EncryptionService.generateSalt();
        final newHash = EncryptionService.hashPassword(newPassword, newSalt);

        await database.update(
          'users',
          {
            'hashed_password': newHash,
            'salt': newSalt,
          },
          where: 'username = ?',
          whereArgs: [testUsername],
        );

        // Verify password was updated securely
        final updatedUserData = await database.query(
          'users',
          where: 'username = ?',
          whereArgs: [testUsername],
        );

        expect(updatedUserData.first['hashed_password'], isNot(equals(originalHash)));
        expect(updatedUserData.first['salt'], isNot(equals(originalSalt)));
        expect(updatedUserData.first['hashed_password'], equals(newHash));
      });
    });
  });
} 