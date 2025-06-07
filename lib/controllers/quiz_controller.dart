import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../models/question.dart';
import '../models/game_state.dart';

class QuizController {
  static final _log = Logger('QuizController');
  static const String _baseUrl = 'https://opentdb.com/api.php';
  final GameState _gameState = GameState();
  Question? _currentQuestion;
  final Map<String, List<Question>> _questionBuffers = {
    'easy': [],
    'medium': [],
    'hard': [],
  };
  final int _maxRetries = 10;

  GameState get gameState => _gameState;
  Question? get currentQuestion => _currentQuestion;

  Future<bool> fetchQuestion() async {
    // Try to get question from buffer first
    Question? uniqueQuestion = _getUniqueQuestionFromBuffer();

    if (uniqueQuestion != null) {
      _currentQuestion = uniqueQuestion;
      _gameState.addUsedQuestion(uniqueQuestion.questionId);
      _log.info('Loaded question from buffer: ${uniqueQuestion.question}');
      return true;
    }

    // If not in buffer, fetch from API
    bool success = await _fetchNewQuestions();
    if (!success) {
      _log.warning('API fetch failed, fallback to dummy question');
      // Create a unique dummy question based on current difficulty
      final dummyQuestion = _createDummyQuestion();
      if (dummyQuestion != null) {
        _currentQuestion = dummyQuestion;
        _gameState.addUsedQuestion(dummyQuestion.questionId);
        return true;
      }
      return false;
    }

    return success;
  }

  Question? _createDummyQuestion() {
    final usedIds = _gameState.usedQuestionsByDifficulty[_gameState.difficulty] ?? {};
    int attemptCount = 0;
    String baseQuestion = '';
    
    // Try to create a unique dummy question
    do {
      switch (_gameState.difficulty) {
        case 'easy':
          baseQuestion = 'Was World War II fought between 1939-1945?';
          break;
        case 'medium':
          baseQuestion = 'Did the Industrial Revolution begin in England?';
          break;
        case 'hard':
          baseQuestion = 'Was the Byzantine Empire a direct continuation of the Roman Empire?';
          break;
        default:
          baseQuestion = 'Is history the study of past events?';
      }
      
      // Add attempt count to make question unique
      final questionText = attemptCount > 0 ? '$baseQuestion ($attemptCount)' : baseQuestion;
      final questionId = questionText.hashCode;
      
      if (!usedIds.contains(questionId)) {
        return Question(
          question: questionText,
          correctAnswer: 'True',
          difficulty: _gameState.difficulty,
          category: 'History',
          questionId: questionId,
        );
      }
      
      attemptCount++;
    } while (attemptCount < 5);
    
    return null;
  }

  Future<bool> _fetchNewQuestions() async {
    int retries = 0;

    while (retries < _maxRetries) {
      try {
        final currentDifficulty = _gameState.difficulty;
        final usedQuestions = _gameState.usedQuestionsByDifficulty[currentDifficulty] ?? {};
        
        // If difficulty is hard, use predefined questions instead of API
        if (currentDifficulty == 'hard') {
          final hardQuestions = _getHardHistoryQuestions()
              .where((q) => !_gameState.isQuestionUsed(q.questionId))
              .toList();
          
          if (hardQuestions.isNotEmpty) {
            _questionBuffers[currentDifficulty]?.addAll(hardQuestions);
            _log.info('Added ${hardQuestions.length} predefined hard questions to buffer.');
            
            Question? uniqueQuestion = _getUniqueQuestionFromBuffer();
            if (uniqueQuestion != null) {
              _currentQuestion = uniqueQuestion;
              _gameState.addUsedQuestion(uniqueQuestion.questionId);
              _log.info('Loaded predefined hard question: ${uniqueQuestion.question}');
              return true;
            }
          }
          return false;
        }
        
        // For easy and medium, continue with API
        int amount = min(10, 50 - usedQuestions.length);
        if (amount <= 0) {
          _log.warning('All questions for difficulty $currentDifficulty have been used.');
          return false;
        }

        _log.info('Fetching $amount questions from API for difficulty $currentDifficulty...');
        final response = await http.get(
          Uri.parse(
              '$_baseUrl?amount=$amount&category=23&type=boolean&difficulty=$currentDifficulty'),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['results'] != null && data['results'].isNotEmpty) {
            List<Question> newQuestions = (data['results'] as List)
                .map((json) => Question.fromJson(json))
                .where((q) => !_gameState.isQuestionUsed(q.questionId))
                .toList();

            if (newQuestions.isEmpty) {
              _log.warning('No new unique questions in response for difficulty $currentDifficulty.');
            } else {
              _questionBuffers[currentDifficulty]?.addAll(newQuestions);
              _log.info('Added ${newQuestions.length} new questions to $currentDifficulty buffer.');
            }

            Question? uniqueQuestion = _getUniqueQuestionFromBuffer();
            if (uniqueQuestion != null) {
              _currentQuestion = uniqueQuestion;
              _gameState.addUsedQuestion(uniqueQuestion.questionId);
              _log.info('Loaded new question from API: ${uniqueQuestion.question}');
              return true;
            }
          }
        }

        retries++;
        if (retries < _maxRetries) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        _log.severe('Exception during fetch: $e');
        retries++;
        if (retries < _maxRetries) {
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }
    }

    _log.warning('Failed to fetch questions after retries.');
    return false;
  }

  /// Get predefined hard history questions
  List<Question> _getHardHistoryQuestions() {
    return [
      Question(
        question: 'The Treaty of Versailles was signed in 1919, officially ending World War I?',
        correctAnswer: 'True',
        difficulty: 'hard',
        category: 'History',
        questionId: 'hard_history_1'.hashCode,
      ),
      Question(
        question: 'The Ming Dynasty ruled China from 1368 to 1644?',
        correctAnswer: 'True',
        difficulty: 'hard',
        category: 'History',
        questionId: 'hard_history_2'.hashCode,
      ),
      Question(
        question: 'The Battle of Hastings took place in 1066?',
        correctAnswer: 'True',
        difficulty: 'hard',
        category: 'History',
        questionId: 'hard_history_3'.hashCode,
      ),
      Question(
        question: 'Cleopatra was Greek, not Egyptian?',
        correctAnswer: 'True',
        difficulty: 'hard',
        category: 'History',
        questionId: 'hard_history_4'.hashCode,
      ),
      Question(
        question: 'The Byzantine Empire fell to the Ottoman Turks in 1453?',
        correctAnswer: 'True',
        difficulty: 'hard',
        category: 'History',
        questionId: 'hard_history_5'.hashCode,
      ),
      Question(
        question: 'The Magna Carta was signed by King John in 1215?',
        correctAnswer: 'True',
        difficulty: 'hard',
        category: 'History',
        questionId: 'hard_history_6'.hashCode,
      ),
      Question(
        question: 'The Russian Revolution took place in 1917?',
        correctAnswer: 'True',
        difficulty: 'hard',
        category: 'History',
        questionId: 'hard_history_7'.hashCode,
      ),
      Question(
        question: 'The ancient city of Carthage was located in modern-day Tunisia?',
        correctAnswer: 'True',
        difficulty: 'hard',
        category: 'History',
        questionId: 'hard_history_8'.hashCode,
      ),
      Question(
        question: 'The Khmer Empire built Angkor Wat in the 12th century?',
        correctAnswer: 'True',
        difficulty: 'hard',
        category: 'History',
        questionId: 'hard_history_9'.hashCode,
      ),
      Question(
        question: 'The Aztec capital Tenochtitlan was larger than any European city when Cortés arrived?',
        correctAnswer: 'True',
        difficulty: 'hard',
        category: 'History',
        questionId: 'hard_history_10'.hashCode,
      ),
    ];
  }

  Question? _getUniqueQuestionFromBuffer() {
    final currentDifficulty = _gameState.difficulty;
    final buffer = _questionBuffers[currentDifficulty] ?? [];
    
    for (int i = 0; i < buffer.length; i++) {
      final question = buffer[i];
      if (!_gameState.isQuestionUsed(question.questionId)) {
        buffer.removeAt(i);
        return question;
      }
    }
    return null;
  }

  Future<void> startGame() async {
    _gameState.isGameActive = true;
    _questionBuffers.forEach((difficulty, buffer) => buffer.clear());
    await _gameState.initializeWithUser();
    _log.info('Game started');
  }

  /// Process answer - FIXED: Now properly handles context parameter
  void answerQuestion(String answer, [BuildContext? context]) {
    if (_currentQuestion == null) return;

    _log.info('Player answered: $answer, Correct answer: ${_currentQuestion!.correctAnswer}');

    if (answer == _currentQuestion!.correctAnswer) {
      // CRITICAL FIX: Pass context to correctAnswer method
      if (context != null) {
        try {
          _gameState.correctAnswer(context);
        } catch (e) {
          _log.severe('Error calling correctAnswer with context: $e');
          // Fallback: manually update score without context
          _manualCorrectAnswer();
        }
      } else {
        // Fallback: manually update score without context
        _manualCorrectAnswer();
      }
      _log.info('Correct answer! Score: ${_gameState.score}');
    } else {
      _gameState.wrongAnswer();
      _log.info('Wrong answer! Lives remaining: ${_gameState.lives}');
    }

    // Log current game state for debugging
    _log.fine('Current state - Score: ${_gameState.score}, Lives: ${_gameState.lives}, Level: ${_gameState.level}');
  }

  /// Manual score update method
  void _manualCorrectAnswer() {
    _gameState.score += _gameState.getDifficultyPoints();
    _gameState.correctAnswersInLevel++;
    _gameState.totalQuestionsAsked++;
    
    // Manual level up check
    if (_gameState.correctAnswersInLevel >= GameState.questionsPerLevel) {
      _gameState.level++;
      _gameState.correctAnswersInLevel = 0;

      // Change difficulty
      if (_gameState.difficulty == 'easy') {
        _gameState.difficulty = 'medium';
      } else if (_gameState.difficulty == 'medium') {
        _gameState.difficulty = 'hard';
      }
    }
  }

  /// Reset game with proper context handling
  void resetGame([BuildContext? context]) {
    // Update high score first
    if (_gameState.score > _gameState.highScore) {
      _gameState.highScore = _gameState.score;
    }

    if (context != null) {
      try {
        _gameState.reset(context);
      } catch (e) {
        _log.severe('Error calling reset with context: $e');
        // Fallback: manual reset
        _manualReset();
      }
    } else {
      // Manual reset without context
      _manualReset();
    }
    
    _currentQuestion = null;
    _questionBuffers.forEach((difficulty, buffer) => buffer.clear());
    _log.info('Game reset - High Score: ${_gameState.highScore}');
  }

  /// Manual reset method
  void _manualReset() {
    _gameState.score = 0;
    _gameState.lives = 5;
    _gameState.level = 1;
    _gameState.correctAnswersInLevel = 0;
    _gameState.difficulty = 'easy';
    _gameState.isGameActive = false;
    _gameState.usedQuestionsByDifficulty = {
      'easy': <int>{},
      'medium': <int>{},
      'hard': <int>{},
    };
    _gameState.totalQuestionsAsked = 0;
  }

  /// Get comprehensive question statistics
  Map<String, int> getQuestionStats() {
    final totalUsedQuestions = _gameState.usedQuestionsByDifficulty.values
        .fold<int>(0, (sum, questions) => sum + questions.length);
        
    return {
      'total_asked': _gameState.totalQuestionsAsked,
      'unique_questions': totalUsedQuestions,
      'buffer_size': _questionBuffers.values.fold<int>(0, (sum, buffer) => sum + buffer.length),
      'current_score': _gameState.score,
      'high_score': _gameState.highScore,
      'lives_remaining': _gameState.lives,
    };
  }

  /// Check if game should end
  bool shouldEndGame() {
    return _gameState.lives <= 0 || !_gameState.isGameActive;
  }

  /// Get current game performance
  Map<String, dynamic> getGamePerformance() {
    return {
      'survival_rate': _gameState.getSurvivalRate(),
      'current_difficulty': _gameState.difficulty,
      'level': _gameState.level,
      'current_score': _gameState.score,
      'high_score': _gameState.highScore,
    };
  }

  /// ADDED: Method to properly end game
  void endGame() {
    _gameState.isGameActive = false;
    _log.info('Game ended - Final Score: ${_gameState.score}, High Score: ${_gameState.highScore}');
  }
}