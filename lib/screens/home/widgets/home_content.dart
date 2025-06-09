import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

class HomeContent extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final Animation<double> bounceAnimation;
  final Animation<double> shimmerAnimation;
  final Animation<double> shakeAnimation;
  final Animation<double> rotationAnimation;
  final Animation<double> scaleAnimation;
  final VoidCallback onStartQuiz;
  final VoidCallback onRefreshTheme;
  final bool isStartingQuiz;
  final int highScore;

  const HomeContent({
    Key? key,
    required this.fadeAnimation,
    required this.bounceAnimation,
    required this.shimmerAnimation,
    required this.shakeAnimation,
    required this.rotationAnimation,
    required this.scaleAnimation,
    required this.onStartQuiz,
    required this.onRefreshTheme,
    required this.isStartingQuiz,
    required this.highScore,
  }) : super(key: key);

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
          onPressed: onRefreshTheme,
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
                style: TextStyle(
                  color: DynamicAppTheme.textPrimary,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Enhanced Time of Day Indicator
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: AnimatedBuilder(
            animation: Listenable.merge([shakeAnimation, scaleAnimation]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(shakeAnimation.value, 0),
                child: Transform.scale(
                  scale: scaleAnimation.value,
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
                          animation: rotationAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: rotationAnimation.value,
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
                          animation: shimmerAnimation,
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
                                    shimmerAnimation.value - 0.3,
                                    shimmerAnimation.value,
                                    shimmerAnimation.value + 0.3,
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
              scale: bounceAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: Listenable.merge([rotationAnimation, scaleAnimation]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: scaleAnimation.value,
                        child: Transform.rotate(
                          angle: rotationAnimation.value,
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
                    value: highScore.toString(),
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
                      onPressed: isStartingQuiz ? null : onStartQuiz,
                      child: isStartingQuiz
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
                                  color: DynamicAppTheme.textPrimary,
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
                                  color: DynamicAppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Start Quiz',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: DynamicAppTheme.textPrimary,
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
    );
  }
} 