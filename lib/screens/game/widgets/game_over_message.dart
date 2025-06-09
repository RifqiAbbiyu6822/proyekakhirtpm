import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

class GameOverMessage extends StatelessWidget {
  const GameOverMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: DynamicAppTheme.errorColor.withValues(alpha: 38, red: null, green: null, blue: null),
          border: Border.all(
            color: DynamicAppTheme.errorColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: DynamicAppTheme.errorColor.withValues(alpha: 20, red: null, green: null, blue: null),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: DynamicAppTheme.errorColor,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'GAME OVER',
              style: TextStyle(
                color: DynamicAppTheme.errorColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have run out of lives!',
              style: TextStyle(
                color: DynamicAppTheme.textPrimary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 