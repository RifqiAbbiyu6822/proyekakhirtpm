import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/custom_bottom_navbar.dart';
import '../theme/theme.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../services/encryption_service.dart';
import '../services/image_service.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  User? _currentUser;
  bool _isLoading = true;
  bool _isThemeInitialized = false;
  String? _error;
  File? _profileImage;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
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
            });
          }
        }
      }
    } catch (e) {
      logger.e('Error loading profile image: $e');
      if (mounted) {
        setState(() {
          _profileImage = null;
        });
      }
    }
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

      if (image != null && _currentUser != null) {
        logger.i('Image selected successfully: ${image.path}');
        
        // Save new profile image
        final imagePath = await ImageService.saveProfileImage(
          image,
          _currentUser!.id.toString(),
        );

        if (imagePath != null) {
          logger.i('Image saved successfully at: $imagePath');
          
          // Delete old profile image if exists
          if (_currentUser!.profileImagePath != null) {
            logger.i('Deleting old profile image...');
            await ImageService.deleteProfileImage(_currentUser!.profileImagePath!);
          }

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
    }
  }

  void _showImageSourceDialog() {
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
            if (_profileImage != null)
              ListTile(
                leading: Icon(Icons.delete, color: DynamicAppTheme.errorColor),
                title: Text(
                  'Remove Photo',
                  style: TextStyle(color: DynamicAppTheme.errorColor),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _removeProfileImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeProfileImage() async {
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
        AuthService.updateCurrentUser(updatedUser);
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
    _animationController.dispose();
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
                : SingleChildScrollView(
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
                                    color: DynamicAppTheme.primaryColor.withOpacity(0.2),
                                    width: 4,
                                  ),
                                ),
                                child: CircleAvatar(
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
                                    onPressed: _showImageSourceDialog,
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
                        if (_currentUser != null) ...[
                          Text(
                            _currentUser!.username,
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: DynamicAppTheme.textPrimary,
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_currentUser!.email != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _currentUser!.email!,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: DynamicAppTheme.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          const SizedBox(height: 32),

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
                                'Total Quizzes',
                                _currentUser!.totalQuizzes.toString(),
                                Icons.quiz,
                              ),
                              _buildStatCard(
                                'High Score',
                                _currentUser!.formattedHighScore,
                                Icons.emoji_events,
                              ),
                              if (_currentUser!.lastQuizDate != null)
                                _buildStatCard(
                                  'Last Quiz',
                                  _formatDate(_currentUser!.lastQuizDate!),
                                  Icons.calendar_today,
                                ),
                              _buildStatCard(
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
                                  icon: Icons.edit,
                                  title: 'Edit Profile',
                                  subtitle: 'Update your account information',
                                  onTap: () => _showEditProfileDialog(),
                                ),
                                _buildDivider(),
                                _buildMenuItem(
                                  icon: Icons.leaderboard,
                                  title: 'Leaderboard',
                                  subtitle: 'See how you rank against others',
                                  onTap: () => _showLeaderboardDialog(),
                                ),
                                _buildDivider(),
                                _buildMenuItem(
                                  icon: Icons.delete_forever,
                                  title: 'Delete Account',
                                  subtitle: 'Permanently remove your account',
                                  onTap: () => _showDeleteAccountDialog(),
                                  isDestructive: true,
                                ),
                                _buildDivider(),
                                _buildMenuItem(
                                  icon: Icons.logout,
                                  title: 'Logout',
                                  subtitle: 'Sign out of your account',
                                  onTap: () => _handleLogout(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
        bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 1),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
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

  Future<void> _showLeaderboardDialog() async {
    try {
      // Store context-dependent values before async operations
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      // Initial leaderboard data
      final leaderboard = await DatabaseHelper.instance.getLeaderboard();
      String searchQuery = '';
      String sortBy = 'high_score';
      bool ascending = false;

      if (!mounted) return;

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
                                      if (!mounted) return;
                                      setState(() => leaderboard.clear());
                                      setState(() => leaderboard.addAll(updatedLeaderboard));
                                    } catch (e) {
                                      if (!mounted) return;
                                      scaffoldMessenger.showSnackBar(
                                        SnackBar(content: Text('Error refreshing leaderboard: $e')),
                                      );
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
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(content: Text('Error searching: $e')),
                                  );
                                }
                              },
                              decoration: InputDecoration(
                                hintText: 'Search by username...',
                                prefixIcon: Icon(Icons.search, color: DynamicAppTheme.textSecondary),
                                filled: true,
                                fillColor: DynamicAppTheme.surfaceColor.withOpacity(0.1),
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
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(content: Text('Error sorting: $e')),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildSortChip(
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
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(content: Text('Error sorting: $e')),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildSortChip(
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
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(content: Text('Error sorting: $e')),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildSortChip(
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
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(content: Text('Error sorting: $e')),
                                        );
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
                                  final isCurrentUser = user.id == _currentUser?.id;
                                  
                                  return Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isCurrentUser
                                          ? DynamicAppTheme.primaryColor.withOpacity(0.1)
                                          : DynamicAppTheme.surfaceColor.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isCurrentUser
                                            ? DynamicAppTheme.primaryColor.withOpacity(0.3)
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
                                            color: _getRankColor(index + 1),
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
                                        
                                        // Profile Picture
                                        FutureBuilder<File?>(
                                          future: ImageService.getImageFile(user.profileImagePath),
                                          builder: (context, snapshot) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isCurrentUser
                                                      ? DynamicAppTheme.primaryColor.withOpacity(0.3)
                                                      : DynamicAppTheme.surfaceColor.withOpacity(0.1),
                                                  width: 2,
                                                ),
                                              ),
                                              child: CircleAvatar(
                                                radius: 24,
                                                backgroundColor: DynamicAppTheme.primaryColor.withAlpha(25),
                                                child: ClipOval(
                                                  child: snapshot.hasData && snapshot.data != null
                                                      ? Image.file(
                                                          snapshot.data!,
                                                          width: 48,
                                                          height: 48,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) {
                                                            logger.e('Error loading profile image: $error');
                                                            return Icon(
                                                              Icons.person,
                                                              size: 24,
                                                              color: DynamicAppTheme.primaryColor,
                                                            );
                                                          },
                                                        )
                                                      : Icon(
                                                          Icons.person,
                                                          size: 24,
                                                          color: DynamicAppTheme.primaryColor,
                                                        ),
                                                ),
                                              ),
                                            );
                                          },
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
                          onPressed: () => navigator.pop(),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading leaderboard: $e')),
      );
    }
  }

  Widget _buildSortChip({
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
          : DynamicAppTheme.surfaceColor.withOpacity(0.1),
      onPressed: onSelected,
    );
  }

  Color _getRankColor(int rank) {
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

  Future<void> _handleLogout() async {
    try {
      // Store context-dependent values before async operations
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      await AuthService.logout();
      
      if (mounted) {
        navigator.pushReplacementNamed('/login');
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      logger.e('Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: DynamicAppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showEditProfileDialog() {
    final TextEditingController usernameController = TextEditingController(
      text: _currentUser?.username ?? '',
    );
    final TextEditingController emailController = TextEditingController(
      text: _currentUser?.email ?? '',
    );
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
                          // Username field
                          TextField(
                            controller: usernameController,
                            style: TextStyle(
                              color: DynamicAppTheme.textPrimary,
                              fontSize: 18,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Username',
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
                          ),
                          const SizedBox(height: 24),
                          
                          // Email field
                          TextField(
                            controller: emailController,
                            style: TextStyle(
                              color: DynamicAppTheme.textPrimary,
                              fontSize: 18,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
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
                          ),
                          const SizedBox(height: 32),
                          
                          // Password section header
                          Text(
                            'Change Password',
                            style: TextStyle(
                              color: DynamicAppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Password field
                          TextField(
                            controller: passwordController,
                            style: TextStyle(
                              color: DynamicAppTheme.textPrimary,
                              fontSize: 18,
                            ),
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'New Password (optional)',
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
                          ),
                          const SizedBox(height: 24),
                          
                          // Confirm Password field
                          TextField(
                            controller: confirmPasswordController,
                            style: TextStyle(
                              color: DynamicAppTheme.textPrimary,
                              fontSize: 18,
                            ),
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Confirm New Password',
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
                        color: DynamicAppTheme.textLight.withOpacity(0.2),
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
                          // Store context-dependent values before async operations
                          final navigator = Navigator.of(context);
                          final scaffoldMessenger = ScaffoldMessenger.of(context);

                          try {
                            // Validate session before updating profile
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

                            // Validate inputs
                            if (usernameController.text.isEmpty || emailController.text.isEmpty) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: const Text('Username and email are required'),
                                  backgroundColor: DynamicAppTheme.errorColor,
                                ),
                              );
                              return;
                            }

                            // Validate password match if provided
                            if (passwordController.text.isNotEmpty && 
                                passwordController.text != confirmPasswordController.text) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: const Text('Passwords do not match'),
                                  backgroundColor: DynamicAppTheme.errorColor,
                                ),
                              );
                              return;
                            }

                            // Update user
                            var updatedUser = _currentUser!.copyWith(
                              username: usernameController.text,
                              email: emailController.text,
                            );

                            // Update password if provided
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

                            if (mounted) {
                              navigator.pop();
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Profile updated successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              setState(() {
                                _currentUser = updatedUser;
                              });
                            }
                          } catch (e) {
                            logger.e('Error updating profile: $e');
                            if (mounted) {
                              scaffoldMessenger.showSnackBar(
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

  void _showDeleteAccountDialog() {
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
                              fillColor: DynamicAppTheme.surfaceColor.withOpacity(0.05),
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
                                    // Store context-dependent values before async operations
                                    final navigator = Navigator.of(dialogContext);
                                    final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);
                                    final currentUser = _currentUser;

                                    setState(() {
                                      isLoading = true;
                                    });

                                    try {
                                      // Validate session before deleting account
                                      final isValid = await AuthService.validateSession();
                                      if (!mounted) {
                                        setState(() {
                                          isLoading = false;
                                        });
                                        return;
                                      }

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

                                      if (currentUser != null) {
                                        // Verify password
                                        final isPasswordValid = EncryptionService.verifyPassword(
                                          passwordController.text,
                                          currentUser.hashedPassword,
                                          currentUser.salt,
                                        );

                                        if (!isPasswordValid) {
                                          throw Exception('Incorrect password');
                                        }

                                        await DatabaseHelper.instance.deleteUser(currentUser.id!);
                                        await AuthService.logout();
                                        
                                        navigator.pushNamedAndRemoveUntil(
                                          '/login',
                                          (route) => false,
                                        );
                                        scaffoldMessenger.showSnackBar(
                                          SnackBar(
                                            content: const Text('Account deleted successfully.'),
                                            backgroundColor: DynamicAppTheme.primaryColor,
                                            duration: const Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      scaffoldMessenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Error deleting account: $e'),
                                          backgroundColor: DynamicAppTheme.errorColor,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}