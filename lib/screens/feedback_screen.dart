import 'package:flutter/material.dart';
import '../widgets/custom_bottom_navbar.dart';
import '../theme/theme.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.arrow_back, color: DynamicAppTheme.textPrimary),
                        ),
                        Expanded(
                          child: Text(
                            'Kesan Pesan Pengembang',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontSize: 40,
                              color: DynamicAppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card pesan
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
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: DynamicAppTheme.primaryColor.withAlpha(25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.message,
                                      size: 24,
                                      color: DynamicAppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Kesan Pesan terhadap Matakuliah',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: DynamicAppTheme.textPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: DynamicAppTheme.backgroundColor.withAlpha(25),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: DynamicAppTheme.primaryColor.withAlpha(25),
                                      ),
                                    ),
                                    child: Text(
                                      'Matakuliah ini memberikan pengalaman belajar yang sangat bermanfaat dan menantang. ' 
                                      'Saya merasa lebih paham konsep-konsep cloud computing dan pengembangan aplikasi secara menyeluruh. '
                                      'Terima kasih atas bimbingan dan materi yang disampaikan dengan sangat baik.',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: DynamicAppTheme.textPrimary,
                                        fontSize: 16,
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.justify,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 4),
      ),
    );
  }
}