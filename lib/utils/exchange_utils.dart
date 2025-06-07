// utils/exchange_utils.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
// Model for Currency information
class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;
  final double exchangeRate;

  CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
    required this.exchangeRate,
  });

  factory CurrencyInfo.fromJson(Map<String, dynamic> json) {
    return CurrencyInfo(
      code: json['code'] ?? 'USD',
      name: json['name'] ?? 'US Dollar',
      symbol: json['symbol'] ?? '\$',
      exchangeRate: (json['rate'] ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'symbol': symbol,
      'exchangeRate': exchangeRate,
    };
  }
}

class ExchangeUtils {
  static final Logger _logger = Logger();
  
  // Currency mapping for countries
static final Map<String, Map<String, String>> countryCurrencyMap = {
  'US': {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
  'ID': {'code': 'IDR', 'name': 'Indonesian Rupiah', 'symbol': 'Rp'},
  'MY': {'code': 'MYR', 'name': 'Malaysian Ringgit', 'symbol': 'RM'},
  'SG': {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': 'S\$'},
  'TH': {'code': 'THB', 'name': 'Thai Baht', 'symbol': '฿'},
  'PH': {'code': 'PHP', 'name': 'Philippine Peso', 'symbol': '₱'},
  'VN': {'code': 'VND', 'name': 'Vietnamese Dong', 'symbol': '₫'},
  'GB': {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
  'EU': {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
  'DE': {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
  'FR': {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
  'IT': {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
  'ES': {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
  'JP': {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
  'KR': {'code': 'KRW', 'name': 'South Korean Won', 'symbol': '₩'},
  'CN': {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥'},
  'IN': {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
  'AU': {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'A\$'},
  'CA': {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': 'C\$'},
  'BR': {'code': 'BRL', 'name': 'Brazilian Real', 'symbol': 'R\$'},
  'MX': {'code': 'MXN', 'name': 'Mexican Peso', 'symbol': '\$'},
  'ZA': {'code': 'ZAR', 'name': 'South African Rand', 'symbol': 'R'},
  'RU': {'code': 'RUB', 'name': 'Russian Ruble', 'symbol': '₽'},
  'CH': {'code': 'CHF', 'name': 'Swiss Franc', 'symbol': 'Fr'},
  'SE': {'code': 'SEK', 'name': 'Swedish Krona', 'symbol': 'kr'},
  'NO': {'code': 'NOK', 'name': 'Norwegian Krone', 'symbol': 'kr'},
  'DK': {'code': 'DKK', 'name': 'Danish Krone', 'symbol': 'kr'},
  'FI': {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
  'AE': {'code': 'AED', 'name': 'United Arab Emirates Dirham', 'symbol': 'د.إ'},
  'SA': {'code': 'SAR', 'name': 'Saudi Riyal', 'symbol': 'ر.س'},
  'EG': {'code': 'EGP', 'name': 'Egyptian Pound', 'symbol': 'ج.م'},
  'NG': {'code': 'NGN', 'name': 'Nigerian Naira', 'symbol': '₦'},
  'AR': {'code': 'ARS', 'name': 'Argentine Peso', 'symbol': '\$'},
  'CO': {'code': 'COP', 'name': 'Colombian Peso', 'symbol': '\$'},
  'PE': {'code': 'PEN', 'name': 'Peruvian Nuevo Sol', 'symbol': 'S/.'},
  'CL': {'code': 'CLP', 'name': 'Chilean Peso', 'symbol': '\$'},
  'CR': {'code': 'CRC', 'name': 'Costa Rican Colón', 'symbol': '₡'},
  'GT': {'code': 'GTQ', 'name': 'Guatemalan Quetzal', 'symbol': 'Q'},
  'HN': {'code': 'HNL', 'name': 'Honduran Lempira', 'symbol': 'L'},
  'PY': {'code': 'PYG', 'name': 'Paraguayan Guarani', 'symbol': '₲'},
  'UY': {'code': 'UYU', 'name': 'Uruguayan Peso', 'symbol': '\$'},
  'TW': {'code': 'TWD', 'name': 'New Taiwan Dollar', 'symbol': 'NT\$'},
  'HK': {'code': 'HKD', 'name': 'Hong Kong Dollar', 'symbol': 'HK\$'},
  'MO': {'code': 'MOP', 'name': 'Macanese Pataca', 'symbol': 'MOP'},
  'PT': {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
  'PL': {'code': 'PLN', 'name': 'Polish Zloty', 'symbol': 'zł'},
  'CZ': {'code': 'CZK', 'name': 'Czech Koruna', 'symbol': 'Kč'},
  'SK': {'code': 'SKK', 'name': 'Slovak Koruna', 'symbol': 'Sk'},
  'HU': {'code': 'HUF', 'name': 'Hungarian Forint', 'symbol': 'Ft'},
  'RO': {'code': 'RON', 'name': 'Romanian Leu', 'symbol': 'lei'},
  'BG': {'code': 'BGN', 'name': 'Bulgarian Lev', 'symbol': 'лв'},
  'RS': {'code': 'RSD', 'name': 'Serbian Dinar', 'symbol': 'дин.'},
  'HR': {'code': 'HRK', 'name': 'Croatian Kuna', 'symbol': 'kn'},
  'ME': {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
  'SI': {'code': 'SIT', 'name': 'Slovenian Tolar', 'symbol': 'SIT'},
  'MK': {'code': 'MKD', 'name': 'Macedonian Denar', 'symbol': 'ден'},
  'AL': {'code': 'ALL', 'name': 'Albanian Lek', 'symbol': 'L'},
  'KZ': {'code': 'KZT', 'name': 'Kazakhstani Tenge', 'symbol': '₸'},
  'KG': {'code': 'KGS', 'name': 'Kyrgyzstani Som', 'symbol': 'с'},
  'TJ': {'code': 'TJS', 'name': 'Tajikistani Somoni', 'symbol': 'SM'},
  'TM': {'code': 'TMT', 'name': 'Turkmenistan Manat', 'symbol': 'm'},
  'UZ': {'code': 'UZS', 'name': 'Uzbekistani Som', 'symbol': 'сум'},
  'AZ': {'code': 'AZN', 'name': 'Azerbaijani Manat', 'symbol': '₼'},
  'AM': {'code': 'AMD', 'name': 'Armenian Dram', 'symbol': 'դր'},
  'GE': {'code': 'GEL', 'name': 'Georgian Lari', 'symbol': 'ლ'},
};


  // Get exchange rate from a free API
  static Future<double> getExchangeRate(String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) return 1.0;
    
    try {
      // Using exchangerate-api.com (free tier available)
      final url = 'https://api.exchangerate-api.com/v4/latest/$fromCurrency';
      _logger.d('Fetching exchange rate from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final rates = jsonData['rates'] as Map<String, dynamic>;
        return (rates[toCurrency] ?? 1.0).toDouble();
      }
    } catch (e) {
      _logger.e('Error fetching exchange rate: $e');
    }
    return 1.0; // Default rate
  }

  // Determine currency based on country
  static Future<CurrencyInfo> getCurrencyInfo(String countryCode) async {
    final currencyData = countryCurrencyMap[countryCode.toUpperCase()] ?? 
                        countryCurrencyMap['US']!; // Default to USD
    
    // Get exchange rate from USD to local currency
    final exchangeRate = await getExchangeRate('USD', currencyData['code']!);
    
    return CurrencyInfo(
      code: currencyData['code']!,
      name: currencyData['name']!,
      symbol: currencyData['symbol']!,
      exchangeRate: exchangeRate,
    );
  }

  // Calculate donation amount in local currency
  static double calculateLocalDonationAmount(double usdAmount, CurrencyInfo currencyInfo) {
    return usdAmount * currencyInfo.exchangeRate;
  }

  // Format currency amount
  static String formatCurrencyAmount(double amount, CurrencyInfo currencyInfo) {
    final symbol = currencyInfo.symbol;
    final code = currencyInfo.code;
    
    // Format number with thousand separators
    String formatNumber(double n, int decimals) {
      String num = n.toStringAsFixed(decimals);
      final parts = num.split('.');
      final wholePart = parts[0];
      final decimalPart = parts.length > 1 ? '.${parts[1]}' : '';
      
      // Add thousand separators
      final formattedWholePart = wholePart.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
      
      return formattedWholePart + decimalPart;
    }
    
    // Format based on currency
    switch (code) {
      case 'IDR':
      case 'VND':
      case 'KRW':
      case 'JPY':
        return '$symbol${formatNumber(amount, 0)}';
      default:
        return '$symbol${formatNumber(amount, 2)}';
    }
  }

  // Get currency by country code without exchange rate
  static Map<String, String>? getCurrencyByCountryCode(String countryCode) {
    return countryCurrencyMap[countryCode.toUpperCase()];
  }

  // Get all supported currencies
  static List<String> getSupportedCurrencies() {
    return countryCurrencyMap.values
        .map((currency) => currency['code']!)
        .toSet()
        .toList();
  }

  // Get all supported countries
  static List<String> getSupportedCountries() {
    return countryCurrencyMap.keys.toList();
  }

  // Check if country is supported
  static bool isCountrySupported(String countryCode) {
    return countryCurrencyMap.containsKey(countryCode.toUpperCase());
  }

  // Check if currency is supported
  static bool isCurrencySupported(String currencyCode) {
    return countryCurrencyMap.values
        .any((currency) => currency['code'] == currencyCode.toUpperCase());
  }
}