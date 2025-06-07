import '../models/game_state.dart';
import '../models/question.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class GameController {
  static final _log = Logger('GameController');
  final GameState gameState = GameState();
  Question? currentQuestion;
  
  // Question pool for demo purposes
  final List<Question> _questionPool = [
    Question(
      question: 'Is Flutter a UI framework?',
      correctAnswer: 'True',
      difficulty: 'easy',
      category: 'Programming',
      questionId: 'flutter_ui_framework'.hashCode,
    ),
    Question(
      question: 'Was World War II fought between 1939-1945?',
      correctAnswer: 'True',
      difficulty: 'easy',
      category: 'History',
      questionId: 'ww2_dates'.hashCode,
    ),
    Question(
      question: 'Is Python a programming language?',
      correctAnswer: 'True',
      difficulty: 'easy',
      category: 'Programming',
      questionId: 'python_language'.hashCode,
    ),
    Question(
      question: 'Is the Earth flat?',
      correctAnswer: 'False',
      difficulty: 'easy',
      category: 'Science',
      questionId: 'earth_flat'.hashCode,
    ),
    Question(
      question: 'Did humans land on the moon in 1969?',
      correctAnswer: 'True',
      difficulty: 'medium',
      category: 'History',
      questionId: 'moon_landing'.hashCode,
    ),
  ];

  /// Start a new game
  Future<void> startGame([BuildContext? context]) async {
    try {
      // Initialize game state
      await gameState.initializeWithUser();
      gameState.isGameActive = true;
      
      // Fetch first question
      await fetchNewQuestion();
      
      _log.info('Game started successfully');
    } catch (e) {
      _log.severe('Error starting game: $e');
      rethrow;
    }
  }

  /// Fetch a new question that hasn't been used yet
  Future<bool> fetchNewQuestion() async {
    try {
      // Get questions for current difficulty that haven't been used
      final availableQuestions = _questionPool
          .where((q) => 
              q.difficulty == gameState.difficulty && 
              !gameState.isQuestionUsed(q.questionId))
          .toList();

      if (availableQuestions.isEmpty) {
        // If no questions available for current difficulty, try any difficulty
        final anyAvailableQuestions = _questionPool
            .where((q) => !gameState.isQuestionUsed(q.questionId))
            .toList();
        
        if (anyAvailableQuestions.isEmpty) {
          _log.warning('No more questions available');
          return false;
        }
        
        // Use first available question from any difficulty
        currentQuestion = anyAvailableQuestions.first;
      } else {
        // Use first available question from current difficulty
        currentQuestion = availableQuestions.first;
      }

      // Mark question as used
      gameState.addUsedQuestion(currentQuestion!.questionId);
      
      _log.info('Fetched question: ${currentQuestion!.question}');
      return true;
    } catch (e) {
      _log.severe('Error fetching question: $e');
      return false;
    }
  }

  /// Process player's answer
  void answerQuestion(String answer, [BuildContext? context]) {
    if (currentQuestion == null) {
      _log.warning('No current question to answer');
      return;
    }

    if (!gameState.isGameActive) {
      _log.warning('Game is not active, ignoring answer');
      return;
    }

    _log.info('Player answered: $answer, Correct: ${currentQuestion!.correctAnswer}');

    if (answer == currentQuestion!.correctAnswer) {
      // Correct answer - add points and check level up
      gameState.correctAnswer(context);
      _log.info('Correct! Score: ${gameState.score}, Level: ${gameState.level}');
    } else {
      // Wrong answer - lose a life
      gameState.wrongAnswer();
      _log.info('Wrong! Lives remaining: ${gameState.lives}');
      
      // Check if game should end
      if (gameState.lives <= 0) {
        endGame();
        _log.info('Game Over! Final score: ${gameState.score}');
      }
    }
  }

  /// Check if the game should end
  bool shouldEndGame() {
    return gameState.lives <= 0 || !gameState.isGameActive;
  }

  /// End the current game
  void endGame() {
    gameState.isGameActive = false;
    
    // Update high score if needed
    if (gameState.score > gameState.highScore) {
      gameState.highScore = gameState.score;
    }
    
    // Save score to database
    gameState.saveScore().catchError((e) {
      _log.severe('Error saving score: $e');
    });
    
    _log.info('Game ended - Final Score: ${gameState.score}, High Score: ${gameState.highScore}');
  }

  /// Reset game to initial state
  Future<void> resetGame([BuildContext? context]) async {
    try {
      // Save current score before reset if game was active
      if (gameState.isGameActive && gameState.score > 0) {
        gameState.saveScore();
      }
      
      // Check if context is still valid before using it
      if (context != null && context.mounted) {
        // Reset game state with valid context
        gameState.reset(context);
      } else {
        // Reset game state without context
        gameState.reset(null);
      }
      
      // Clear current question
      currentQuestion = null;
      
      _log.info('Game reset successfully');
    } catch (e) {
      _log.severe('Error resetting game: $e');
      rethrow;
    }
  }

  /// Get current game statistics
  Map<String, dynamic> getGameStats() {
    return {
      ...gameState.getGameStats(),
      'currentQuestion': currentQuestion?.question,
      'questionsUsed': gameState.usedQuestionsByDifficulty.values
          .fold<int>(0, (sum, questions) => sum + questions.length),
    };
  }

  /// Check if there are more questions available
  bool hasQuestionsAvailable() {
    return _questionPool.any((q) => !gameState.isQuestionUsed(q.questionId));
  }

  /// Get progress information
  Map<String, dynamic> getProgress() {
    return {
      'level': gameState.level,
      'difficulty': gameState.difficulty,
      'correctInLevel': gameState.correctAnswersInLevel,
      'questionsPerLevel': GameState.questionsPerLevel,
      'progress': gameState.getLevelProgress(),
      'questionsToLevelUp': gameState.questionsToLevelUp,
    };
  }

  /// Get life status
  Map<String, dynamic> getLifeStatus() {
    final livesColor = gameState.getLivesColor();
    return {
      'lives': gameState.lives,
      'maxLives': 5,
      'survivalRate': gameState.getSurvivalRate(),
      'livesColor': livesColor.toARGB32(),
      'isGameOver': gameState.isGameOver,
    };
  }

  /// Pause game
  void pauseGame() {
    gameState.isGameActive = false;
    _log.info('Game paused');
  }

  /// Resume game
  void resumeGame() {
    if (gameState.lives > 0) {
      gameState.isGameActive = true;
      _log.info('Game resumed');
    } else {
      _log.warning('Cannot resume game - no lives remaining');
    }
  }

  /// Get formatted game status
  String getGameStatus() {
    if (!gameState.isGameActive && gameState.lives <= 0) {
      return 'Game Over';
    } else if (!gameState.isGameActive) {
      return 'Paused';
    } else {
      return 'Active';
    }
  }

  /// Add a custom question to the pool (for testing or expansion)
  void addQuestion(Question question) {
    _questionPool.add(question);
    _log.info('Added custom question: ${question.question}');
  }

  /// Get remaining questions count
  int getRemainingQuestionsCount() {
    return _questionPool
        .where((q) => !gameState.isQuestionUsed(q.questionId))
        .length;
  }

  /// Force level up (for testing purposes)
  void forceLevelUp([BuildContext? context]) {
    gameState.levelUp(context);
    _log.info('Forced level up to: ${gameState.level}');
  }
}