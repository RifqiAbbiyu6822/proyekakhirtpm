import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../controllers/lbs_service.dart' hide LocationInfo;
import '../../widgets/custom_bottom_navbar.dart';
import 'animations/support_animations.dart';
import 'widgets/developer_profile.dart';
import 'widgets/support_option.dart';
import 'widgets/location_info.dart';
import 'widgets/donation_dialog.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  State<SupportScreen> createState() => SupportScreenState();
}

class SupportScreenState extends State<SupportScreen> with SingleTickerProviderStateMixin {
  late SupportAnimations _animations;
  final double baseDonationAmountUSD = 10.0;
  double localDonationAmount = 10.0;
  String currencySymbol = '\$';
  String currencyCode = 'USD';
  bool isLoadingCurrency = true;
  String locationText = 'Detecting location...';

  @override
  void initState() {
    super.initState();
    _animations = SupportAnimations(this);
    _animations.startInitialAnimations();
    _initializeThemeAndCurrency();
  }

  Future<void> _initializeThemeAndCurrency() async {
    setState(() {
      isLoadingCurrency = true;
      locationText = 'Detecting location...';
    });

    try {
      await DynamicAppTheme.updateTheme();
      await LocationBasedService.updateLocationAndTime();
      
      if (mounted) {
        setState(() {
          final currencyInfo = LocationBasedService.currentCurrencyInfo;
          final locationInfo = LocationBasedService.currentLocationInfo;
          
          if (currencyInfo != null) {
            localDonationAmount = LocationBasedService.calculateLocalDonationAmount(baseDonationAmountUSD);
            currencySymbol = currencyInfo.symbol;
            currencyCode = currencyInfo.code;
          }
          
          locationText = locationInfo != null 
              ? '${locationInfo.city}, ${locationInfo.country}'
              : 'Location not detected';
          
          isLoadingCurrency = false;
        });
      }
    } catch (e) {
      logger.e('Error initializing currency: $e');
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
    _animations.dispose();
    super.dispose();
  }

  void _showDonationDialog() {
    showDialog(
      context: context,
      builder: (context) => DonationDialog(
        localDonationAmount: localDonationAmount,
        baseDonationAmountUSD: baseDonationAmountUSD,
        currencyCode: currencyCode,
        locationText: locationText,
        onDonate: _showThankYouSnackbar,
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
    if (!mounted) return;
    await _initializeThemeAndCurrency();
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: LocationInfo(
                      locationText: locationText,
                      currencyCode: currencyCode,
                      localDonationAmount: localDonationAmount,
                    ),
                  ),

                Expanded(
                  child: SlideTransition(
                    position: _animations.slideAnimation,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: ListView(
                        children: [
                          // Developer Profile
                          const DeveloperProfile(
                            name: 'Mohammad Rifqi Abbiyu Musyaffa',
                            nim: '123220068',
                            about: 'plis sudahi segala proyek akhir ini aku udah ga kuat serius',
                            imagePath: 'assets/profile_images/dev1.jpg',
                            instagramLink: 'https://www.instagram.com/rifqi_abbiyu/',
                          ),

                          const Divider(height: 32, thickness: 1),

                          // Donation option
                          SupportOption(
                            icon: Icons.coffee,
                            title: 'Buy us a Coffee',
                            subtitle: isLoadingCurrency 
                                ? 'Calculating local price...'
                                : 'Support development with ${LocationBasedService.formatCurrencyAmount(localDonationAmount)}',
                            color: DynamicAppTheme.primaryColorLight,
                            onTap: isLoadingCurrency ? () {} : _showDonationDialog,
                            isLoading: isLoadingCurrency,
                          ),

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
} 