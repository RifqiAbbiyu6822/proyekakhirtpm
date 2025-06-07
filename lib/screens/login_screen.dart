import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/theme.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;
  bool _isThemeInitialized = false;

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
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      // Validate inputs
      if (username.isEmpty || password.isEmpty) {
        throw Exception('Please fill in all fields');
      }

      // Attempt login
      final success = await AuthService.login(username, password);
      
      if (!mounted) return;

      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _error = 'Invalid username or password';
        });
      }
    } catch (e) {
      logger.e('Login error: $e');
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
                      // App Logo/Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: DynamicAppTheme.primaryColor.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.history_edu,
                          size: 80,
                          color: DynamicAppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Welcome Text
                      Text(
                        'Welcome Back!',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue your learning journey',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Login Form
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
                                if (_error != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _error!,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: DynamicAppTheme.errorColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 20),
                                // Login Button
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
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
                                          'Login',
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
                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Don\'t have an account? ',
                            style: TextStyle(
                              color: DynamicAppTheme.textSecondary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: Text(
                              'Register',
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