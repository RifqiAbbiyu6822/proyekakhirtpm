import 'package:flutter/material.dart';

class SupportAnimations {
  final AnimationController controller;
  late final Animation<Offset> slideAnimation;

  SupportAnimations(TickerProvider vsync) : 
    controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: vsync,
    ) {
    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );
  }

  void startInitialAnimations() {
    controller.forward();
  }

  void dispose() {
    controller.dispose();
  }
} 