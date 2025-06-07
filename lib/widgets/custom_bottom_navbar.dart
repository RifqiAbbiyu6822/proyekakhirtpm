import 'package:flutter/material.dart' hide TimeOfDay;
import '../theme/theme.dart';
import '../controllers/lbs_service.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const CustomBottomNavBar({Key? key, required this.selectedIndex}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure selectedIndex is valid (between 0 and 4)
    final validSelectedIndex = selectedIndex.clamp(0, 4);

    return Container(
      decoration: BoxDecoration(
        color: DynamicAppTheme.navBarColor,
        boxShadow: DynamicAppTheme.navBarShadow,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: LocationBasedService.currentTimeOfDay == TimeOfDay.night
                      ? const Color(0xFFFFD700) // Victory gold for night
                      : const Color(0xFFF5E6D3), // Vintage cream for day
                  fontWeight: FontWeight.bold,
                );
              }
              return Theme.of(context).textTheme.labelLarge?.copyWith(
                color: DynamicAppTheme.navIconUnselected,
              );
            }),
          ),
        ),
        child: NavigationBar(
          selectedIndex: validSelectedIndex,
          backgroundColor: Colors.transparent,
          indicatorColor: LocationBasedService.currentTimeOfDay == TimeOfDay.night
              ? DynamicAppTheme.nightColor1.withValues(alpha: 179, red: null, green: null, blue: null) // 0.7 * 255 ≈ 179
              : DynamicAppTheme.color2.withValues(alpha: 179, red: null, green: null, blue: null),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          animationDuration: const Duration(milliseconds: 400),
          height: 65,
          destinations: [
            _buildDestination(
              selectedIndex: validSelectedIndex,
              index: 0,
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'Home',
            ),
            _buildDestination(
              selectedIndex: validSelectedIndex,
              index: 1,
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'Profile',
            ),
            _buildDestination(
              selectedIndex: validSelectedIndex,
              index: 2,
              icon: Icons.notifications_outlined,
              selectedIcon: Icons.notifications,
              label: 'Notifications',
            ),
            _buildDestination(
              selectedIndex: validSelectedIndex,
              index: 3,
              icon: Icons.help_outline,
              selectedIcon: Icons.help,
              label: 'Support',
            ),
            _buildDestination(
              selectedIndex: validSelectedIndex,
              index: 4,
              icon: Icons.feedback_outlined,
              selectedIcon: Icons.feedback,
              label: 'Feedback',
            ),
          ],
          onDestinationSelected: (index) {
            if (index == validSelectedIndex) return;

            switch (index) {
              case 0:
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                break;
              case 1:
                Navigator.pushNamed(context, '/profile');
                break;
              case 2:
                Navigator.pushNamed(context, '/notifications');
                break;
              case 3:
                Navigator.pushNamed(context, '/support');
                break;
              case 4:
                Navigator.pushNamed(context, '/feedback');
                break;
            }
          },
        ),
      ),
    );
  }

  NavigationDestination _buildDestination({
    required int selectedIndex,
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;
    final selectedColor = LocationBasedService.currentTimeOfDay == TimeOfDay.night
        ? const Color(0xFFFFD700) // Victory gold for night
        : const Color(0xFFF5E6D3); // Vintage cream for day

    return NavigationDestination(
      icon: Icon(
        icon,
        color: isSelected ? selectedColor : DynamicAppTheme.navIconUnselected,
        size: 24,
      ),
      selectedIcon: Icon(
        selectedIcon,
        color: selectedColor,
        size: 28,
      ),
      label: label,
    );
  }
}