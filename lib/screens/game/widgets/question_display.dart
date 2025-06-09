import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../models/question.dart';
import '../animations/game_animations.dart';

class QuestionDisplay extends StatelessWidget {
  final Question question;
  final GameAnimations animations;
  final bool isAnswered;
  final String? selectedAnswer;
  final Function(String) onAnswerSelected;

  const QuestionDisplay({
    super.key,
    required this.question,
    required this.animations,
    required this.isAnswered,
    required this.selectedAnswer,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          ScaleTransition(
            scale: animations.questionAnimation,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: DynamicAppTheme.primaryColor.withValues(alpha: 51, red: null, green: null, blue: null),
                  width: 1,
                ),
              ),
              color: DynamicAppTheme.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Question',
                      style: TextStyle(
                        color: DynamicAppTheme.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      question.question,
                      style: TextStyle(
                        color: DynamicAppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SlideTransition(
            position: animations.buttonAnimation,
            child: Column(
              children: [
                _buildAnswerButton(
                  answer: 'True',
                  isSelected: selectedAnswer == 'True',
                  isCorrect: isAnswered ? question.correctAnswer == 'True' : null,
                ),
                const SizedBox(height: 16),
                _buildAnswerButton(
                  answer: 'False',
                  isSelected: selectedAnswer == 'False',
                  isCorrect: isAnswered ? question.correctAnswer == 'False' : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton({
    required String answer,
    required bool isSelected,
    bool? isCorrect,
  }) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    if (isAnswered) {
      if (isCorrect == true) {
        backgroundColor = DynamicAppTheme.successColor.withValues(alpha: 38, red: null, green: null, blue: null);
        textColor = DynamicAppTheme.successColor;
        borderColor = DynamicAppTheme.successColor;
      } else if (isSelected && isCorrect == false) {
        backgroundColor = DynamicAppTheme.errorColor.withValues(alpha: 38, red: null, green: null, blue: null);
        textColor = DynamicAppTheme.errorColor;
        borderColor = DynamicAppTheme.errorColor;
      } else {
        backgroundColor = DynamicAppTheme.cardColor;
        textColor = DynamicAppTheme.textPrimary;
        borderColor = DynamicAppTheme.primaryColor.withValues(alpha: 51, red: null, green: null, blue: null);
      }
    } else {
      backgroundColor = isSelected
          ? DynamicAppTheme.primaryColor.withValues(alpha: 38, red: null, green: null, blue: null)
          : DynamicAppTheme.cardColor;
      textColor = isSelected ? DynamicAppTheme.primaryColor : DynamicAppTheme.textPrimary;
      borderColor = isSelected
          ? DynamicAppTheme.primaryColor
          : DynamicAppTheme.primaryColor.withValues(alpha: 51, red: null, green: null, blue: null);
    }

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: isAnswered ? null : () => onAnswerSelected(answer),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor, width: 2),
          ),
          elevation: isSelected ? 8 : 4,
        ),
        child: Text(
          answer,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 