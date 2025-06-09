import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

class SupportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  const SupportOption({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Card(
        elevation: 4,
        color: DynamicAppTheme.cardColor,
        shadowColor: DynamicAppTheme.primaryColor.withAlpha(51),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                : Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: DynamicAppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: DynamicAppTheme.textSecondary,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: DynamicAppTheme.textSecondary.withAlpha(153),
            size: 18,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
} 