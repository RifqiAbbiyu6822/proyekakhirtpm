import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/theme.dart';

class DeveloperProfile extends StatelessWidget {
  final String name;
  final String nim;
  final String about;
  final String imagePath;
  final String? instagramLink;

  const DeveloperProfile({
    Key? key,
    required this.name,
    required this.nim,
    required this.about,
    required this.imagePath,
    this.instagramLink,
  }) : super(key: key);

  Future<void> _launchInstagram(BuildContext context) async {
    if (instagramLink == null) return;

    try {
      final uri = Uri.parse(instagramLink!);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      if (!(await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      ))) {
        if (context.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Could not open $instagramLink'),
              backgroundColor: DynamicAppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            backgroundColor: DynamicAppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Card(
        elevation: 8,
        color: DynamicAppTheme.cardColor,
        shadowColor: DynamicAppTheme.primaryColor.withAlpha(51),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title
              Text(
                'About Developer',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: DynamicAppTheme.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Profile Image with Gradient Border
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      DynamicAppTheme.primaryColor,
                      DynamicAppTheme.primaryColorLight,
                    ],
                  ),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: DynamicAppTheme.cardColor,
                  child: ClipOval(
                    child: Image.asset(
                      imagePath,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          size: 60,
                          color: DynamicAppTheme.primaryColor,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name
              Text(
                name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: DynamicAppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              // NIM Badge
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DynamicAppTheme.primaryColor.withOpacity(0.2),
                      DynamicAppTheme.primaryColorLight.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'NIM: $nim',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: DynamicAppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),

              // About Text
              Text(
                about,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: DynamicAppTheme.textSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),

              // Instagram Button
              if (instagramLink != null) ...[
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => _launchInstagram(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF405DE6),
                          Color(0xFF5851DB),
                          Color(0xFF833AB4),
                          Color(0xFFE1306C),
                          Color(0xFFF77737),
                          Color(0xFFFFDC80),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 24,
                          color: Colors.white,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Follow me on Instagram',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 