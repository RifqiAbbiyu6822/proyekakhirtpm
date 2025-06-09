import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/custom_bottom_navbar.dart';
import '../../theme/theme.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/database_helper.dart';
import '../../services/image_service.dart';
import 'animations/profile_animations.dart';
import 'widgets/profile_content.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late ProfileAnimations _animations;
  User? _currentUser;
  bool _isLoading = true;
  bool _isThemeInitialized = false;
  String? _error;
  File? _profileImage;
  bool _isInitialized = false;
  bool _isProcessingImage = false;

  @override
  void initState() {
    super.initState();
    _animations = ProfileAnimations(this);
    _animations.startInitialAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _initializeData();
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      logger.i('Loading profile image...');
      if (_currentUser?.profileImagePath != null) {
        logger.d('Profile image path: ${_currentUser!.profileImagePath}');
        final imageFile = await ImageService.getImageFile(_currentUser!.profileImagePath);
        if (imageFile != null && mounted) {
          logger.i('Profile image loaded successfully');
          setState(() {
            _profileImage = imageFile;
          });
        } else {
          logger.w('Could not load profile image');
          if (mounted) {
            setState(() {
              _profileImage = null;
              // Clear the path if image file doesn't exist
              if (_currentUser?.profileImagePath != null) {
                _currentUser = _currentUser!.copyWith(profileImagePath: null);
              }
            });
          }
        }
      }
    } catch (e) {
      logger.e('Error loading profile image: $e');
      if (mounted) {
        setState(() {
          _profileImage = null;
          // Clear the path on error
          if (_currentUser?.profileImagePath != null) {
            _currentUser = _currentUser!.copyWith(profileImagePath: null);
          }
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isProcessingImage) {
      logger.w('Image processing already in progress');
      return;
    }

    setState(() => _isProcessingImage = true);

    try {
      logger.i('Starting image pick process...');
      
      // Check permissions first
      final hasPermissions = await ImageService.requestPermissions();
      if (!hasPermissions) {
        throw Exception('Camera and storage permissions are required');
      }

      File? image;
      if (source == ImageSource.camera) {
        logger.i('Taking photo from camera...');
        image = await ImageService.takePhoto();
      } else {
        logger.i('Picking image from gallery...');
        image = await ImageService.pickImageFromGallery();
      }

      if (image != null && _currentUser != null) {
        logger.i('Image selected successfully: ${image.path}');
        
        // Delete old profile image if exists
        if (_currentUser!.profileImagePath != null) {
          logger.i('Deleting old profile image...');
          await ImageService.deleteProfileImage(_currentUser!.profileImagePath!);
        }

        // Save new profile image
        final imagePath = await ImageService.saveProfileImage(
          image,
          _currentUser!.id.toString(),
        );

        if (imagePath != null) {
          logger.i('Image saved successfully at: $imagePath');

          // Update user with new profile image path
          final updatedUser = _currentUser!.copyWith(profileImagePath: imagePath);
          await DatabaseHelper.instance.updateUser(updatedUser);
          await AuthService.updateCurrentUser(updatedUser);

          if (mounted) {
            setState(() {
              _currentUser = updatedUser;
              _profileImage = image;
            });
          }
          
          logger.i('Profile image updated successfully');
        } else {
          logger.e('Failed to save profile image');
          throw Exception('Failed to save profile image');
        }
      } else {
        logger.w('No image was selected or user is null');
      }
    } catch (e) {
      logger.e('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile image: $e'),
            backgroundColor: DynamicAppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingImage = false);
      }
    }
  }

  Future<void> _removeProfileImage() async {
    if (_isProcessingImage) {
      logger.w('Image processing already in progress');
      return;
    }

    setState(() => _isProcessingImage = true);

    try {
      logger.i('Starting profile image removal...');
      if (_currentUser?.profileImagePath != null) {
        logger.i('Current profile image path: ${_currentUser!.profileImagePath}');
        
        // Delete profile image file
        final deleteResult = await ImageService.deleteProfileImage(_currentUser!.profileImagePath!);
        logger.i('Delete result: $deleteResult');
        
        if (!deleteResult) {
          throw Exception('Failed to delete profile image file');
        }
        
        // Update user in database
        final updatedUser = _currentUser!.copyWith(profileImagePath: null);
        await DatabaseHelper.instance.updateUser(updatedUser);
        await AuthService.updateCurrentUser(updatedUser);
        logger.i('User updated in database with null profile image path');

        setState(() {
          _currentUser = updatedUser;
          _profileImage = null;
        });
        logger.i('State updated successfully');
      } else {
        logger.w('No profile image path found to delete');
      }
    } catch (e) {
      logger.e('Error removing profile image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing profile image: $e'),
            backgroundColor: DynamicAppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingImage = false);
      }
    }
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Initialize theme first
      await DynamicAppTheme.updateTheme();
      if (!mounted) return;
      setState(() {
        _isThemeInitialized = true;
      });

      // Wait for auth service to be initialized first
      if (!AuthService.isInitialized) {
        await AuthService.initialize();
      }
      if (!mounted) return;

      // Validate session with full validation
      final isValid = await AuthService.validateSession();
      if (!mounted) return;

      if (!isValid) {
        Navigator.of(context).pushReplacementNamed('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Your session has expired. Please login again to continue.'),
            backgroundColor: DynamicAppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      await _refreshUserData();
      await _loadProfileImage();
    } catch (e) {
      logger.e('Error initializing profile: $e');
      if (mounted) {
        setState(() {
          _error = 'Error loading profile: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshUserData() async {
    // Store context-dependent values before async operations
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Validate session before refreshing data
      final isValid = await AuthService.validateSession();
      if (!mounted) return;

      if (!isValid) {
        navigator.pushReplacementNamed('/login');
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Your session has expired. Please login again to continue.'),
            backgroundColor: DynamicAppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Get current user from auth service
      final currentUser = AuthService.currentUser;
      if (currentUser == null || currentUser.id == null) {
        logger.i('No current user found, redirecting to login');
        if (!mounted) return;
        navigator.pushReplacementNamed('/login');
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Session error. Please login again.'),
            backgroundColor: DynamicAppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Refresh user data from database
      final refreshedUser = await DatabaseHelper.instance.getUserById(currentUser.id!);
      if (!mounted) return;

      if (refreshedUser != null) {
        setState(() {
          _currentUser = refreshedUser;
        });
        // Update the auth service with fresh data
        AuthService.updateCurrentUser(refreshedUser);
      } else {
        logger.i('User not found in database, logging out');
        await AuthService.logout();
        navigator.pushReplacementNamed('/login');
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('User account not found. Please login again.'),
            backgroundColor: DynamicAppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      logger.e('Error refreshing user data: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Error loading profile: $e';
      });
      // Use stored scaffoldMessenger instead of context
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error refreshing profile: $e'),
          backgroundColor: DynamicAppTheme.errorColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animations.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isThemeInitialized) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: DynamicAppTheme.backgroundGradient,
          ),
          child: Center(
            child: CircularProgressIndicator(
              color: DynamicAppTheme.primaryColor,
            ),
          ),
        ),
        bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 1),
      );
    }

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
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: DynamicAppTheme.backgroundGradient,
                    ),
                    child: CircularProgressIndicator(
                      color: DynamicAppTheme.primaryColor,
                    ),
                  ),
                )
              : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: DynamicAppTheme.errorColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _initializeData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DynamicAppTheme.primaryColor,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _currentUser != null
                  ? ProfileContent(
                      user: _currentUser!,
                      profileImage: _profileImage,
                      onRefresh: _refreshUserData,
                      onPickImage: _pickImage,
                      onRemoveImage: _removeProfileImage,
                      onUserUpdated: (updatedUser) {
                        setState(() {
                          _currentUser = updatedUser;
                        });
                      },
                    )
                  : const Center(child: Text('No user data available')),
          ),
        ),
        bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 1),
      ),
    );
  }
} 