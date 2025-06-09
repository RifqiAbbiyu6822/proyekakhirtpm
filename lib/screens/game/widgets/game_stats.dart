import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../models/game_state.dart';

class GameStats extends StatelessWidget {
  final GameState gameState;

  const GameStats({
    super.key,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatChip(
            icon: Icons.star,
            label: '${gameState.score}',
            primaryColor: DynamicAppTheme.scoreColor,
            backgroundColor: DynamicAppTheme.scoreColor.withValues(alpha: 25, red: null, green: null, blue: null),
            textColor: DynamicAppTheme.scoreColor,
          ),
          _buildStatChip(
            icon: Icons.emoji_events,
            label: 'Best: ${gameState.highScore}',
            primaryColor: DynamicAppTheme.primaryColor,
            backgroundColor: DynamicAppTheme.primaryColor.withValues(alpha: 25, red: null, green: null, blue: null),
            textColor: DynamicAppTheme.primaryColor,
          ),
          _buildStatChip(
            icon: gameState.getDifficultyIcon(),
            label: gameState.getDifficultyDisplayText(),
            primaryColor: gameState.getDifficultyColor(),
            backgroundColor: gameState.getDifficultyColor().withValues(alpha: 25, red: null, green: null, blue: null),
            textColor: gameState.getDifficultyColor(),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withValues(alpha: 51, red: null, green: null, blue: null), // 0.2 * 255 ≈ 51
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: primaryColor,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
} 