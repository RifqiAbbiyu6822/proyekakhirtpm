import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../theme/theme.dart';
import 'profile_dialogs.dart';
import '../utils/profile_utils.dart';

class ProfileStats extends StatelessWidget {
  final User user;
  final Function(User) onUserUpdated;

  const ProfileStats({
    Key? key,
    required this.user,
    required this.onUserUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Profile section title
        Text(
          'Profile Information',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 40,
          ),
        ),

        // Stats Grid
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard(
              context,
              'Total Quizzes',
              user.totalQuizzes.toString(),
              Icons.quiz,
            ),
            _buildStatCard(
              context,
              'High Score',
              user.formattedHighScore,
              Icons.emoji_events,
            ),
            if (user.lastQuizDate != null)
              _buildStatCard(
                context,
                'Last Quiz',
                _formatDate(user.lastQuizDate!),
                Icons.calendar_today,
              ),
            _buildStatCard(
              context,
              'Theme',
              DynamicAppTheme.currentTimeOfDayString,
              Icons.brightness_4,
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Stats section title
        Text(
          'Statistics',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 32,
          ),
        ),

        // Menu Options
        Container(
          decoration: BoxDecoration(
            color: DynamicAppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildMenuItem(
                context: context,
                icon: Icons.edit,
                title: 'Edit Profile',
                subtitle: 'Update your account information',
                onTap: () => ProfileDialogs.showEditProfileDialog(
                  context: context,
                  user: user,
                  onUserUpdated: onUserUpdated,
                ),
              ),
              _buildDivider(),
              _buildMenuItem(
                context: context,
                icon: Icons.leaderboard,
                title: 'Leaderboard',
                subtitle: 'See how you rank against others',
                onTap: () => ProfileDialogs.showLeaderboardDialog(context: context),
              ),
              _buildDivider(),
              _buildMenuItem(
                context: context,
                icon: Icons.delete_forever,
                title: 'Delete Account',
                subtitle: 'Permanently remove your account',
                onTap: () => ProfileDialogs.showDeleteAccountDialog(
                  context: context,
                  user: user,
                ),
                isDestructive: true,
              ),
              _buildDivider(),
              _buildMenuItem(
                context: context,
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                onTap: () => ProfileUtils.handleLogout(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: DynamicAppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DynamicAppTheme.primaryColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: DynamicAppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: DynamicAppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: DynamicAppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withAlpha(25)
              : DynamicAppTheme.primaryColor.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : DynamicAppTheme.primaryColor,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: isDestructive ? Colors.red : DynamicAppTheme.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: DynamicAppTheme.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: DynamicAppTheme.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: DynamicAppTheme.textLight.withAlpha(25),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 