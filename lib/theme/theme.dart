import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:historyquizapp/controllers/lbs_service.dart';
import 'dart:async';

class DynamicAppTheme {
  // Morning color palette (6:00 - 11:59) - Vintage Morning Propaganda
  static const Color morningColor1 = Color(0xFFE8D8C3); // Vintage Paper
  static const Color morningColor2 = Color(0xFFB22222); // Soviet Red
  static const Color morningColor3 = Color(0xFF2B3F5C); // Military Blue
  static const Color morningColor4 = Color(0xFFF4E4BC); // Aged Parchment
  static const Color morningColor5 = Color(0xFF1A1A1A); // Propaganda Black

  // Afternoon color palette (12:00 - 17:59) - Bold Propaganda Day
  static const Color afternoonColor1 = Color(0xFFCC1E1E); // Revolutionary Red
  static const Color afternoonColor2 = Color(0xFF1B3058); // Navy Command
  static const Color afternoonColor3 = Color(0xFFFFB700); // Glory Gold
  static const Color afternoonColor4 = Color(0xFFE6D5B8); // Weathered Paper
  static const Color afternoonColor5 = Color(0xFF262626); // Deep Black

  // Night color palette (18:00 - 5:59) - Dramatic Night Propaganda
  static const Color nightColor1 = Color(0xFF8B0000); // Dark Blood
  static const Color nightColor2 = Color(0xFFDAA520); // Medal Gold
  static const Color nightColor3 = Color(0xFF000066); // Night Watch Blue
  static const Color nightColor4 = Color(0xFFD4B886); // Vintage Kraft
  static const Color nightColor5 = Color(0xFF000000); // Absolute Black

  // Initialize and update theme based on location and TimeAPI
  static Future<void> updateTheme() async {
    await LocationBasedService.updateLocationAndTime();
  }


  // Get detailed time information from LocationBasedService
  static Map<String, dynamic> get timeInfo => LocationBasedService.locationTimeInfo;

  // Get current color palette based on time of day
  static Map<String, Color> get currentColors {
    switch (LocationBasedService.currentTimeOfDay) {
      case TimeOfDay.morning:
        return {
          'color1': morningColor1,
          'color2': morningColor2,
          'color3': morningColor3,
          'color4': morningColor4,
          'color5': morningColor5,
        };
      case TimeOfDay.afternoon:
        return {
          'color1': afternoonColor1,
          'color2': afternoonColor2,
          'color3': afternoonColor3,
          'color4': afternoonColor4,
          'color5': afternoonColor5,
        };
      case TimeOfDay.night:
        return {
          'color1': nightColor1,
          'color2': nightColor2,
          'color3': nightColor3,
          'color4': nightColor4,
          'color5': nightColor5,
        };
    }
  }

  // Current theme colors
  static Color get color1 => currentColors['color1']!;
  static Color get color2 => currentColors['color2']!;
  static Color get color3 => currentColors['color3']!;
  static Color get color4 => currentColors['color4']!;
  static Color get color5 => currentColors['color5']!;

  // Primary colors
  static Color get primaryColor => color1;
  static Color get primaryColorLight => color4;
  static Color get primaryColorDark => color2;
  
  // Secondary / accent colors
  static Color get secondaryColor => color5;
  static Color get accentColor => color3;

  // Background and surface colors
  static Color get backgroundColor => color4;
  static Color get surfaceColor => LocationBasedService.currentTimeOfDay == TimeOfDay.night ? color2 : const Color(0xFFFAF7F0);
  static Color get cardColor => LocationBasedService.currentTimeOfDay == TimeOfDay.night ? color2 : const Color(0xFFFAF7F0);

  // Text colors - improved contrast
  static Color get textPrimary {
    switch (LocationBasedService.currentTimeOfDay) {
      case TimeOfDay.morning:
        return const Color(0xFF1A1A1A); // Almost Black for sunrise theme
      case TimeOfDay.afternoon:
        return const Color(0xFF2C3E67); // Deep Navy for sakura theme
      case TimeOfDay.night:
        return const Color(0xFFFFFAF0); // Floral White for sunset theme
    }
  }
  
  static Color get textSecondary {
    switch (LocationBasedService.currentTimeOfDay) {
      case TimeOfDay.morning:
        return const Color(0xFF4A5D8F); // Deep Blue for sunrise
      case TimeOfDay.afternoon:
        return const Color(0xFFA3567B); // Deep Rose for sakura
      case TimeOfDay.night:
        return const Color(0xFFFFDAB9); // Peach for sunset
    }
  }
  
  static Color get textLight {
    switch (LocationBasedService.currentTimeOfDay) {
      case TimeOfDay.morning:
        return const Color(0xFFFFFFFF); // Pure White for sunrise
      case TimeOfDay.afternoon:
        return const Color(0xFFFFFAF0); // Floral White for sakura
      case TimeOfDay.night:
        return const Color(0xFFFCDD2D); // Bright Yellow for sunset
    }
  }

  // Status colors - bold variants
  static Color get successColor => const Color(0xFF6779B9); // Soft Blue
  static Color get errorColor => const Color(0xFFC47DA0); // Deep Pink
  static Color get warningColor => const Color(0xFFFF900E); // Bright Orange
  static Color get infoColor => const Color(0xFFFCDD2D); // Bright Yellow

  // Navigation colors - Enhanced contrast for propaganda style
  static Color get navBarColor => LocationBasedService.currentTimeOfDay == TimeOfDay.night 
    ? nightColor5.withAlpha(242)  // 0.95 -> 242
    : color2.withAlpha(242);      // 0.95 -> 242

  static Color get navIconUnselected => LocationBasedService.currentTimeOfDay == TimeOfDay.night
    ? const Color(0xFFB8860B)        // Dark golden for night
    : const Color(0xFFF5E6D3);       // Vintage cream for day/morning

  // Enhanced navigation bar shadow
  static List<BoxShadow> get navBarShadow => [
    BoxShadow(
      color: color2.withAlpha(128),    // 0.5 -> 128
      blurRadius: 15,
      spreadRadius: 2,
      offset: const Offset(0, -3),
    ),
    BoxShadow(
      color: Colors.black.withAlpha(77),  // 0.3 -> 77
      blurRadius: 8,
      spreadRadius: 0,
      offset: const Offset(0, -1),
    ),
  ];

  // Game specific colors
  static Color get correctAnswerColor => successColor;
  static Color get wrongAnswerColor => errorColor;
  static Color get lifeColor => errorColor;
  static Color get scoreColor => accentColor;

  // Light theme (dynamic)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: LocationBasedService.currentTimeOfDay == TimeOfDay.night ? Brightness.dark : Brightness.light,
        primary: primaryColor,
        secondary: accentColor,
        surface: backgroundColor,
        onSurface: textPrimary,
        onPrimary: LocationBasedService.currentTimeOfDay == TimeOfDay.night ? const Color(0xFFF5F1E8) : const Color(0xFFF5F1E8),
        onSecondary: LocationBasedService.currentTimeOfDay == TimeOfDay.night ? const Color(0xFFF5F1E8) : const Color(0xFF3E2723),
      ),
      primarySwatch: _createMaterialColor(primaryColor),
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'Breamcatcher',
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 8,
        shadowColor: color1.withAlpha(77),  // 0.3 -> 77
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: color2.withAlpha(51),  // 0.2 -> 51
            width: 1,
          ),
        ),
      ),

      // ElevatedButton theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: const Color(0xFFF5F1E8),
          elevation: 8,
          shadowColor: color2.withAlpha(128),  // 0.5 -> 128
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(
              color: color2.withAlpha(77),  // 0.3 -> 77
              width: 2,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),

      // OutlinedButton theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),

      // InputDecoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color3.withAlpha(153)),  // 0.6 -> 153
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color3.withAlpha(153)),  // 0.6 -> 153
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textSecondary.withAlpha(204)),  // 0.8 -> 204
        fillColor: backgroundColor.withAlpha(204),  // 0.8 -> 204
        filled: true,
      ),

      // SnackBar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryColor.withAlpha(230),  // 0.9 -> 230
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentTextStyle: const TextStyle(
          color: Color(0xFFF5F1E8),
          fontWeight: FontWeight.w500,
        ),
      ),

      // NavigationBar theme with enhanced contrast
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBarColor,
        indicatorColor: LocationBasedService.currentTimeOfDay == TimeOfDay.night
            ? nightColor1.withAlpha(179)    // 0.7 -> 179
            : color2.withAlpha(179),        // 0.7 -> 179
        elevation: 15,
        height: 65,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: LocationBasedService.currentTimeOfDay == TimeOfDay.night
                  ? const Color(0xFFFFD700)   // Victory gold for night
                  : const Color(0xFFF5E6D3),  // Vintage cream for day
              fontWeight: FontWeight.w800,    // Bolder text
              fontSize: 13,                   // Slightly larger text
              letterSpacing: 0.5,            // Better text spacing
            );
          }
          return TextStyle(
            color: navIconUnselected,
            fontWeight: FontWeight.w600,
            fontSize: 12,
            letterSpacing: 0.3,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: LocationBasedService.currentTimeOfDay == TimeOfDay.night
                  ? const Color(0xFFFFD700)   // Victory gold for night
                  : const Color(0xFFF5E6D3),  // Vintage cream for day
              size: 28,                       // Larger icons
            );
          }
          return IconThemeData(
            color: navIconUnselected,
            size: 24,
          );
        }),
      ),

      // Text theme with proper sizing - IMPROVED TYPOGRAPHY
      textTheme: TextTheme(
        // Display styles - for hero/splash text
        displayLarge: TextStyle(
          fontFamily: 'Breamcatcher',
          color: textPrimary,
          fontSize: 32,        // Large display text
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          height: 1.1,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Breamcatcher',
          color: textPrimary,
          fontSize: 28,        // Medium display text
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          height: 1.2,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Breamcatcher',
          color: textPrimary,
          fontSize: 24,        // Small display text
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          height: 1.2,
        ),
        
        // Headline styles - for major headings
        headlineLarge: TextStyle(
          fontFamily: 'Breamcatcher',
          color: textPrimary,
          fontSize: 22,        // Large headline - significantly reduced from 45
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Breamcatcher',
          color: textPrimary,
          fontSize: 20,        // Medium headline - reduced from 30
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Breamcatcher',
          color: textPrimary,
          fontSize: 18,        // Small headline - reduced from 20
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          height: 1.4,
        ),
        
        // Title styles - for section titles and card headers
        titleLarge: TextStyle(
          fontFamily: 'Breamcatcher',
          color: textPrimary,
          fontSize: 18,        // Large title - significantly reduced from 45
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          height: 1.4,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Breamcatcher',
          color: textSecondary,
          fontSize: 16,        // Medium title - reduced from 30
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          height: 1.4,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Breamcatcher',
          color: textSecondary,
          fontSize: 14,        // Small title - reduced from 20
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        
        // Body styles - for main content
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,        // Large body text - significantly reduced from 30
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: textPrimary,
          fontSize: 14,        // Medium body text - reduced from 20
          fontWeight: FontWeight.w400,
          letterSpacing: 0.05,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: textSecondary,
          fontSize: 12,        // Small body text
          fontWeight: FontWeight.w400,
          letterSpacing: 0.05,
          height: 1.4,
        ),
        
        // Label styles - for buttons, tabs, and small labels
        labelLarge: TextStyle(
          color: textPrimary,
          fontSize: 12,        // Large label - increased from 12
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        labelMedium: TextStyle(
          color: textPrimary,
          fontSize: 12,        // Medium label
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
        labelSmall: TextStyle(
          color: textSecondary,
          fontSize: 10,        // Small label
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // Helper to create MaterialColor from Color
  static MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = (color.r * 255.0).round() & 0xff,
              g = (color.g * 255.0).round() & 0xff,
              b = (color.b * 255.0).round() & 0xff;
    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }

    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.toARGB32(), swatch);
  }

  // Common gradients (propaganda style)
  static LinearGradient get primaryGradient {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color2,
        color2.withAlpha(204),  // 0.8 -> 204
        color1.withAlpha(153),  // 0.6 -> 153
      ],
      stops: const [0.0, 0.6, 1.0],
    );
  }

  static LinearGradient get backgroundGradient {
    switch (LocationBasedService.currentTimeOfDay) {
      case TimeOfDay.morning:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            morningColor4,
            morningColor4.withAlpha(204),  // 0.8 -> 204
            morningColor1.withAlpha(153),  // 0.6 -> 153
          ],
          stops: const [0.0, 0.7, 1.0],
        );
      case TimeOfDay.afternoon:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            afternoonColor4,
            afternoonColor4.withAlpha(204),  // 0.8 -> 204
            afternoonColor1.withAlpha(102),  // 0.4 -> 102
          ],
          stops: const [0.0, 0.7, 1.0],
        );
      case TimeOfDay.night:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            nightColor4,
            nightColor4.withAlpha(204),  // 0.8 -> 204
            nightColor1.withAlpha(102),  // 0.4 -> 102
          ],
          stops: const [0.0, 0.7, 1.0],
        );
    }
  }

  static LinearGradient get cardGradient {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryColor.withAlpha(204),  // 0.8 -> 204
        primaryColor.withAlpha(153),  // 0.6 -> 153
      ],
    );
  }

  // Time-specific vintage gradients
  static LinearGradient get timeBasedBackgroundGradient {
    switch (LocationBasedService.currentTimeOfDay) {
      case TimeOfDay.morning:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            morningColor2.withAlpha(102),  // 0.4 -> 102
            morningColor4,
            morningColor1.withAlpha(77),   // 0.3 -> 77
          ],
        );
      case TimeOfDay.afternoon:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            afternoonColor2.withAlpha(102),  // 0.4 -> 102
            afternoonColor4,
            afternoonColor1.withAlpha(77),   // 0.3 -> 77
          ],
        );
      case TimeOfDay.night:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            nightColor4,
            nightColor1,
            nightColor2,
          ],
        );
    }
  }

  // Enhanced shadows for propaganda style
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: color2.withAlpha(51),  // 0.2 -> 51
      blurRadius: 12,
      spreadRadius: 2,
      offset: const Offset(4, 4),
    ),
    BoxShadow(
      color: Colors.black.withAlpha(26),  // 0.1 -> 26
      blurRadius: 8,
      spreadRadius: 0,
      offset: const Offset(2, 2),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: color2.withAlpha(77),  // 0.3 -> 77
      blurRadius: 16,
      spreadRadius: 2,
      offset: const Offset(6, 6),
    ),
    BoxShadow(
      color: Colors.black.withAlpha(51),  // 0.2 -> 51
      blurRadius: 12,
      spreadRadius: 0,
      offset: const Offset(3, 3),
    ),
  ];

  // Utility methods
  static String get currentTimeOfDayString => LocationBasedService.currentTimeOfDayString;
  static TimeOfDay get currentTimeOfDay => LocationBasedService.currentTimeOfDay;
  static String get currentTimeZone => LocationBasedService.currentTimeZone;
  static DateTime? get currentLocalTime => LocationBasedService.currentLocalTime;
  
  // Force update theme (useful for testing or manual refresh)
  static Future<void> forceUpdateTheme() async {
    await LocationBasedService.forceUpdate();
  }

  // Check if we have accurate time data
  static bool get hasAccurateTimeData => LocationBasedService.hasAccurateTimeData;
  static bool get hasLocationData => LocationBasedService.hasLocationData;
}

// Enhanced theme-aware widget with periodic updates
class ThemeAwareWidget extends StatefulWidget {
  final Widget child;
  final Duration? updateInterval; // Optional periodic update
  
  const ThemeAwareWidget({
    Key? key, 
    required this.child,
    this.updateInterval,
  }) : super(key: key);

  @override
  State<ThemeAwareWidget> createState() => _ThemeAwareWidgetState();
}

class _ThemeAwareWidgetState extends State<ThemeAwareWidget> {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    // Initialize theme on widget creation
    _initializeTheme();
    
    // Set up periodic updates if specified
    if (widget.updateInterval != null) {
      _updateTimer = Timer.periodic(widget.updateInterval!, (timer) {
        _updateTheme();
      });
    }
  }

  Future<void> _initializeTheme() async {
    await DynamicAppTheme.updateTheme();
    if (mounted) setState(() {});
  }

  Future<void> _updateTheme() async {
    await DynamicAppTheme.forceUpdateTheme();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DynamicAppTheme.lightTheme,
      child: widget.child,
    );
  }
}

// Debug widget to show current theme information
class ThemeDebugInfo extends StatelessWidget {
  const ThemeDebugInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeInfo = DynamicAppTheme.timeInfo;
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vintage Theme Debug Info',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Time of Day', timeInfo['timeOfDayString']),
            _buildInfoRow('Time Zone', timeInfo['timeZone'] ?? 'Unknown'),
            _buildInfoRow('Local Time', timeInfo['localDateTime']?.toString() ?? 'N/A'),
            _buildInfoRow('Day of Year', timeInfo['dayOfYear']?.toString() ?? 'N/A'),
            _buildInfoRow('DST Active', timeInfo['isDayLightSaving']?.toString() ?? 'N/A'),
            _buildInfoRow('Location Access', timeInfo['hasLocationAccess'].toString()),
            _buildInfoRow('TimeAPI Data', timeInfo['hasTimeApiData'].toString()),
            _buildInfoRow('Latitude', timeInfo['latitude']?.toStringAsFixed(4) ?? 'N/A'),
            _buildInfoRow('Longitude', timeInfo['longitude']?.toStringAsFixed(4) ?? 'N/A'),
            const SizedBox(height: 16),
            // Color palette preview
            _buildColorPalette(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildColorPalette() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Vintage Color Palette:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildColorBox(DynamicAppTheme.color1, 'Primary'),
            _buildColorBox(DynamicAppTheme.color2, 'Secondary'),
            _buildColorBox(DynamicAppTheme.color3, 'Accent'),
            _buildColorBox(DynamicAppTheme.color4, 'Background'),
            _buildColorBox(DynamicAppTheme.color5, 'Surface'),
          ],
        ),
      ],
    );
  }

  Widget _buildColorBox(Color color, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 30,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade400.withAlpha(128)),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(77),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}