import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../controllers/lbs_service.dart'; // Import the updated service
import '../widgets/custom_bottom_navbar.dart'; // Import your custom navbar
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  State<SupportScreen> createState() => SupportScreenState();
}

class SupportScreenState extends State<SupportScreen> with SingleTickerProviderStateMixin {
  final _logger = Logger();
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  final double baseDonationAmountUSD = 10.0; // Base amount in USD
  double localDonationAmount = 10.0;
  String currencySymbol = '\$';
  String currencyCode = 'USD';
  bool isLoadingCurrency = true;
  String locationText = 'Detecting location...';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    // Initialize theme and location-based currency
    _initializeThemeAndCurrency();
  }

  Future<void> _initializeThemeAndCurrency() async {
    setState(() {
      isLoadingCurrency = true;
      locationText = 'Detecting location...';
    });

    try {
      // Initialize theme
      await DynamicAppTheme.updateTheme();
      
      // Update location and currency data
      await LocationBasedService.updateLocationAndTime();
      
      // Get currency information
      final currencyInfo = LocationBasedService.currentCurrencyInfo;
      final locationInfo = LocationBasedService.currentLocationInfo;
      
      if (mounted) {
        setState(() {
          if (currencyInfo != null) {
            localDonationAmount = LocationBasedService.calculateLocalDonationAmount(baseDonationAmountUSD);
            currencySymbol = currencyInfo.symbol;
            currencyCode = currencyInfo.code;
          }
          
          if (locationInfo != null) {
            locationText = '${locationInfo.city}, ${locationInfo.country}';
          } else {
            locationText = 'Location not detected';
          }
          
          isLoadingCurrency = false;
        });
      }
    } catch (e) {
      _logger.e('Error initializing currency: $e');
      if (mounted) {
        setState(() {
          isLoadingCurrency = false;
          locationText = 'Unable to detect location';
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showDonationDialog() {
    final formattedAmount = LocationBasedService.formatCurrencyAmount(localDonationAmount);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support Us'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Would you like to donate $formattedAmount to support development?'),
            const SizedBox(height: 12),
            if (currencyCode != 'USD')
              Text(
                'Equivalent to \$${baseDonationAmountUSD.toStringAsFixed(2)} USD',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    locationText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showThankYouSnackbar();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DynamicAppTheme.primaryColor,
              foregroundColor: DynamicAppTheme.surfaceColor,
            ),
            child: Text('Donate $formattedAmount'),
          ),
        ],
      ),
    );
  }

  void _showThankYouSnackbar() {
    final formattedAmount = LocationBasedService.formatCurrencyAmount(localDonationAmount);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Terima kasih telah berdonasi $formattedAmount!'),
        duration: const Duration(seconds: 3),
        backgroundColor: DynamicAppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _refreshLocation() async {
    await _initializeThemeAndCurrency();
  }

  void _showDeveloperProfile(String name, String nim, String about, String imagePath, String? instagramLink) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DynamicAppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Developer Profile',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    DynamicAppTheme.primaryColor.withAlpha(25),
                    DynamicAppTheme.primaryColorLight.withAlpha(25),
                  ],
                ),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: DynamicAppTheme.cardColor,
                child: ClipOval(
                  child: Image.asset(
                    imagePath,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        size: 50,
                        color: DynamicAppTheme.primaryColor,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: DynamicAppTheme.textPrimary,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: DynamicAppTheme.primaryColor.withAlpha(38),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'NIM: $nim',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: DynamicAppTheme.primaryColor,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              about,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: DynamicAppTheme.textSecondary,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (instagramLink != null) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  try {
                    final uri = Uri.parse(instagramLink);
                    if (!await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    )) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not open $instagramLink'),
                            backgroundColor: DynamicAppTheme.errorColor,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error opening link: $e'),
                          backgroundColor: DynamicAppTheme.errorColor,
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
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
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Follow on Instagram',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: DynamicAppTheme.primaryColor,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperOption({
    required String name,
    required String nim,
    required String about,
    required String imagePath,
    required Color color,
    String? instagramLink,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Card(
        elevation: 4,
        color: DynamicAppTheme.cardColor,
        shadowColor: DynamicAppTheme.primaryColor.withAlpha(51),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[200],
            child: ClipOval(
              child: Image.asset(
                imagePath,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person,
                    size: 25,
                    color: Colors.grey,
                  );
                },
              ),
            ),
          ),
          title: Text(
            name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: DynamicAppTheme.textPrimary,
              fontSize: 20,
            ),
          ),
          subtitle: Text(
            'NIM: $nim',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: DynamicAppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          onTap: () => _showDeveloperProfile(name, nim, about, imagePath, instagramLink),
        ),
      ),
    );
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
                          'Support Us',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 40,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        onPressed: _refreshLocation,
                        icon: Icon(
                          Icons.refresh,
                          color: DynamicAppTheme.textPrimary,
                        ),
                        tooltip: 'Refresh location',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Location info card
                if (LocationBasedService.hasLocationData || LocationBasedService.hasCurrencyData)
                  Card(
                    elevation: 2,
                    color: DynamicAppTheme.cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: DynamicAppTheme.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Current Location',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: DynamicAppTheme.textPrimary,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            locationText,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: DynamicAppTheme.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          if (LocationBasedService.hasCurrencyData) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.monetization_on,
                                  color: DynamicAppTheme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Local Currency: $currencyCode',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: DynamicAppTheme.textPrimary,
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Donation amount: ${LocationBasedService.formatCurrencyAmount(localDonationAmount)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: DynamicAppTheme.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: ListView(
                        children: [
                          // Developer Profiles
                          _buildDeveloperOption(
                            name: 'Mohammad Rifqi Abbiyu Musyaffa',
                            nim: '123220068',
                            about: 'plis sudahi segala proyek akhir ini',
                            imagePath: 'assets/profile_images/dev1.jpg',
                            color: DynamicAppTheme.primaryColorLight,
                            instagramLink: 'https://www.instagram.com/rifqi_abbiyu/',
                          ),

                          const Divider(height: 32, thickness: 1),

                          // Donation option (buy a coffee)
                          _buildSupportOption(
                            icon: Icons.coffee,
                            title: 'Buy us a Coffee',
                            subtitle: isLoadingCurrency 
                                ? 'Calculating local price...'
                                : 'Support development with ${LocationBasedService.formatCurrencyAmount(localDonationAmount)}',
                            color: DynamicAppTheme.primaryColorLight,
                            onTap: isLoadingCurrency ? () {} : _showDonationDialog,
                            isLoading: isLoadingCurrency,
                          ),

                          // Additional support options

                          // Add bottom padding to avoid overlap with navbar
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 3),
      ),
    );
  }

  Widget _buildSupportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
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