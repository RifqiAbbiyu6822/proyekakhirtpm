import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/image_service.dart';
import '../theme/theme.dart';
import 'package:logger/logger.dart';
import '../services/database_helper.dart';

final logger = Logger();

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;
  bool _isThemeInitialized = false;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    
    // Initialize dynamic theme
    _initializeTheme();
  }

  Future<void> _initializeTheme() async {
    await DynamicAppTheme.updateTheme();
    if (mounted) {
      setState(() {
        _isThemeInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
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

      if (image != null) {
        logger.i('Image selected successfully: ${image.path}');
        setState(() {
          _profileImage = image;
        });
      } else {
        logger.w('No image was selected');
      }
    } catch (e) {
      logger.e('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: DynamicAppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DynamicAppTheme.cardColor,
        title: Text(
          'Select Image Source',
          style: TextStyle(
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
                _pickImage(ImageSource.camera);
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
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;

      // Validate username
      final usernameError = AuthService.validateUsername(username);
      if (usernameError != null) {
        throw Exception(usernameError);
      }

      // Validate email
      final emailError = AuthService.validateEmail(email);
      if (emailError != null) {
        throw Exception(emailError);
      }

      // Validate password
      final passwordError = AuthService.validatePassword(password);
      if (passwordError != null) {
        throw Exception(passwordError);
      }

      // Check if passwords match
      if (password != confirmPassword) {
        throw Exception('Passwords do not match');
      }

      // Attempt registration
      final user = await AuthService.register(
        username: username,
        password: password,
        email: email,
      );
      
      if (!mounted) return;

      if (user != null) {
        // Save profile image if one was selected
        if (_profileImage != null && user.id != null) {
          try {
            logger.i('Saving profile image for new user: ${user.id}');
            final imagePath = await ImageService.saveProfileImage(
              _profileImage!,
              user.id.toString(),
            );

            if (imagePath != null) {
              logger.i('Profile image saved successfully at: $imagePath');
              // Update user with profile image path
              final updatedUser = user.copyWith(profileImagePath: imagePath);
              await DatabaseHelper.instance.updateUser(updatedUser);
              await AuthService.updateCurrentUser(updatedUser);
              logger.i('User updated with profile image path');
            } else {
              logger.e('Failed to save profile image - imagePath is null');
            }
          } catch (e) {
            logger.e('Error saving profile image: $e');
            // Continue with login even if image save fails
          }
        }

        // Auto login after successful registration
        final loginSuccess = await AuthService.login(username, password);
        
        if (!mounted) return;

        if (loginSuccess) {
          Navigator.pushReplacementNamed(context, '/profile');
        } else {
          Navigator.pushReplacementNamed(context, '/register');
        }
      } else {
        setState(() {
          _error = 'Registration failed. Please try again.';
        });
      }
    } catch (e) {
      logger.e('Registration error: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Image Picker
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: DynamicAppTheme.primaryColor.withAlpha(25),
                              backgroundImage: _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : null,
                              child: _profileImage == null
                                  ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color: DynamicAppTheme.primaryColor,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: DynamicAppTheme.primaryColor.withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.camera_alt,
                                    color: DynamicAppTheme.primaryColor,
                                  ),
                                  onPressed: _showImageSourceDialog,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Welcome Text
                      Text(
                        'Create Account',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join us and start your learning journey',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Registration Form
                      Container(
                        decoration: BoxDecoration(
                          gradient: DynamicAppTheme.cardGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: DynamicAppTheme.elevatedShadow,
                        ),
                        child: Card(
                          elevation: 0,
                          color: DynamicAppTheme.cardColor.withAlpha(229),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Username Field
                                TextField(
                                  controller: _usernameController,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                    labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: DynamicAppTheme.textSecondary
                                    ),
                                    prefixIcon: Icon(Icons.person, color: DynamicAppTheme.primaryColor),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: DynamicAppTheme.textLight),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: DynamicAppTheme.primaryColor),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: DynamicAppTheme.backgroundColor.withAlpha(127),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Email Field
                                TextField(
                                  controller: _emailController,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: DynamicAppTheme.textSecondary
                                    ),
                                    prefixIcon: Icon(Icons.email, color: DynamicAppTheme.primaryColor),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: DynamicAppTheme.textLight),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: DynamicAppTheme.primaryColor),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: DynamicAppTheme.backgroundColor.withAlpha(127),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Password Field
                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: DynamicAppTheme.textSecondary
                                    ),
                                    prefixIcon: Icon(Icons.lock, color: DynamicAppTheme.primaryColor),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                        color: DynamicAppTheme.textSecondary,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: DynamicAppTheme.textLight),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: DynamicAppTheme.primaryColor),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: DynamicAppTheme.backgroundColor.withAlpha(127),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Confirm Password Field
                                TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: DynamicAppTheme.textSecondary
                                    ),
                                    prefixIcon: Icon(Icons.lock_outline, color: DynamicAppTheme.primaryColor),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                        color: DynamicAppTheme.textSecondary,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword = !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: DynamicAppTheme.textLight),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: DynamicAppTheme.primaryColor),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: DynamicAppTheme.backgroundColor.withAlpha(127),
                                  ),
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _error!,
                                    style: TextStyle(
                                      color: DynamicAppTheme.errorColor,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 20),
                                // Register Button
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _handleRegister,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: DynamicAppTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              DynamicAppTheme.backgroundColor,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          'Register',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: DynamicAppTheme.textSecondary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: Text(
                              'Login',
                              style: TextStyle(
                                color: DynamicAppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}