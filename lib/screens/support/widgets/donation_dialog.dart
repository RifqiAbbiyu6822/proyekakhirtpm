import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../controllers/lbs_service.dart';

class DonationDialog extends StatelessWidget {
  final double localDonationAmount;
  final double baseDonationAmountUSD;
  final String currencyCode;
  final String locationText;
  final VoidCallback onDonate;

  const DonationDialog({
    Key? key,
    required this.localDonationAmount,
    required this.baseDonationAmountUSD,
    required this.currencyCode,
    required this.locationText,
    required this.onDonate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedAmount = LocationBasedService.formatCurrencyAmount(localDonationAmount);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DynamicAppTheme.cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support Us',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: DynamicAppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Would you like to donate $formattedAmount to support development?',
                    style: TextStyle(color: DynamicAppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  if (currencyCode != 'USD')
                    Text(
                      'Equivalent to \$${baseDonationAmountUSD.toStringAsFixed(2)} USD',
                      style: TextStyle(
                        fontSize: 12,
                        color: DynamicAppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: DynamicAppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          locationText,
                          style: TextStyle(
                            fontSize: 12,
                            color: DynamicAppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DynamicAppTheme.cardColor,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: DynamicAppTheme.textSecondary,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onDonate();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DynamicAppTheme.primaryColor,
                      foregroundColor: DynamicAppTheme.surfaceColor,
                    ),
                    child: Text('Donate $formattedAmount'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 