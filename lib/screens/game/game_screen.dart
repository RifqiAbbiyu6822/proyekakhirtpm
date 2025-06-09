import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/quiz_controller.dart';
import '../../widgets/life_indicator.dart';
import '../../widgets/custom_bottom_navbar.dart';
import '../../theme/theme.dart';
import '../../services/auth_service.dart';
import 'animations/game_animations.dart';
import 'widgets/game_stats.dart';
import 'widgets/game_over_message.dart';
import 'widgets/question_display.dart';
import 'widgets/exit_game_button.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class GameScreen extends StatefulWidget {
  final QuizController quizController;

  const GameScreen({super.key, required this.quizController});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameAnimations _animations;
  bool _isAnswered = false;
  String? _selectedAnswer;
  bool _isGameEnding = false;

  @override
  void initState() {
    super.initState();
    _animations = GameAnimations(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });
  }

  Future<void> _initializeGame() async {
    try {
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
    _animations.dispose();
    super.dispose();
  }

  void _checkGameOverCondition() {
    final gameState = widget.quizController.gameState;
    
    if ((gameState.lives <= 0 || !gameState.isGameActive || widget.quizController.shouldEndGame()) && !_isGameEnding) {
      _isGameEnding = true;
      _endGameImmediately();
    }
  }

  void _endGameImmediately() {
    if (!mounted || _isGameEnding) return;
    
    final gameState = widget.quizController.gameState;
    
    widget.quizController.endGame();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Game Over! No lives remaining.'),
        backgroundColor: DynamicAppTheme.errorColor,
        duration: const Duration(seconds: 2),
      ),
    );
    
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

    _checkGameOverCondition();
    if (_isGameEnding) return;

    try {
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

      _animations.resetAnimations();

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
      await _animations.playLoadQuestionAnimation();
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
      final navigator = Navigator.of(context);
      final gameState = widget.quizController.gameState;
      
      setState(() {
        _selectedAnswer = answer;
        _isAnswered = true;
      });

      HapticFeedback.lightImpact();
      
      widget.quizController.answerQuestion(answer, context);

      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      
      if (gameState.lives <= 0 || !gameState.isGameActive) {
        await Future.delayed(const Duration(milliseconds: 1400));
        _endGameImmediately();
        return;
      }

      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted || _isGameEnding) return;

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

  void _exitGame() {
    widget.quizController.resetGame(context);
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = widget.quizController.gameState;
    final question = widget.quizController.currentQuestion;

    if (gameState.lives <= 0 && !_isGameEnding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _endGameImmediately();
      });
    }

    if (question == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            color: DynamicAppTheme.backgroundColor,
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        bottomNavigationBar: const CustomBottomNavBar(selectedIndex: -1),
      );
    }

    return Theme(
      data: DynamicAppTheme.lightTheme,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: DynamicAppTheme.backgroundColor,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      GameStats(gameState: gameState),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: LifeIndicator(lives: gameState.lives),
                      ),
                      if (gameState.lives <= 0)
                        const GameOverMessage(),
                      QuestionDisplay(
                        question: question,
                        animations: _animations,
                        isAnswered: _isAnswered,
                        selectedAnswer: _selectedAnswer,
                        onAnswerSelected: _processAnswer,
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: DynamicAppTheme.backgroundColor,
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ExitGameButton(onExit: _exitGame),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const CustomBottomNavBar(selectedIndex: -1),
      ),
    );
  }
} 