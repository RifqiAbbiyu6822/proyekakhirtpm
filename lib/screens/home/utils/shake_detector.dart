import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

class ShakeDetector {
  static const double _shakeThreshold = 15.0;
  static const int _shakeCooldownMs = 2000; // 2 seconds cooldown
  
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime _lastShakeTime = DateTime.now();
  final Function() onShakeDetected;
  final BuildContext context;

  ShakeDetector({
    required this.onShakeDetected,
    required this.context,
  });

  void startListening() {
    _accelerometerSubscription = accelerometerEventStream().listen(_detectShake);
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
      onShakeDetected();
    }
  }

  void dispose() {
    _accelerometerSubscription?.cancel();
  }
} 