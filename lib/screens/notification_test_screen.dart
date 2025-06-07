import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../theme/theme.dart';
import '../widgets/custom_bottom_navbar.dart';
import 'package:logger/logger.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => NotificationTestScreenState();
}

class NotificationTestScreenState extends State<NotificationTestScreen> {
  final logger = Logger();
  bool _notificationsEnabled = false;
  int _pendingCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    if (!mounted) return;
    bool shouldSetState = true;
    try {
      await NotificationService.initialize();
      if (!mounted) {
        shouldSetState = false;
        return;
      }
      await _checkPendingNotifications();
    } catch (e, stackTrace) {
      logger.e('Error initializing notifications: $e\n$stackTrace');
      if (!mounted) {
        shouldSetState = false;
        return;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing notifications: $e'),
            backgroundColor: DynamicAppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (shouldSetState && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkPendingNotifications() async {
    if (!mounted) return;
    try {
      final pending = await NotificationService.getPendingNotifications();
      if (!mounted) return;
      setState(() {
        _pendingCount = pending.length;
        _notificationsEnabled = pending.isNotEmpty;
      });
    } catch (e, stackTrace) {
      logger.e('Error checking notifications: $e\n$stackTrace');
      if (!mounted) return;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking notifications: $e'),
            backgroundColor: DynamicAppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _handleInstantNotification() async {
    try {
      await NotificationService.showInstantNotification(
        title: 'Test Notification! 🎯',
        body: 'This is a test notification from your History Quiz app!',
        payload: 'test_notification',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Test notification sent!'),
          backgroundColor: DynamicAppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending notification: $e'),
          backgroundColor: DynamicAppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _handleScheduledNotification() async {
    try {
      await NotificationService.scheduleCustomNotification(
        id: 999,
        title: 'Scheduled Test! ⏰',
        body: 'This notification was scheduled 10 seconds ago!',
        delay: const Duration(seconds: 10),
        payload: 'scheduled_test',
      );
      await _checkPendingNotifications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notification scheduled for 10 seconds!'),
          backgroundColor: DynamicAppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scheduling notification: $e'),
          backgroundColor: DynamicAppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _handlePeriodicNotifications(bool value) async {
    try {
      if (value) {
        await NotificationService.startPeriodicNotifications();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Periodic notifications started!'),
            backgroundColor: DynamicAppTheme.successColor,
          ),
        );
      } else {
        await NotificationService.stopNotifications();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All notifications stopped!'),
            backgroundColor: DynamicAppTheme.primaryColor,
          ),
        );
      }
      await _checkPendingNotifications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating notifications: $e'),
          backgroundColor: DynamicAppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _handleStopAllNotifications() async {
    try {
      await NotificationService.stopNotifications();
      await _checkPendingNotifications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All notifications cancelled!'),
          backgroundColor: DynamicAppTheme.primaryColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling notifications: $e'),
          backgroundColor: DynamicAppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DynamicAppTheme.lightTheme,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: DynamicAppTheme.backgroundGradient,
          ),
          child: SafeArea(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: DynamicAppTheme.primaryColor,
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Icon(
                                    Icons.arrow_back,
                                    color: DynamicAppTheme.textPrimary,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Notification Settings',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontSize: 32,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _checkPendingNotifications,
                                  icon: Icon(
                                    Icons.refresh,
                                    color: DynamicAppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Status Card
                          Card(
                            color: DynamicAppTheme.cardColor,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Notification Status',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: DynamicAppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Pending notifications: $_pendingCount',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: DynamicAppTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Status: ${_notificationsEnabled ? "Active" : "Inactive"}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: _notificationsEnabled
                                          ? DynamicAppTheme.successColor
                                          : DynamicAppTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Test instant notification
                          ElevatedButton.icon(
                            onPressed: _handleInstantNotification,
                            icon: const Icon(Icons.notifications_active),
                            label: const Text('Send Test Notification'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DynamicAppTheme.primaryColor,
                              foregroundColor: DynamicAppTheme.textLight,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Schedule notification
                          ElevatedButton.icon(
                            onPressed: _handleScheduledNotification,
                            icon: const Icon(Icons.schedule),
                            label: const Text('Schedule Test (10 seconds)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DynamicAppTheme.primaryColor,
                              foregroundColor: DynamicAppTheme.textLight,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Periodic notifications switch
                          Card(
                            color: DynamicAppTheme.cardColor,
                            child: Column(
                              children: [
                                SwitchListTile(
                                  title: Text(
                                    'Periodic Reminders',
                                    style: TextStyle(
                                      color: DynamicAppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Get reminded to play every 10 minutes',
                                        style: TextStyle(
                                          color: DynamicAppTheme.textSecondary,
                                        ),
                                      ),
                                      if (_notificationsEnabled)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Next notification in: ${_pendingCount > 0 ? "~${10 - (DateTime.now().minute % 10)} minutes" : "calculating..."}',
                                            style: TextStyle(
                                              color: DynamicAppTheme.primaryColor,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  value: _notificationsEnabled,
                                  activeColor: DynamicAppTheme.primaryColor,
                                  onChanged: _handlePeriodicNotifications,
                                ),
                                if (_notificationsEnabled)
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Notification Schedule:',
                                          style: TextStyle(
                                            color: DynamicAppTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '• Notifications are sent every 10 minutes\n'
                                          '• Different messages keep you engaged\n'
                                          '• Schedule refreshes daily\n'
                                          '• Notifications are smart and won\'t disturb during quiet hours',
                                          style: TextStyle(
                                            color: DynamicAppTheme.textSecondary,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Stop all notifications
                          OutlinedButton.icon(
                            onPressed: _handleStopAllNotifications,
                            icon: const Icon(Icons.notifications_off),
                            label: const Text('Stop All Notifications'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: DynamicAppTheme.errorColor,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Instructions card with enhanced information
                          Card(
                            color: DynamicAppTheme.cardColor.withAlpha(230),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: DynamicAppTheme.primaryColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Notification Settings',
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: DynamicAppTheme.textPrimary,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '• Notifications help you maintain a regular study schedule\n'
                                    '• Each notification has unique and engaging content\n'
                                    '• You can test notifications using the buttons above\n'
                                    '• Make sure to allow notifications in your device settings\n'
                                    '• You can stop notifications at any time',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: DynamicAppTheme.textSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
        bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 2),
      ),
    );
  }
} 