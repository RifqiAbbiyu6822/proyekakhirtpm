import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/theme.dart';
import '../../../models/user.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_helper.dart';
import '../../../services/encryption_service.dart';
import '../utils/profile_utils.dart';

class ProfileDialogs {
  static void showImageSourceDialog({
    required BuildContext context,
    required Function(ImageSource) onPickImage,
    Function()? onRemoveImage,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DynamicAppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Update Profile Picture',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: DynamicAppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: DynamicAppTheme.primaryColor),
              title: Text(
                'Take Photo',
                style: TextStyle(color: DynamicAppTheme.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                onPickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: DynamicAppTheme.primaryColor),
              title: Text(
                'Choose from Gallery',
                style: TextStyle(color: DynamicAppTheme.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                onPickImage(ImageSource.gallery);
              },
            ),
            if (onRemoveImage != null)
              ListTile(
                leading: Icon(Icons.delete, color: DynamicAppTheme.errorColor),
                title: Text(
                  'Remove Photo',
                  style: TextStyle(color: DynamicAppTheme.errorColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onRemoveImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  static void showEditProfileDialog({
    required BuildContext context,
    required User user,
    required Function(User) onUserUpdated,
  }) {
    final TextEditingController usernameController = TextEditingController(text: user.username);
    final TextEditingController emailController = TextEditingController(text: user.email);
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: DynamicAppTheme.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildTextField(
                            controller: usernameController,
                            label: 'Username',
                          ),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: emailController,
                            label: 'Email',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Change Password',
                            style: TextStyle(
                              color: DynamicAppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: passwordController,
                            label: 'New Password (optional)',
                            obscureText: true,
                          ),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: confirmPasswordController,
                            label: 'Confirm New Password',
                            obscureText: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: DynamicAppTheme.textLight.withValues(alpha: 0.2 * 255),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: DynamicAppTheme.textSecondary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            if (usernameController.text.isEmpty || emailController.text.isEmpty) {
                              throw Exception('Username and email are required');
                            }

                            if (passwordController.text.isNotEmpty &&
                                passwordController.text != confirmPasswordController.text) {
                              throw Exception('Passwords do not match');
                            }

                            var updatedUser = user.copyWith(
                              username: usernameController.text,
                              email: emailController.text,
                            );

                            if (passwordController.text.isNotEmpty) {
                              final newSalt = EncryptionService.generateSalt();
                              final hashedPassword = EncryptionService.hashPassword(
                                passwordController.text,
                                newSalt,
                              );
                              updatedUser = updatedUser.copyWith(
                                hashedPassword: hashedPassword,
                                salt: newSalt,
                              );
                            }

                            await DatabaseHelper.instance.updateUser(updatedUser);
                            await AuthService.updateCurrentUser(updatedUser);

                            if (context.mounted) {
                              Navigator.pop(context);
                              onUserUpdated(updatedUser);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile updated successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error updating profile: $e'),
                                  backgroundColor: DynamicAppTheme.errorColor,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DynamicAppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(
        color: DynamicAppTheme.textPrimary,
        fontSize: 18,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: DynamicAppTheme.textSecondary,
          fontSize: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: DynamicAppTheme.textLight,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: DynamicAppTheme.primaryColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
      ),
    );
  }

  static void showDeleteAccountDialog({
    required BuildContext context,
    required User user,
  }) {
    final TextEditingController passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: DynamicAppTheme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'Delete Account',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: DynamicAppTheme.errorColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'This action cannot be undone. Please enter your password to confirm.',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: DynamicAppTheme.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            style: TextStyle(color: DynamicAppTheme.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(color: DynamicAppTheme.textSecondary),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: DynamicAppTheme.textLight),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: DynamicAppTheme.errorColor),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: DynamicAppTheme.surfaceColor.withValues(alpha: 0.05 * 255),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                            child: Text(
                              'Cancel',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: DynamicAppTheme.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    setState(() {
                                      isLoading = true;
                                    });

                                    try {
                                      // Verify password
                                      final isPasswordValid = EncryptionService.verifyPassword(
                                        passwordController.text,
                                        user.hashedPassword,
                                        user.salt,
                                      );

                                      if (!isPasswordValid) {
                                        throw Exception('Incorrect password');
                                      }

                                      await ProfileUtils.handleDeleteAccount(context, user);
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
                                    } finally {
                                      setState(() {
                                        isLoading = false;
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DynamicAppTheme.errorColor,
                              foregroundColor: Colors.white,
                            ),
                            child: isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        DynamicAppTheme.surfaceColor,
                                      ),
                                    ),
                                  )
                                : const Text('Delete Account'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static void showLeaderboardDialog({
    required BuildContext context,
  }) async {
    try {
      // Initial leaderboard data
      final leaderboard = await DatabaseHelper.instance.getLeaderboard();
      String searchQuery = '';
      String sortBy = 'high_score';
      bool ascending = false;

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Leaderboard',
                                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    color: DynamicAppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.refresh, color: DynamicAppTheme.primaryColor),
                                  onPressed: () async {
                                    try {
                                      final updatedLeaderboard = await DatabaseHelper.instance.getLeaderboard(
                                        searchQuery: searchQuery,
                                        sortBy: sortBy,
                                        ascending: ascending,
                                      );
                                      setState(() {
                                        leaderboard.clear();
                                        leaderboard.addAll(updatedLeaderboard);
                                      });
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error refreshing leaderboard: $e')),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Search bar
                            TextField(
                              onChanged: (value) async {
                                searchQuery = value;
                                try {
                                  final searchResults = await DatabaseHelper.instance.getLeaderboard(
                                    searchQuery: value,
                                    sortBy: sortBy,
                                    ascending: ascending,
                                  );
                                  setState(() {
                                    leaderboard.clear();
                                    leaderboard.addAll(searchResults);
                                  });
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error searching: $e')),
                                    );
                                  }
                                }
                              },
                              decoration: InputDecoration(
                                hintText: 'Search by username...',
                                prefixIcon: Icon(Icons.search, color: DynamicAppTheme.textSecondary),
                                filled: true,
                                fillColor: DynamicAppTheme.surfaceColor.withValues(alpha: 0.1 * 255),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              style: TextStyle(color: DynamicAppTheme.textPrimary),
                            ),
                            const SizedBox(height: 16),
                            // Sort options
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildSortChip(
                                    context: context,
                                    label: 'High Score',
                                    selected: sortBy == 'high_score',
                                    ascending: ascending && sortBy == 'high_score',
                                    onSelected: () async {
                                      final newAscending = sortBy == 'high_score' ? !ascending : false;
                                      setState(() {
                                        sortBy = 'high_score';
                                        ascending = newAscending;
                                      });
                                      try {
                                        final sortedResults = await DatabaseHelper.instance.getLeaderboard(
                                          searchQuery: searchQuery,
                                          sortBy: sortBy,
                                          ascending: ascending,
                                        );
                                        setState(() {
                                          leaderboard.clear();
                                          leaderboard.addAll(sortedResults);
                                        });
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error sorting: $e')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildSortChip(
                                    context: context,
                                    label: 'Username',
                                    selected: sortBy == 'username',
                                    ascending: ascending && sortBy == 'username',
                                    onSelected: () async {
                                      final newAscending = sortBy == 'username' ? !ascending : true;
                                      setState(() {
                                        sortBy = 'username';
                                        ascending = newAscending;
                                      });
                                      try {
                                        final sortedResults = await DatabaseHelper.instance.getLeaderboard(
                                          searchQuery: searchQuery,
                                          sortBy: sortBy,
                                          ascending: ascending,
                                        );
                                        setState(() {
                                          leaderboard.clear();
                                          leaderboard.addAll(sortedResults);
                                        });
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error sorting: $e')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildSortChip(
                                    context: context,
                                    label: 'Total Quizzes',
                                    selected: sortBy == 'total_quizzes',
                                    ascending: ascending && sortBy == 'total_quizzes',
                                    onSelected: () async {
                                      final newAscending = sortBy == 'total_quizzes' ? !ascending : false;
                                      setState(() {
                                        sortBy = 'total_quizzes';
                                        ascending = newAscending;
                                      });
                                      try {
                                        final sortedResults = await DatabaseHelper.instance.getLeaderboard(
                                          searchQuery: searchQuery,
                                          sortBy: sortBy,
                                          ascending: ascending,
                                        );
                                        setState(() {
                                          leaderboard.clear();
                                          leaderboard.addAll(sortedResults);
                                        });
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error sorting: $e')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildSortChip(
                                    context: context,
                                    label: 'Last Quiz',
                                    selected: sortBy == 'last_quiz_date',
                                    ascending: ascending && sortBy == 'last_quiz_date',
                                    onSelected: () async {
                                      final newAscending = sortBy == 'last_quiz_date' ? !ascending : false;
                                      setState(() {
                                        sortBy = 'last_quiz_date';
                                        ascending = newAscending;
                                      });
                                      try {
                                        final sortedResults = await DatabaseHelper.instance.getLeaderboard(
                                          searchQuery: searchQuery,
                                          sortBy: sortBy,
                                          ascending: ascending,
                                        );
                                        setState(() {
                                          leaderboard.clear();
                                          leaderboard.addAll(sortedResults);
                                        });
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error sorting: $e')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: leaderboard.isEmpty
                            ? Center(
                                child: Text(
                                  searchQuery.isEmpty ? 'No players yet!' : 'No results found',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: DynamicAppTheme.textSecondary,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: leaderboard.length,
                                itemBuilder: (context, index) {
                                  final user = leaderboard[index];
                                  final isCurrentUser = user.id == AuthService.currentUser?.id;
                                  
                                  return Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isCurrentUser
                                          ? DynamicAppTheme.primaryColor.withValues(alpha: 0.1 * 255)
                                          : DynamicAppTheme.surfaceColor.withValues(alpha: 0.05 * 255),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isCurrentUser
                                            ? DynamicAppTheme.primaryColor.withValues(alpha: 0.3 * 255)
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Rank
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: ProfileUtils.getRankColor(index + 1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                color: DynamicAppTheme.surfaceColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        
                                        // User info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.username + (isCurrentUser ? ' (You)' : ''),
                                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                  color: DynamicAppTheme.textPrimary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                '${user.totalQuizzes} quizzes completed',
                                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                  color: DynamicAppTheme.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Score
                                        Text(
                                          user.formattedHighScore,
                                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            color: DynamicAppTheme.primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Close',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: DynamicAppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading leaderboard: $e')),
        );
      }
    }
  }

  static Widget _buildSortChip({
    required BuildContext context,
    required String label,
    required bool selected,
    required bool ascending,
    required VoidCallback onSelected,
  }) {
    return ActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: selected
                  ? DynamicAppTheme.surfaceColor
                  : DynamicAppTheme.textPrimary,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (selected) ...[
            const SizedBox(width: 4),
            Icon(
              ascending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: DynamicAppTheme.surfaceColor,
            ),
          ],
        ],
      ),
      backgroundColor: selected
          ? DynamicAppTheme.primaryColor
          : DynamicAppTheme.surfaceColor.withValues(alpha: 0.1 * 255),
      onPressed: onSelected,
    );
  }
} 