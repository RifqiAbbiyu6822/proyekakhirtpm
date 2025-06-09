import 'package:flutter/material.dart';

class HomeAnimations {
  late AnimationController fadeController;
  late AnimationController bounceController;
  late AnimationController shimmerController;
  late AnimationController shakeController;
  late AnimationController rotationController;
  late Animation<double> fadeAnimation;
  late Animation<double> bounceAnimation;
  late Animation<double> shimmerAnimation;
  late Animation<double> shakeAnimation;
  late Animation<double> rotationAnimation;
  late Animation<double> scaleAnimation;

  HomeAnimations(TickerProvider vsync) {
    // Initialize controllers
    fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: vsync,
    );

    bounceController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: vsync,
    );

    shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: vsync,
    );

    shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: vsync,
    );

    rotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: vsync,
    );

    // Initialize animations
    fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: fadeController, curve: Curves.easeInOut),
    );

    bounceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: bounceController, curve: Curves.elasticOut),
    );

    shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: shimmerController, curve: Curves.easeInOut),
    );

    shakeAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: shakeController, curve: Curves.elasticInOut),
    );

    rotationAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: rotationController, curve: Curves.easeInOut),
    );

    scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: rotationController, curve: Curves.elasticInOut),
    );
  }

  void startInitialAnimations() {
    fadeController.forward();
    bounceController.forward();
    shimmerController.repeat(reverse: true);
  }

  void triggerShakeAnimation() {
    shakeController.forward().then((_) {
      shakeController.reset();
    });
  }

  void triggerRotationAnimation() {
    rotationController.forward().then((_) {
      rotationController.reset();
    });
  }

  void dispose() {
    fadeController.dispose();
    bounceController.dispose();
    shimmerController.dispose();
    shakeController.dispose();
    rotationController.dispose();
  }
} 