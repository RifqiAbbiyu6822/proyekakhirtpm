import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../controllers/lbs_service.dart';

class LocationInfo extends StatelessWidget {
  final String locationText;
  final String currencyCode;
  final double localDonationAmount;

  const LocationInfo({
    Key? key,
    required this.locationText,
    required this.currencyCode,
    required this.localDonationAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
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
    );
  }
} 