import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/services.dart';
import '../controllers/quiz_controller.dart';
import '../widgets/life_indicator.dart';
import '../widgets/custom_bottom_navbar.dart';
import '../theme/theme.dart';
import '../services/auth_service.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class GameScreen extends StatefulWidget {
  final QuizController quizController;

  const GameScreen({Key? key, required this.quizController}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late AnimationController _questionAnimationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _questionAnimation;
  late Animation<Offset> _buttonAnimation;
  bool _isAnswered = false;
  String? _selectedAnswer;
  bool _isGameEnding = false; // Add flag to prevent multiple game over calls

  @override
  void initState() {
    super.initState();

    _questionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _questionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _questionAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _buttonAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });
  }

  Future<void> _initializeGame() async {
    try {
      // Validate session first
      final isValid = await AuthService.validateSession();
      if (!isValid) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Your session has expired. Please login again to continue playing.'),
              backgroundColor: DynamicAppTheme.errorColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      await _initializeTheme();
      await _loadQuestion();
    } catch (e) {
      logger.e('Error initializing game: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting game: ${e.toString()}'),
            backgroundColor: DynamicAppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _initializeTheme() async {
    await DynamicAppTheme.updateTheme();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _questionAnimationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  // NEW: Check game over condition immediately
  void _checkGameOverCondition() {
    final gameState = widget.quizController.gameState;
    
    // Check if game should end due to lives = 0 or other conditions
    if ((gameState.lives <= 0 || !gameState.isGameActive || widget.quizController.shouldEndGame()) && !_isGameEnding) {
      _isGameEnding = true;
      _endGameImmediately();
    }
  }

  // NEW: End game immediately when lives reach 0
  void _endGameImmediately() {
    if (!mounted || _isGameEnding) return;
    
    final gameState = widget.quizController.gameState;
    
    // End the game in controller
    widget.quizController.endGame();
    
    // Show game over message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Game Over! No lives remaining.'),
        backgroundColor: DynamicAppTheme.errorColor,
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Navigate to result screen after a short delay
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/result',
          arguments: {
            'finalScore': gameState.score,
            'highScore': gameState.highScore,
            'totalQuestions': gameState.totalQuestionsAsked,
            'level': gameState.level,
            'difficulty': gameState.difficulty,
          },
        );
      }
    });
  }

  Future<void> _loadQuestion() async {
    if (!mounted) return;

    // Check game over condition before loading question
    _checkGameOverCondition();
    if (_isGameEnding) return;

    try {
      // Validate session before loading question
      final isValid = await AuthService.validateSession();
      if (!isValid) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Your session has expired. Please login again to continue.'),
              backgroundColor: DynamicAppTheme.errorColor,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }
      }

      setState(() {
        _isAnswered = false;
        _selectedAnswer = null;
      });

      _questionAnimationController.reset();
      _buttonAnimationController.reset();

      bool success = await widget.quizController.fetchQuestion();

      if (!mounted) return;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load question. Please try again or restart the quiz.'),
            backgroundColor: DynamicAppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      setState(() {});

      _questionAnimationController.forward();
      await Future.delayed(const Duration(milliseconds: 300));
      _buttonAnimationController.forward();
    } catch (e) {
      logger.e('Error loading question: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading question: ${e.toString()}'),
            backgroundColor: DynamicAppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _processAnswer(String answer) async {
    try {
      // Store navigator and game state before async operations
      final navigator = Navigator.of(context);
      final gameState = widget.quizController.gameState;
      
      setState(() {
        _selectedAnswer = answer;
        _isAnswered = true;
      });

      HapticFeedback.lightImpact();
      
      // Pass context to answerQuestion method
      widget.quizController.answerQuestion(answer, context);

      // CRITICAL: Check game over condition immediately after processing answer
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      
      // Check if game should end due to lives = 0
      if (gameState.lives <= 0 || !gameState.isGameActive) {
        await Future.delayed(const Duration(milliseconds: 1400)); // Show feedback briefly
        _endGameImmediately();
        return;
      }

      // If game is still active, continue with normal flow
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted || _isGameEnding) return;

      // Check again before loading next question
      if (widget.quizController.shouldEndGame()) {
        widget.quizController.endGame();
        
        if (mounted) {
          navigator.pushReplacementNamed(
            '/result',
            arguments: {
              'finalScore': gameState.score,
              'highScore': gameState.highScore,
              'totalQuestions': gameState.totalQuestionsAsked,
              'level': gameState.level,
              'difficulty': gameState.difficulty,
            },
          );
        }
      } else {
        _loadQuestion();
      }
    } catch (e) {
      logger.e('Error processing answer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing answer: $e'),
            backgroundColor: DynamicAppTheme.errorColor,
          ),
        );
      }
    }
  }

  Color _getContrastingCardColor() {
    return DynamicAppTheme.cardColor;
  }

  @override
  Widget build(BuildContext context) {
    final gameState = widget.quizController.gameState;
    final question = widget.quizController.currentQuestion;

    // CRITICAL: Check game over condition in build method too
    if (gameState.lives <= 0 && !_isGameEnding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _endGameImmediately();
      });
    }

    if (question == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: DynamicAppTheme.backgroundGradient,
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        bottomNavigationBar: const CustomBottomNavBar(selectedIndex: -1),
      );
    }

    final cardColor = _getContrastingCardColor();
    final textPrimary = DynamicAppTheme.textPrimary;
    final textSecondary = DynamicAppTheme.textSecondary;

    return Theme(
      data: DynamicAppTheme.lightTheme,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: DynamicAppTheme.backgroundGradient,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 
                            MediaQuery.of(context).padding.top - 
                            MediaQuery.of(context).padding.bottom - 
                            80,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Header: Score, Level, and other stats
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatChip(
                              icon: Icons.star,
                              label: '${gameState.score}',
                              primaryColor: DynamicAppTheme.scoreColor,
                              backgroundColor: DynamicAppTheme.scoreColor.withAlpha(25),
                              textColor: DynamicAppTheme.scoreColor,
                            ),
                            _buildStatChip(
                              icon: Icons.emoji_events,
                              label: 'Best: ${gameState.highScore}',
                              primaryColor: DynamicAppTheme.primaryColor,
                              backgroundColor: DynamicAppTheme.primaryColor.withAlpha(25),
                              textColor: DynamicAppTheme.primaryColor,
                            ),
                            _buildStatChip(
                              icon: gameState.getDifficultyIcon(),
                              label: gameState.getDifficultyDisplayText(),
                              primaryColor: gameState.getDifficultyColor(),
                              backgroundColor: gameState.getDifficultyColor().withAlpha(25),
                              textColor: gameState.getDifficultyColor(),
                            ),
                          ],
                        ),
                      ),

                      // Life indicator with better spacing
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: LifeIndicator(lives: gameState.lives),
                      ),

                      // Show "GAME OVER" message when lives = 0
                      if (gameState.lives <= 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: DynamicAppTheme.errorColor.withAlpha(38),
                              border: Border.all(
                                color: DynamicAppTheme.errorColor,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: DynamicAppTheme.errorColor.withAlpha(20),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.sentiment_very_dissatisfied,
                                  color: DynamicAppTheme.errorColor,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'GAME OVER',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: DynamicAppTheme.errorColor,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No lives remaining',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: DynamicAppTheme.errorColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Progress indicator for level up (hide when game over)
                      if (gameState.lives > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Progress to Next Level: ${gameState.correctAnswersInLevel}/5',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${(gameState.getLevelProgress() * 100).toInt()}%',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: textSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: gameState.getLevelProgress(),
                                  backgroundColor: textSecondary.withAlpha(51),
                                  valueColor: AlwaysStoppedAnimation<Color>(DynamicAppTheme.accentColor),
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Question Card with animation
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ScaleTransition(
                          scale: _questionAnimation,
                          child: Card(
                            elevation: 8,
                            shadowColor: DynamicAppTheme.primaryColor.withAlpha(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(
                                color: DynamicAppTheme.primaryColor.withAlpha(50),
                                width: 1,
                              ),
                            ),
                            child: Container(
                              constraints: BoxConstraints(
                                minHeight: 200,
                                maxHeight: MediaQuery.of(context).size.height * 0.4,
                              ),
                              padding: const EdgeInsets.all(24),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: DynamicAppTheme.primaryColor.withAlpha(15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.quiz,
                                        size: 32,
                                        color: DynamicAppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      question.question,
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: textPrimary,
                                        height: 1.2,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: DynamicAppTheme.primaryColor.withAlpha(25),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: DynamicAppTheme.primaryColor.withAlpha(76),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        question.category,
                                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                          color: DynamicAppTheme.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Answer buttons with animations
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: question.allAnswers.map((answer) {
                            bool isSelected = _selectedAnswer == answer;
                            bool isCorrect = _isAnswered && answer == question.correctAnswer;
                            bool isWrong = _isAnswered && isSelected && !isCorrect;
                            bool isDisabled = _isAnswered || gameState.lives <= 0 || _isGameEnding;

                            return SlideTransition(
                              position: _buttonAnimation,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ElevatedButton(
                                  onPressed: isDisabled ? null : () => _processAnswer(answer),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isCorrect
                                        ? DynamicAppTheme.successColor.withAlpha(25)
                                        : isWrong
                                            ? DynamicAppTheme.errorColor.withAlpha(25)
                                            : cardColor,
                                    foregroundColor: isCorrect
                                        ? DynamicAppTheme.successColor
                                        : isWrong
                                            ? DynamicAppTheme.errorColor
                                            : DynamicAppTheme.primaryColor,
                                    elevation: isSelected ? 0 : 4,
                                    shadowColor: DynamicAppTheme.primaryColor.withAlpha(25),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: isCorrect
                                            ? DynamicAppTheme.successColor.withAlpha(76)
                                            : isWrong
                                                ? DynamicAppTheme.errorColor.withAlpha(76)
                                                : DynamicAppTheme.primaryColor.withAlpha(25),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          answer,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: isCorrect
                                                ? DynamicAppTheme.successColor
                                                : isWrong
                                                    ? DynamicAppTheme.errorColor
                                                    : textPrimary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (_isAnswered)
                                        Icon(
                                          isCorrect
                                              ? Icons.check_circle
                                              : isWrong
                                                  ? Icons.cancel
                                                  : null,
                                          color: isCorrect
                                              ? DynamicAppTheme.successColor
                                              : DynamicAppTheme.errorColor,
                                          size: 24,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Show feedback when answered
                      if (_isAnswered)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: _selectedAnswer == question.correctAnswer
                                  ? DynamicAppTheme.correctAnswerColor.withAlpha(38)
                                  : DynamicAppTheme.wrongAnswerColor.withAlpha(38),
                              border: Border.all(
                                color: _selectedAnswer == question.correctAnswer
                                    ? DynamicAppTheme.correctAnswerColor
                                    : DynamicAppTheme.wrongAnswerColor,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_selectedAnswer == question.correctAnswer
                                      ? DynamicAppTheme.correctAnswerColor
                                      : DynamicAppTheme.wrongAnswerColor).withAlpha(20),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _selectedAnswer == question.correctAnswer
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: _selectedAnswer == question.correctAnswer
                                      ? DynamicAppTheme.correctAnswerColor
                                      : DynamicAppTheme.wrongAnswerColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    _selectedAnswer == question.correctAnswer
                                        ? 'Correct! +${gameState.getDifficultyPoints()} points'
                                        : 'Wrong! The answer was ${question.correctAnswer}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: _selectedAnswer == question.correctAnswer
                                          ? DynamicAppTheme.correctAnswerColor
                                          : DynamicAppTheme.wrongAnswerColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: const CustomBottomNavBar(selectedIndex: -1),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color primaryColor,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withAlpha(76),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}