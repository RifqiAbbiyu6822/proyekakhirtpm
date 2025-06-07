// Fixed Auth Service
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'database_helper.dart';
import 'encryption_service.dart';
import 'package:logger/logger.dart';

class AuthService {
  static const String _sessionKey = 'user_session';
  static User? _currentUser;
  static bool _isInitializing = false;
  static bool _isInitialized = false;
  static final _logger = Logger();

  // Get current logged in user
  static User? get currentUser => _currentUser;

  // Check if auth service is initialized
  static bool get isInitialized => _isInitialized;

  // Update current user (for profile updates)
  static Future<void> updateCurrentUser(User user) async {
    _logger.d('Updating current user: ${user.username}');
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, user.username);
  }

  // Validate username
  static String? validateUsername(String username) {
    username = username.trim();
    if (username.isEmpty) {
      return 'Username cannot be empty';
    }
    if (username.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  // Validate password
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password cannot be empty';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Validate email
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return null; // Email is optional
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Initialize auth service (call this at app startup)
  static Future<void> initialize() async {
    if (_isInitialized || _isInitializing) {
      return;
    }

    _logger.i('Initializing auth service...');
    _isInitializing = true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString(_sessionKey);
      
      if (username != null) {
        _logger.d('Found saved session for user: $username');
        try {
          final user = await DatabaseHelper.instance.getUser(username);
          if (user != null) {
            _logger.i('Successfully restored user session: ${user.username}');
            _currentUser = user;
          } else {
            _logger.w('User from saved session not found, clearing session');
            await prefs.remove(_sessionKey);
          }
        } catch (e) {
          _logger.e('Error restoring session: $e');
          await prefs.remove(_sessionKey);
        }
      } else {
        _logger.d('No saved session found');
      }
    } catch (e) {
      _logger.e('Auth initialization error: $e');
    } finally {
      _isInitializing = false;
      _isInitialized = true;
      _logger.i('Auth service initialization complete. Current user: ${_currentUser?.username ?? "None"}');
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    // Wait for initialization if needed
    if (!_isInitialized) {
      await initialize();
    }

    _logger.d('Checking login status. Current user: ${_currentUser?.username ?? "None"}');
    return _currentUser != null;
  }

  // Check if current session is valid
  static Future<bool> validateSession() async {
    try {
      _logger.i('Validating session...');
      
      // Wait for initialization if needed
      if (!_isInitialized) {
        await initialize();
      }

      // First check if we have a current user in memory
      if (_currentUser == null) {
        _logger.w('No current user in memory');
        await logout(); // Clear any stale session data
        return false;
      }

      // Then verify the session in SharedPreferences matches current user
      try {
        final prefs = await SharedPreferences.getInstance();
        final sessionUsername = prefs.getString(_sessionKey);
        
        if (sessionUsername == null) {
          _logger.w('No session found in SharedPreferences');
          await logout();
          return false;
        }
        
        if (sessionUsername != _currentUser!.username) {
          _logger.w('Session username mismatch: stored=$sessionUsername, current=${_currentUser!.username}');
          await logout();
          return false;
        }

        // Finally verify user still exists in database and data is fresh
        if (_currentUser?.id != null) {
          _logger.d('Verifying user in database: ${_currentUser!.username}');
          try {
            final user = await DatabaseHelper.instance.getUserById(_currentUser!.id!);
            if (user != null) {
              // Verify critical data hasn't changed
              if (user.username != _currentUser!.username || 
                  user.hashedPassword != _currentUser!.hashedPassword ||
                  user.salt != _currentUser!.salt) {
                _logger.w('User data mismatch in database');
                await logout();
                return false;
              }
              
              _logger.i('User verified in database');
              _currentUser = user; // Update with fresh data
              return true;
            } else {
              _logger.w('User no longer exists in database');
              await logout();
              return false;
            }
          } catch (e) {
            _logger.e('Error verifying user in database: $e');
            await logout();
            return false;
          }
        }

        _logger.w('Invalid user ID');
        await logout();
        return false;
      } catch (e) {
        _logger.e('Error accessing SharedPreferences: $e');
        await logout();
        return false;
      }
    } catch (e) {
      _logger.e('Session validation error: $e');
      await logout();
      return false;
    }
  }

  // Register new user
  static Future<User?> register({
    required String username,
    required String password,
    String? email,
  }) async {
    _logger.i('Starting registration for user: $username');
    
    try {
      // Validate input
      final usernameError = validateUsername(username);
      if (usernameError != null) {
        throw Exception(usernameError);
      }

      final passwordError = validatePassword(password);
      if (passwordError != null) {
        throw Exception(passwordError);
      }

      final emailError = validateEmail(email);
      if (emailError != null) {
        throw Exception(emailError);
      }

      // Check if username already exists
      final exists = await DatabaseHelper.instance.usernameExists(username);
      if (exists) {
        _logger.w('Username already exists: $username');
        throw Exception('Username already exists');
      }

      _logger.i('Generating salt and hashing password...');
      // Generate salt and hash password
      final salt = EncryptionService.generateSalt();
      final hashedPassword = EncryptionService.hashPassword(password, salt);

      // Create user
      final user = User(
        username: username.trim(),
        hashedPassword: hashedPassword,
        salt: salt,
        email: email?.trim(),
      );

      _logger.i('Saving user to database...');
      // Save to database
      final createdUser = await DatabaseHelper.instance.createUser(user);
      _logger.i('User created successfully: ${createdUser.username}');
      
      // Set as current user and save session after successful registration
      _currentUser = createdUser;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, createdUser.username);
      _logger.i('Session saved for new user: ${createdUser.username}');
      
      return createdUser;
    } catch (e) {
      _logger.e('Registration error: $e');
      rethrow; // Rethrow to let caller handle specific errors
    }
  }

  // Login user
  static Future<bool> login(String username, String password) async {
    _logger.i('Attempting login for user: $username');
    
    try {
      // Validate input
      final usernameError = validateUsername(username);
      if (usernameError != null) {
        throw Exception(usernameError);
      }

      final passwordError = validatePassword(password);
      if (passwordError != null) {
        throw Exception(passwordError);
      }

      final user = await DatabaseHelper.instance.getUser(username.trim());
      if (user == null) {
        _logger.w('User not found: $username');
        return false;
      }

      final isValid = EncryptionService.verifyPassword(
        password,
        user.hashedPassword,
        user.salt,
      );

      if (isValid) {
        _logger.i('Password verified, logging in user: $username');
        
        // Set current user first
        _currentUser = user;
        
        try {
          // Then try to save session
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_sessionKey, username.trim());
          _logger.i('Session saved for user: $username');
          
          // Verify session was saved correctly
          final savedUsername = prefs.getString(_sessionKey);
          if (savedUsername != username.trim()) {
            _logger.w('Session verification failed');
            _currentUser = null;
            return false;
          }
          
          return true;
        } catch (e) {
          _logger.e('Error saving session: $e');
          _currentUser = null;
          return false;
        }
      }
      
      _logger.w('Invalid password for user: $username');
      return false;
    } catch (e) {
      _logger.e('Login error: $e');
      // Make sure to clean up if login fails
      _currentUser = null;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_sessionKey);
      } catch (e) {
        _logger.e('Error cleaning up failed login: $e');
      }
      rethrow;
    }
  }

  // Logout user
  static Future<void> logout() async {
    _logger.i('Logging out user: ${_currentUser?.username ?? "None"}');
    try {
      _currentUser = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      _logger.i('Session cleared successfully');
    } catch (e) {
      _logger.e('Logout error: $e');
    }
  }

  // Update user stats after quiz completion
  static Future<void> updateUserStats({
    required int score,
  }) async {
    if (_currentUser == null) return;

    try {
      final updatedUser = _currentUser!.copyWith(
        totalQuizzes: _currentUser!.totalQuizzes + 1,
        highScore: score > _currentUser!.highScore ? score : _currentUser!.highScore,
        lastQuizDate: DateTime.now(),
      );

      await DatabaseHelper.instance.updateUser(updatedUser);
      _currentUser = updatedUser;
    } catch (e) {
      _logger.e('Error updating user stats: $e');
    }
  }

  // Refresh current user data from database
  static Future<void> refreshCurrentUser() async {
    if (_currentUser?.id == null) return;

    try {
      final refreshedUser = await DatabaseHelper.instance.getUserById(_currentUser!.id!);
      if (refreshedUser != null) {
        _currentUser = refreshedUser;
      }
    } catch (e) {
      _logger.e('Error refreshing user data: $e');
    }
  }

  // Get user's rank in leaderboard
  static Future<int?> getUserRank() async {
    if (_currentUser == null) return null;

    try {
      final leaderboard = await DatabaseHelper.instance.getLeaderboard(limit: 1000);
      for (int i = 0; i < leaderboard.length; i++) {
        if (leaderboard[i].id == _currentUser!.id) {
          return i + 1; // Return 1-based rank
        }
      }
      return null;
    } catch (e) {
      _logger.e('Error getting user rank: $e');
      return null;
    }
  }

  // Clear all user data (for debugging/testing)
  static Future<void> clearAllData() async {
    try {
      _currentUser = null;
      _isInitialized = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      _logger.e('Error clearing data: $e');
    }
  }
}