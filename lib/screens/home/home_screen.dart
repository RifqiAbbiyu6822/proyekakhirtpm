import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../../controllers/quiz_controller.dart';
import '../../widgets/custom_bottom_navbar.dart';
import '../../theme/theme.dart';
import '../../services/auth_service.dart';
import 'animations/home_animations.dart';
import 'utils/shake_detector.dart';
import 'widgets/home_content.dart';

class HomeScreen extends StatefulWidget {
  final QuizController quizController;

  const HomeScreen({Key? key, required this.quizController}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isThemeLoading = true;
  bool _isStartingQuiz = false;
  bool _isRefreshingTheme = false;
  
  late HomeAnimations _animations;
  late ShakeDetector _shakeDetector;

  @override
  void initState() {
    super.initState();
    _animations = HomeAnimations(this);
    
    // Initialize data and start animations
    _initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shakeDetector = ShakeDetector(
      onShakeDetected: () {
        if (mounted) {
          _onShakeDetected();
        }
      },
      context: context,
    );
    _shakeDetector.startListening();
  }

  Future<void> _initializeData() async {
    try {
      await DynamicAppTheme.updateTheme();
      await AuthService.validateSession();
      if (mounted) {
        setState(() => _isThemeLoading = false);
        _animations.startInitialAnimations();
      }
    } catch (e) {
      debugPrint('Error initializing data: $e');
    }
  }

  void _onShakeDetected() {
    if (!mounted || _isRefreshingTheme) return;
    
    // Trigger animations
    _animations.triggerShakeAnimation();
    _animations.triggerRotationAnimation();
    
    // Clear any existing snackbars
    ScaffoldMessenger.of(context).clearSnackBars();
    
    // Show shake detection feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Row(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 2 * pi),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, rotation, child) {
                      return Transform.rotate(
                        angle: rotation,
                        child: Icon(Icons.vibration, color: DynamicAppTheme.textLight),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Shake detected! Refreshing theme...',
                    style: TextStyle(
                      color: DynamicAppTheme.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        backgroundColor: DynamicAppTheme.primaryColor,
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 8,
      ),
    );
    
    // Refresh theme after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _refreshTheme();
    });
  }

  Future<void> _refreshTheme() async {
    if (_isRefreshingTheme) return;
    
    setState(() {
      _isRefreshingTheme = true;
    });

    try {
      // Visual feedback for start
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.color_lens, color: DynamicAppTheme.textLight),
              const SizedBox(width: 8),
              Text(
                'Refreshing theme...',
                style: TextStyle(color: DynamicAppTheme.textLight),
              ),
            ],
          ),
          backgroundColor: DynamicAppTheme.primaryColor,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Update theme
      await DynamicAppTheme.updateTheme();
      
      if (!mounted) return;

      // Update UI
      setState(() {
        _isRefreshingTheme = false;
      });

      // Success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: DynamicAppTheme.textLight),
              const SizedBox(width: 8),
              Text(
                'Theme updated!',
                style: TextStyle(color: DynamicAppTheme.textLight),
              ),
            ],
          ),
          backgroundColor: DynamicAppTheme.successColor,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error refreshing theme: $e');
      if (mounted) {
        setState(() {
          _isRefreshingTheme = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: DynamicAppTheme.textLight),
                const SizedBox(width: 8),
                Text(
                  'Failed to update theme',
                  style: TextStyle(color: DynamicAppTheme.textLight),
                ),
              ],
            ),
            backgroundColor: DynamicAppTheme.errorColor,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _startQuiz() async {
    if (_isStartingQuiz) return;

    setState(() => _isStartingQuiz = true);

    try {
      // Validate session first
      final isValid = await AuthService.validateSession();
      if (!mounted) return;
      
      if (!isValid) {
        Navigator.of(context).pushReplacementNamed('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: DynamicAppTheme.surfaceColor, size: 20),
                const SizedBox(width: 12),
                const Text('Please login to start a quiz'),
              ],
            ),
            backgroundColor: DynamicAppTheme.errorColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }

      // Reset and start the game
      widget.quizController.resetGame(context);
      await widget.quizController.startGame();
      
      if (!mounted) return;
      Navigator.pushNamed(context, '/game');
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error starting quiz: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: DynamicAppTheme.surfaceColor, size: 20),
              const SizedBox(width: 12),
              Text('Error starting quiz: $e'),
            ],
          ),
          backgroundColor: DynamicAppTheme.errorColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isStartingQuiz = false);
      }
    }
  }

  @override
  void dispose() {
    _animations.dispose();
    _shakeDetector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DynamicAppTheme.lightTheme,
      child: Scaffold(
        body: _isThemeLoading
          ? Container(
              decoration: BoxDecoration(
                gradient: DynamicAppTheme.backgroundGradient,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: DynamicAppTheme.cardColor.withAlpha(204),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: DynamicAppTheme.primaryColor.withAlpha(77),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: CircularProgressIndicator(
                        color: DynamicAppTheme.primaryColor,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        color: DynamicAppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: DynamicAppTheme.backgroundGradient,
              ),
              child: SafeArea(
                child: HomeContent(
                  fadeAnimation: _animations.fadeAnimation,
                  bounceAnimation: _animations.bounceAnimation,
                  shimmerAnimation: _animations.shimmerAnimation,
                  shakeAnimation: _animations.shakeAnimation,
                  rotationAnimation: _animations.rotationAnimation,
                  scaleAnimation: _animations.scaleAnimation,
                  onStartQuiz: _startQuiz,
                  onRefreshTheme: _refreshTheme,
                  isStartingQuiz: _isStartingQuiz,
                  highScore: widget.quizController.gameState.highScore,
                ),
              ),
            ),
        bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 0),
      ),
    );
  }
} 