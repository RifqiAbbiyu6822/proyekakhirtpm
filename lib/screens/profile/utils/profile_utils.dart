import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_helper.dart';
import '../../../theme/theme.dart';

class ProfileUtils {
  static Future<void> handleLogout(BuildContext context) async {
    try {
      await AuthService.logout();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: DynamicAppTheme.errorColor,
          ),
        );
      }
    }
  }

  static Future<void> handleDeleteAccount(BuildContext context, User user) async {
    try {
      await DatabaseHelper.instance.deleteUser(user.id!);
      await AuthService.logout();
      
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account deleted successfully.'),
            backgroundColor: DynamicAppTheme.primaryColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $e'),
            backgroundColor: DynamicAppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static Color getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return DynamicAppTheme.textSecondary;
    }
  }
} 