import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';
import '../controllers/quiz_controller.dart';
import '../widgets/custom_bottom_navbar.dart';
import '../theme/theme.dart'; 
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  final QuizController quizController;

  const HomeScreen({Key? key, required this.quizController}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _bounceController;
  late AnimationController _shimmerController;
  late AnimationController _shakeController;
  late AnimationController _rotationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isThemeLoading = true;
  bool _isStartingQuiz = false;
  bool _isRefreshingTheme = false;
  
  // Accelerometer variables
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime _lastShakeTime = DateTime.now();
  static const double _shakeThreshold = 15.0;
  static const int _shakeCooldownMs = 2000; // 2 seconds cooldown

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _shakeAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.elasticInOut),
    );

    // Initialize the dynamic theme and accelerometer
    _initializeData();
    _initializeAccelerometer();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _bounceController.dispose();
    _shimmerController.dispose();
    _shakeController.dispose();
    _rotationController.dispose();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  void _initializeAccelerometer() {
    _accelerometerSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      _detectShake(event);
    });
  }

  void _detectShake(AccelerometerEvent event) {
    // Calculate the magnitude of acceleration
    double acceleration = sqrt(
      event.x * event.x + 
      event.y * event.y + 
      event.z * event.z
    );
    
    // Check if shake threshold is exceeded and cooldown period has passed
    DateTime now = DateTime.now();
    if (acceleration > _shakeThreshold && 
        now.difference(_lastShakeTime).inMilliseconds > _shakeCooldownMs) {
      
      _lastShakeTime = now;
      _onShakeDetected();
    }
  }

  void _onShakeDetected() {
    if (!mounted || _isRefreshingTheme) return;
    
    // Trigger shake animation
    _shakeController.forward().then((_) {
      _shakeController.reset();
    });

    // Trigger rotation animation
    _rotationController.forward().then((_) {
      _rotationController.reset();
    });
    
    // Show shake detection feedback with cool animation
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

  Future<void> _initializeData() async {
    try {
      await DynamicAppTheme.updateTheme();
      await AuthService.validateSession();
      if (mounted) {
        setState(() {
          _isThemeLoading = false;
        });
        _fadeController.forward();
        _bounceController.forward();
        _shimmerController.repeat(reverse: true);
      }
    } catch (e) {
      debugPrint('Error initializing theme: $e');
      if (mounted) {
        setState(() {
          _isThemeLoading = false;
        });
      }
    }
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
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Enhanced Time of Day Indicator
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_shakeAnimation, _scaleAnimation]),
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(_shakeAnimation.value, 0),
                              child: Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        DynamicAppTheme.primaryColor.withAlpha(102),
                                        DynamicAppTheme.primaryColor.withAlpha(51),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: DynamicAppTheme.primaryColor.withAlpha(26),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: DynamicAppTheme.primaryColor.withAlpha(26),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedBuilder(
                                        animation: _rotationAnimation,
                                        builder: (context, child) {
                                          return Transform.rotate(
                                            angle: _rotationAnimation.value,
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: DynamicAppTheme.primaryColor.withAlpha(77),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.palette,
                                                color: DynamicAppTheme.primaryColor,
                                                size: 18,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 12),
                                      AnimatedBuilder(
                                        animation: _shimmerAnimation,
                                        builder: (context, child) {
                                          return ShaderMask(
                                            shaderCallback: (bounds) {
                                              return LinearGradient(
                                                colors: [
                                                  DynamicAppTheme.textPrimary,
                                                  DynamicAppTheme.primaryColor,
                                                  DynamicAppTheme.textPrimary,
                                                ],
                                                stops: [
                                                  _shimmerAnimation.value - 0.3,
                                                  _shimmerAnimation.value,
                                                  _shimmerAnimation.value + 0.3,
                                                ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
                                              ).createShader(bounds);
                                            },
                                            child: Text(
                                              '${DynamicAppTheme.currentTimeOfDayString} Theme',
                                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Enhanced Header with animated title
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: ScaleTransition(
                            scale: _bounceAnimation,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedBuilder(
                                  animation: Listenable.merge([_rotationAnimation, _scaleAnimation]),
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _scaleAnimation.value,
                                      child: Transform.rotate(
                                        angle: _rotationAnimation.value,
                                        child: Image.asset(
                                          'assets/logo.png',
                                          width: 250,
                                          height: 250,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 0),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: LinearGradient(
                                      colors: [
                                        DynamicAppTheme.cardColor.withAlpha(230),
                                        DynamicAppTheme.cardColor.withAlpha(190),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(26),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                      BoxShadow(
                                        color: DynamicAppTheme.primaryColor.withAlpha(26),
                                        blurRadius: 30,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      ShaderMask(
                                        shaderCallback: (bounds) {
                                          return LinearGradient(
                                            colors: [
                                              DynamicAppTheme.primaryColor,
                                              DynamicAppTheme.primaryColor.withAlpha(153),
                                            ],
                                          ).createShader(bounds);
                                        },
                                        child: Text(
                                          'History Quiz',
                                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            height: 1.1,
                                            letterSpacing: -1,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: DynamicAppTheme.primaryColor.withAlpha(51),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Test Your Knowledge!',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontSize: 16,
                                            color: DynamicAppTheme.textSecondary,
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Enhanced Stats Section
                      Expanded(
                        flex: 1,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.emoji_events,
                                  title: 'High Score',
                                  value: '${widget.quizController.gameState.highScore}',
                                  color: DynamicAppTheme.scoreColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Enhanced Action Buttons
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            children: [
                              // Enhanced Start Quiz Button
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: double.infinity,
                                height: 65,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        DynamicAppTheme.primaryColorDark,
                                        DynamicAppTheme.primaryColorDark,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(32),
                                    boxShadow: [
                                      BoxShadow(
                                        color: DynamicAppTheme.primaryColor.withAlpha(51),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withAlpha(26),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: DynamicAppTheme.surfaceColor,
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(32),
                                      ),
                                    ),
                                    onPressed: _isStartingQuiz ? null : _startQuiz,
                                    child: _isStartingQuiz
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  DynamicAppTheme.surfaceColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Starting...',
                                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                color: DynamicAppTheme.surfaceColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withAlpha(128),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.play_arrow, 
                                                size: 28, 
                                                color: DynamicAppTheme.surfaceColor,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Start Quiz',
                                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                color: DynamicAppTheme.surfaceColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Enhanced Refresh Theme Button
                              _buildRefreshButton(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 0),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DynamicAppTheme.cardColor.withAlpha(230),
            DynamicAppTheme.cardColor.withAlpha(190),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: color.withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  color.withAlpha(128),
                  color.withAlpha(64),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(128),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withAlpha(64),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: DynamicAppTheme.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              DynamicAppTheme.accentColor,
              DynamicAppTheme.accentColor,
            ],
          ),
          border: Border.all(
            color: DynamicAppTheme.primaryColor.withAlpha(26),
            width: 2,
          ),
        ),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: DynamicAppTheme.primaryColor,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            backgroundColor: Colors.transparent,
          ),
          onPressed: _refreshTheme,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: DynamicAppTheme.primaryColor.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.refresh,
                  size: 22,
                  color: DynamicAppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Refresh Theme',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: DynamicAppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}