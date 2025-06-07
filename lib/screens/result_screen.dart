  import 'package:flutter/material.dart';
  import '../controllers/quiz_controller.dart';
  import '../widgets/custom_bottom_navbar.dart';
  import '../theme/theme.dart'; // Updated import
  import 'package:logger/logger.dart';

  class ResultScreen extends StatefulWidget {
    final QuizController quizController;

    const ResultScreen({Key? key, required this.quizController}) : super(key: key);

    @override
    State<ResultScreen> createState() => _ResultScreenState();
  }

  class _ResultScreenState extends State<ResultScreen> with TickerProviderStateMixin {
    final logger = Logger();
    late AnimationController _animationController;
    late Animation<double> _scaleAnimation;
    late Animation<double> _fadeAnimation;
    bool _isInitialized = false;

    @override
    void initState() {
      super.initState();

      _animationController = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      );

      _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
      );

      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
      );

      _animationController.forward();
    }

    @override
    void didChangeDependencies() {
      super.didChangeDependencies();
      if (!_isInitialized) {
        _initializeAndSave();
        _isInitialized = true;
      }
    }

    Future<void> _initializeAndSave() async {
      try {
        await DynamicAppTheme.updateTheme();
        // Save the score when the result screen is shown
        await widget.quizController.gameState.saveScore();
        if (mounted) setState(() {});
      } catch (e) {
        logger.e('Error initializing result screen: $e');
      }
    }

    @override
    void dispose() {
      _animationController.dispose();
      super.dispose();
    }

    // Helper method untuk mendapatkan warna dengan opacity yang aman
    Color _getSafeColor(Color baseColor, {double opacity = 1.0}) {
      final alpha = (opacity.clamp(0.0, 1.0) * 255).round();
      return baseColor.withAlpha(alpha);
    }

    @override
    Widget build(BuildContext context) {
      final gameState = widget.quizController.gameState;

      return Theme(
        data: DynamicAppTheme.lightTheme,
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: DynamicAppTheme.backgroundGradient,
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      // Score Display
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                          decoration: BoxDecoration(
                            color: _getSafeColor(DynamicAppTheme.cardColor),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: DynamicAppTheme.primaryColor.withAlpha(40),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Score',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    gameState.score >= gameState.highScore
                                        ? Icons.emoji_events
                                        : Icons.stars,
                                    color: DynamicAppTheme.primaryColor,
                                    size: 40,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '${gameState.score}',
                                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                      color: DynamicAppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 48,
                                    ),
                                  ),
                                ],
                              ),
                              if (gameState.score >= gameState.highScore)
                                Container(
                                  margin: const EdgeInsets.only(top: 16),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: DynamicAppTheme.primaryColor.withAlpha(30),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Text(
                                    'New High Score!',
                                    style: TextStyle(
                                      color: DynamicAppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 50),

                      // Stats cards with improved layout
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildStatCard(
                            icon: Icons.emoji_events,
                            title: 'High Score',
                            value: '${gameState.highScore}',
                            color: DynamicAppTheme.primaryColor,
                          ),
                          _buildStatCard(
                            icon: Icons.trending_up,
                            title: 'Level',
                            value: '${gameState.level}',
                            color: DynamicAppTheme.accentColor,
                          ),
                          _buildStatCard(
                            icon: Icons.favorite,
                            title: 'Lives Left',
                            value: '${gameState.lives}',
                            color: DynamicAppTheme.lifeColor,
                          ),
                        ],
                      ),

                      const SizedBox(height: 60),

                      // Action Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.refresh,
                                label: 'Play Again',
                                onPressed: () {
                                  widget.quizController.resetGame(context);
                                  Navigator.pushReplacementNamed(context, '/game');
                                },
                                backgroundColor: DynamicAppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.home,
                                label: 'Home',
                                onPressed: () {
                                  widget.quizController.resetGame(context);
                                  Navigator.pushReplacementNamed(context, '/');
                                },
                                backgroundColor: DynamicAppTheme.accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: const CustomBottomNavBar(selectedIndex: -1),
        ),
      );
    }

    Widget _buildStatCard({
      required IconData icon,
      required String title,
      required String value,
      required Color color,
    }) {
      return SizedBox(
        width: 160,
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: DynamicAppTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(25),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: _getSafeColor(color, opacity: 0.15),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getSafeColor(color, opacity: 0.2),
                      _getSafeColor(color, opacity: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: DynamicAppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildActionButton({
      required IconData icon,
      required String label,
      required VoidCallback onPressed,
      required Color backgroundColor,
    }) {
      return SizedBox(
        height: 56,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 24),
          label: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            backgroundColor: backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 3,
          ),
        ),
      );
    }
  }