import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/user.dart';
import '../../../theme/theme.dart';
import 'profile_dialogs.dart';
import 'profile_stats.dart';

class ProfileContent extends StatelessWidget {
  final User user;
  final File? profileImage;
  final Function() onRefresh;
  final Function(ImageSource) onPickImage;
  final Function() onRemoveImage;
  final Function(User) onUserUpdated;

  const ProfileContent({
    Key? key,
    required this.user,
    required this.profileImage,
    required this.onRefresh,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onUserUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Image
          Center(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: DynamicAppTheme.primaryColor.withAlpha((0.2 * 255).round()),
                      width: 4,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: DynamicAppTheme.primaryColor.withValues(alpha: 25/255),
                    backgroundImage: profileImage != null ? FileImage(profileImage!) : null,
                    child: profileImage == null
                        ? Icon(
                            Icons.person,
                            size: 60,
                            color: DynamicAppTheme.primaryColor,
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: DynamicAppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DynamicAppTheme.surfaceColor,
                        width: 2,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => ProfileDialogs.showImageSourceDialog(
                        context: context,
                        onPickImage: onPickImage,
                        onRemoveImage: profileImage != null ? onRemoveImage : null,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // User Info
          Text(
            user.username,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: DynamicAppTheme.textPrimary,
              fontSize: 64,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (user.email != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                user.email!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: DynamicAppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
          const SizedBox(height: 32),

          // Profile Stats
          ProfileStats(
            user: user,
            onUserUpdated: onUserUpdated,
          ),
        ],
      ),
    );
  }
} 