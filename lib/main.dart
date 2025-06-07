import 'package:flutter/material.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/support_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/result_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/notification_test_screen.dart';
import 'controllers/quiz_controller.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'theme/theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:logger/logger.dart';

final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize theme
  logger.i('Initializing theme...');
  await DynamicAppTheme.updateTheme();

  // Request permissions first
  logger.i('Starting permission requests...');
  
  if (Platform.isAndroid) {
    // Request storage permission explicitly
    logger.i('Requesting storage permissions...');
    var storageStatus = await Permission.storage.request();
    logger.i('Storage permission status: $storageStatus');
    
    // For Android 11 and above, also request manage external storage
    if (await Permission.manageExternalStorage.status.isDenied) {
      logger.i('Requesting manage external storage permission...');
      var manageStatus = await Permission.manageExternalStorage.request();
      logger.i('Manage storage permission status: $manageStatus');
    }
    
    // Request notification permission explicitly
    logger.i('Requesting notification permission...');
    var notificationStatus = await Permission.notification.request();
    logger.i('Notification permission status: $notificationStatus');
  }

  // Initialize authentication
  logger.i('Starting app initialization...');
  await AuthService.initialize();
  final isLoggedIn = await AuthService.validateSession();
  logger.i('Initial auth state - isLoggedIn: $isLoggedIn');

  // Initialize notification service
  logger.i('Initializing notification service...');
  await NotificationService.initialize();
  
  // Start periodic notifications if user is logged in
  if (isLoggedIn) {
    await NotificationService.startPeriodicNotifications();
    logger.i('Periodic notifications started');
  }

  runApp(HistoryQuizApp(isLoggedIn: isLoggedIn));
}

class HistoryQuizApp extends StatelessWidget {
  final QuizController quizController = QuizController();
  final bool isLoggedIn;

  HistoryQuizApp({
    Key? key,
    required this.isLoggedIn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    logger.i('Building app with isLoggedIn: $isLoggedIn');
        
    return MaterialApp(
      title: 'History Quiz',
      theme: DynamicAppTheme.lightTheme,
      initialRoute: isLoggedIn ? '/' : '/login',
      routes: {
        '/': (context) => HomeScreen(quizController: quizController),
        '/game': (context) => GameScreen(quizController: quizController),
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationTestScreen(),
        '/support': (context) => const SupportScreen(),
        '/feedback': (context) => const FeedbackScreen(),
        '/result': (context) => ResultScreen(quizController: quizController),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => HomeScreen(quizController: quizController),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}