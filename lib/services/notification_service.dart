import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'dart:async';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static final logger = Logger();

  // Add notification messages for variety
  static const List<Map<String, String>> _notificationMessages = [
    {
      'title': '🏛️ History Challenge!',
      'body': 'Did you know? Ancient Egyptians built the Great Pyramid around 2560 BC. Test your knowledge about ancient civilizations!'
    },
    {
      'title': '⚔️ Battle Time!',
      'body': 'The Battle of Hastings in 1066 changed English history forever. Ready to conquer your next history quiz?'
    },
    {
      'title': '👑 Royal Quiz Alert!',
      'body': 'From Cleopatra to Queen Victoria - how well do you know your historical rulers? Take the quiz now!'
    },
    {
      'title': '🗺️ Explorer\'s Call!',
      'body': 'Columbus sailed the ocean blue in 1492. Discover more fascinating historical journeys in today\'s quiz!'
    },
    {
      'title': '⏳ Time Machine Ready!',
      'body': 'Your historical knowledge adventure awaits! Jump into the past with our latest quiz challenges.'
    },
    {
      'title': '🎭 Historical Drama',
      'body': 'The Renaissance brought art and culture to Europe. Show off your knowledge of this golden age!'
    },
    {
      'title': '🚀 Modern History Alert',
      'body': 'From World Wars to Space Race - test your knowledge of recent history in our latest quizzes!'
    },
    {
      'title': '🏺 Ancient Mysteries',
      'body': 'Unlock the secrets of ancient civilizations. Your next historical adventure is waiting!'
    },
    {
      'title': '📜 Constitution Time!',
      'body': 'Democracy, revolutions, and constitutions shaped our world. How much do you know about them?'
    },
    {
      'title': '🌍 World History Quiz',
      'body': 'From East to West, North to South - challenge yourself with global historical events!'
    }
  ];

  static int _currentMessageIndex = 0;

  static Map<String, String> _getNextNotificationMessage() {
    final message = _notificationMessages[_currentMessageIndex];
    _currentMessageIndex = (_currentMessageIndex + 1) % _notificationMessages.length;
    return message;
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Initialize notification channels for Android
    const androidSettings = AndroidInitializationSettings('app_icon');
    
    // Request permissions for iOS
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        // Handle iOS notification when app is in foreground
        logger.d('Received iOS notification: $title');
      }
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        logger.d('Notification tapped: ${response.payload}');
      },
    );

    // Request permissions explicitly for Android 13+
    await _requestPermissions();

    _initialized = true;
    logger.d('Notification service initialized successfully');
  }

  static Future<void> _requestPermissions() async {
    // Request permissions for Android
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      logger.d('Android notification permissions requested');
    }
  }

  static Future<void> startPeriodicNotifications() async {
    await initialize();

    // Cancel any existing notifications
    await _notifications.cancelAll();

    // Create basic notification details
    const androidDetails = AndroidNotificationDetails(
      'history_quiz',
      'History Quiz Reminders',
      channelDescription: 'Reminders to play History Quiz',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Simple periodic notification
    await _notifications.periodicallyShow(
      0,
      '🏛️ History Quiz Time!',
      'Test your knowledge with our exciting history questions!',
      RepeatInterval.everyMinute,
      details,
    );

    logger.d('Basic periodic notification started');
  }

  static Future<void> scheduleCustomNotification({
    required int id,
    required String title,
    required String body,
    required Duration delay,
    String? payload,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'game_reminder',
      'Game Reminders',
      channelDescription: 'Custom game reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: 'app_icon',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    logger.d('Custom notification scheduled for: $scheduledDate');
  }

  static Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'game_reminder',
      'Game Reminders',
      channelDescription: 'Instant game notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: 'app_icon',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: 1,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  static Future<void> stopNotifications() async {
    await _notifications.cancelAll();
    logger.d('All notifications cancelled');
  }

  static Future<void> stopSpecificNotification(int id) async {
    await _notifications.cancel(id);
    logger.d('Notification with ID $id cancelled');
  }

  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    await initialize(); // Ensure initialization before checking
    return await _notifications.pendingNotificationRequests();
  }
}