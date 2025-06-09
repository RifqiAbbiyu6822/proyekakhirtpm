import 'package:flutter/material.dart';

class ProfileAnimations {
  final TickerProvider vsync;
  late final AnimationController animationController;

  ProfileAnimations(this.vsync) {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: vsync,
    );
  }

  void startInitialAnimations() {
    animationController.forward();
  }

  void dispose() {
    animationController.dispose();
  }
} 