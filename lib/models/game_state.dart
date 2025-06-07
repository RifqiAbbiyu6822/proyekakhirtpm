import 'package:flutter/material.dart';
import '../theme/theme.dart'; 
import 'package:provider/provider.dart'; 
import '../services/database_helper.dart';
import '../services/auth_service.dart';
import 'package:logger/logger.dart';
class GameState {
  final logger = Logger();
  int score;
  int lives;
  int level;
  int correctAnswersInLevel;
  int totalQuestionsAsked;
  int highScore;
  String difficulty;
  bool isGameActive;
  Map<String, Set<int>> usedQuestionsByDifficulty;
  static const int questionsPerLevel = 5;

  GameState({
    this.score = 0,
    this.lives = 5,
    this.level = 1,
    this.correctAnswersInLevel = 0,
    this.difficulty = 'easy',
    this.isGameActive = false,
    Map<String, Set<int>>? usedQuestionsByDifficulty,
    this.totalQuestionsAsked = 0,
    this.highScore = 0,
  }) : usedQuestionsByDifficulty = usedQuestionsByDifficulty ?? {
    'easy': <int>{},
    'medium': <int>{},
    'hard': <int>{},
  };

  /// Initialize game state with user data
  Future<void> initializeWithUser() async {
    final currentUser = AuthService.currentUser;
    if (currentUser != null) {
      // Load high score from database
      final user = await DatabaseHelper.instance.getUserById(currentUser.id!);
      if (user != null) {
        highScore = user.highScore;
      }
    }
  }

  /// Save score to database
  Future<void> saveScore() async {
    final currentUser = AuthService.currentUser;
    if (currentUser != null) {
      // Update high score if needed
      if (score > highScore) {
        highScore = score;
      }

      // Update user in database
      final updatedUser = currentUser.copyWith(
        totalQuizzes: currentUser.totalQuizzes + 1,
        highScore: highScore,
        lastQuizDate: DateTime.now(),
      );
      await DatabaseHelper.instance.updateUser(updatedUser);
    }
  }

  /// Reset game state, update highScore if needed
  void reset(BuildContext? context) {
    score = 0;
    lives = 5;
    level = 1;
    correctAnswersInLevel = 0;
    difficulty = 'easy';
    isGameActive = true;
    usedQuestionsByDifficulty = {
      'easy': {},
      'medium': {},
      'hard': {},
    };
    totalQuestionsAsked = 0;

    // After resetting, notify the theme manager about difficulty change
    if (context != null) {
      try {
        final themeManager = Provider.of<DynamicThemeManager>(context, listen: false);
        themeManager.difficulty = difficulty;
      } catch (e) {
        logger.d('DynamicThemeManager not found in provider tree: $e');
      }
    }
  }

  /// Level up if enough correct answers in one level
  void levelUp(BuildContext? context) {
    if (correctAnswersInLevel >= questionsPerLevel) {
      level++;
      correctAnswersInLevel = 0;

      // Change difficulty
      if (difficulty == 'easy') {
        difficulty = 'medium';
      } else if (difficulty == 'medium') {
        difficulty = 'hard';
      }

      // Update theme based on new difficulty
      if (context != null) {
        try {
          final themeManager = Provider.of<DynamicThemeManager>(context, listen: false);
          themeManager.difficulty = difficulty;
        } catch (e) {
          logger.d('DynamicThemeManager not found in provider tree: $e');
        }
      }
    }
  }

  /// Process correct answer
  void correctAnswer(BuildContext? context) {
    score += getDifficultyPoints();
    correctAnswersInLevel++;
    totalQuestionsAsked++;
    levelUp(context);
  }

  /// Process wrong answer
  void wrongAnswer() {
    lives--;
    totalQuestionsAsked++;
    if (lives <= 0) {
      isGameActive = false;
    }
  }

  /// Add used question for current difficulty
  void addUsedQuestion(int? questionId) {
    if (questionId != null) {
      usedQuestionsByDifficulty[difficulty]?.add(questionId);
    }
  }

  /// Check if question has been used in current difficulty
  bool isQuestionUsed(int? questionId) {
    if (questionId == null) return false;
    return usedQuestionsByDifficulty[difficulty]?.contains(questionId) ?? false;
  }

  /// Get points based on difficulty
  int getDifficultyPoints() {
    switch (difficulty) {
      case 'easy':
        return 10;
      case 'medium':
        return 20;
      case 'hard':
        return 30;
      default:
        return 10;
    }
  }

  /// Get survival rate (based on initial lives vs current lives)
  double getSurvivalRate() {
    const initialLives = 5;
    return (lives / initialLives) * 100;
  }

  /// Get color based on difficulty level using DynamicAppTheme
  Color getDifficultyColor() {
    switch (difficulty) {
      case 'easy':
        return DynamicAppTheme.successColor;
      case 'medium':
        return DynamicAppTheme.warningColor;
      case 'hard':
        return DynamicAppTheme.errorColor;
      default:
        return DynamicAppTheme.successColor;
    }
  }

  /// Get difficulty icon based on current difficulty
  IconData getDifficultyIcon() {
    switch (difficulty) {
      case 'easy':
        return Icons.sentiment_satisfied;
      case 'medium':
        return Icons.sentiment_neutral;
      case 'hard':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.sentiment_satisfied;
    }
  }

  /// Get difficulty display text
  String getDifficultyDisplayText() {
    switch (difficulty) {
      case 'easy':
        return 'Mudah';
      case 'medium':
        return 'Sedang';
      case 'hard':
        return 'Sulit';
      default:
        return 'Mudah';
    }
  }

  /// Get progress percentage for current level
  double getLevelProgress() {
    return correctAnswersInLevel / questionsPerLevel.toDouble();
  }

  /// Get lives color based on remaining lives
  Color getLivesColor() {
    if (lives >= 4) {
      return DynamicAppTheme.successColor;
    } else if (lives >= 2) {
      return DynamicAppTheme.warningColor;
    } else {
      return DynamicAppTheme.errorColor;
    }
  }

  /// Get score color based on current theme
  Color getScoreColor() {
    return DynamicAppTheme.scoreColor;
  }

  /// Get level badge color
  Color getLevelBadgeColor() {
    return DynamicAppTheme.accentColor;
  }

  /// Check if game is over
  bool get isGameOver => lives <= 0;

  /// Get remaining questions to level up
  int get questionsToLevelUp => questionsPerLevel - correctAnswersInLevel;

  /// Check if ready to level up
  bool get isReadyToLevelUp => correctAnswersInLevel >= questionsPerLevel;

  /// Get game statistics as a map
  Map<String, dynamic> getGameStats() {
    return {
      'score': score,
      'highScore': highScore,
      'level': level,
      'lives': lives,
      'difficulty': difficulty,
      'totalQuestions': totalQuestionsAsked,
      'correctInLevel': correctAnswersInLevel,
      'questionsToLevelUp': questionsToLevelUp,
      'levelProgress': getLevelProgress(),
      'survivalRate': getSurvivalRate(),
      'isGameActive': isGameActive,
      'isGameOver': isGameOver,
    };
  }

  /// Create a copy of the current state
  GameState copyWith({
    int? score,
    int? lives,
    int? level,
    int? correctAnswersInLevel,
    String? difficulty,
    bool? isGameActive,
    Map<String, Set<int>>? usedQuestionsByDifficulty,
    int? totalQuestionsAsked,
    int? highScore,
  }) {
    return GameState(
      score: score ?? this.score,
      lives: lives ?? this.lives,
      level: level ?? this.level,
      correctAnswersInLevel: correctAnswersInLevel ?? this.correctAnswersInLevel,
      difficulty: difficulty ?? this.difficulty,
      isGameActive: isGameActive ?? this.isGameActive,
      usedQuestionsByDifficulty: usedQuestionsByDifficulty ?? Map<String, Set<int>>.from(this.usedQuestionsByDifficulty),
      totalQuestionsAsked: totalQuestionsAsked ?? this.totalQuestionsAsked,
      highScore: highScore ?? this.highScore,
    );
  }

  /// Convert to JSON for saving/loading
  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'lives': lives,
      'level': level,
      'correctAnswersInLevel': correctAnswersInLevel,
      'difficulty': difficulty,
      'isGameActive': isGameActive,
      'usedQuestionsByDifficulty': Map<String, List<dynamic>>.from(usedQuestionsByDifficulty.map((k, v) => MapEntry(k, v.toList()))),
      'totalQuestionsAsked': totalQuestionsAsked,
      'highScore': highScore,
    };
  }

  /// Create from JSON for saving/loading
  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      score: json['score'] as int? ?? 0,
      lives: json['lives'] as int? ?? 5,
      level: json['level'] as int? ?? 1,
      correctAnswersInLevel: json['correctAnswersInLevel'] as int? ?? 0,
      difficulty: json['difficulty'] as String? ?? 'easy',
      isGameActive: json['isGameActive'] as bool? ?? false,
      usedQuestionsByDifficulty: Map<String, Set<int>>.from(json['usedQuestionsByDifficulty'] as Map<String, List<dynamic>>? ?? {
        'easy': <int>{},
        'medium': <int>{},
        'hard': <int>{},
      }),
      totalQuestionsAsked: json['totalQuestionsAsked'] as int? ?? 0,
      highScore: json['highScore'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    return 'GameState(score: $score, lives: $lives, level: $level, difficulty: $difficulty, isGameActive: $isGameActive)';
  }
}

/// Optional: DynamicThemeManager class for managing theme state - NULL SAFE
class DynamicThemeManager extends ChangeNotifier {
  String _difficulty = 'easy';
  
  String get difficulty => _difficulty;
  
  set difficulty(String? newDifficulty) {
    final safeDifficulty = newDifficulty ?? 'easy';
    if (_difficulty != safeDifficulty) {
      _difficulty = safeDifficulty;
      notifyListeners();
    }
  }

  /// Get theme colors based on difficulty - NULL SAFE
  Color getDifficultyThemeColor() {
    switch (_difficulty) {
      case 'easy':
        return DynamicAppTheme.successColor;
      case 'medium':
        return DynamicAppTheme.warningColor;
      case 'hard':
        return DynamicAppTheme.errorColor;
      default:
        return DynamicAppTheme.successColor;
    }
  }

  /// Update theme based on game state - NULL SAFE
  void updateThemeForGameState(GameState? gameState) {
    if (gameState != null) {
      difficulty = gameState.difficulty;
    }
  }
}