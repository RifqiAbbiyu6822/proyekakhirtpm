import 'package:flutter/material.dart';

class GameAnimations {
  late AnimationController questionAnimationController;
  late AnimationController buttonAnimationController;
  late Animation<double> questionAnimation;
  late Animation<Offset> buttonAnimation;

  GameAnimations(TickerProvider vsync) {
    _initializeControllers(vsync);
    _initializeAnimations();
  }

  void _initializeControllers(TickerProvider vsync) {
    questionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: vsync,
    );

    buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: vsync,
    );
  }

  void _initializeAnimations() {
    questionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: questionAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    buttonAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: buttonAnimationController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  void dispose() {
    questionAnimationController.dispose();
    buttonAnimationController.dispose();
  }

  void resetAnimations() {
    questionAnimationController.reset();
    buttonAnimationController.reset();
  }

  Future<void> playLoadQuestionAnimation() async {
    questionAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    buttonAnimationController.forward();
  }
} 