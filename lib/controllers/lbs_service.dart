import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';
import '../utils/exchange_utils.dart'; // Import the new exchange utils
import '../services/permission_service.dart'; // Import the permission service

enum TimeOfDay { morning, afternoon, night }

// Model for TimeAPI response
class TimeApiResponse {
  final DateTime dateTime;
  final String timeZone;
  final int dayOfWeek;
  final int dayOfYear;
  final bool isDayLightSavingsTime;

  TimeApiResponse({
    required this.dateTime,
    required this.timeZone,
    required this.dayOfWeek,
    required this.dayOfYear,
    required this.isDayLightSavingsTime,
  });

  factory TimeApiResponse.fromJson(Map<String, dynamic> json) {
    return TimeApiResponse(
      dateTime: DateTime.parse(json['dateTime']),
      timeZone: json['timeZone'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? 0,
      dayOfYear: json['dayOfYear'] ?? 0,
      isDayLightSavingsTime: json['isDayLightSavingsTime'] ?? false,
    );
  }
}

// Model for Location information from reverse geocoding
class LocationInfo {
  final String country;
  final String countryCode;
  final String city;
  final String state;

  LocationInfo({
    required this.country,
    required this.countryCode,
    required this.city,
    required this.state,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      country: json['country'] ?? '',
      countryCode: json['country_code'] ?? '',
      city: json['city'] ?? json['town'] ?? json['village'] ?? '',
      state: json['state'] ?? json['province'] ?? '',
    );
  }
}

class LocationBasedService {
  static final Logger _log = Logger('LocationBasedService');
  
  // Current location and time data
  static Position? _currentPosition;
  static TimeApiResponse? _currentTimeData;
  static LocationInfo? _currentLocationInfo;
  static CurrencyInfo? _currentCurrencyInfo;
  static String _currentTimeZone = '';
  static TimeOfDay _currentTimeOfDay = TimeOfDay.morning;

  static void initLogging() {
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  // Get current location
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _log.warning('Location services are disabled.');
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _log.warning('Location permissions are denied');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _log.warning('Location permissions are permanently denied');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      _log.severe('Error getting location: $e');
      return null;
    }
  }

  // Reverse geocoding to get country information
  static Future<LocationInfo?> getLocationInfo(double latitude, double longitude) async {
    try {
      // Using Nominatim API (OpenStreetMap) - free and reliable
      final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=10&addressdetails=1';
      _log.info('Fetching location info from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'YourAppName/1.0', // Required by Nominatim
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        _log.fine('Location API Response: $jsonData');
        
        if (jsonData['address'] != null) {
          return LocationInfo.fromJson(jsonData['address']);
        }
      } else {
        _log.warning('Location API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _log.severe('Error fetching location info: $e');
    }
    return null;
  }

  // Fetch time data from TimeAPI.io
  static Future<TimeApiResponse?> fetchTimeData(double latitude, double longitude) async {
    try {
      final url = 'https://timeapi.io/api/time/current/coordinate?latitude=$latitude&longitude=$longitude';
      _log.info('Fetching time data from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        _log.fine('TimeAPI Response: $jsonData');
        return TimeApiResponse.fromJson(jsonData);
      } else {
        _log.warning('TimeAPI request failed with status: ${response.statusCode}');
        _log.warning('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      _log.severe('Error fetching time data: $e');
      return null;
    }
  }

  // Determine time of day based on local time from TimeAPI
  static TimeOfDay determineTimeOfDay(TimeApiResponse timeData) {
    final localTime = timeData.dateTime;
    final hour = localTime.hour;
    
    _log.info('Local time: $localTime (Hour: $hour)');
    
    if (hour >= 5 && hour < 11) {
      return TimeOfDay.morning;     
    } else if (hour >= 11 && hour < 18) {
      return TimeOfDay.afternoon;   
    } else {
      return TimeOfDay.night;       
    }
  }

  // Fallback time determination based on device time
  static TimeOfDay fallbackTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return TimeOfDay.morning;
    } else if (hour >= 11 && hour < 18) {
      return TimeOfDay.afternoon;
    } else {
      return TimeOfDay.night;
    }
  }

  // Initialize and update location and time data
  static Future<void> updateLocationAndTime() async {
    _log.info('Updating location and time data...');
    
    try {
      // Request permissions first
      await PermissionService.checkLocationPermission();
      
      // Get current position
      final position = await getCurrentPosition();
      
      if (position != null) {
        _currentPosition = position;
        _log.info('Got position: ${position.latitude}, ${position.longitude}');
        
        // Fetch location info and currency data in parallel
        final futures = await Future.wait([
          getLocationInfo(position.latitude, position.longitude),
          fetchTimeData(position.latitude, position.longitude),
        ]);
        
        final locationInfo = futures[0] as LocationInfo?;
        final timeData = futures[1] as TimeApiResponse?;
        
        if (locationInfo != null) {
          _currentLocationInfo = locationInfo;
          _log.info('Location info updated: ${locationInfo.city}, ${locationInfo.country}');
          
          // Get currency information using ExchangeUtils
          _currentCurrencyInfo = await ExchangeUtils.getCurrencyInfo(locationInfo.countryCode);
          _log.info('Currency: ${_currentCurrencyInfo!.code} (${_currentCurrencyInfo!.symbol})');
        }
        
        if (timeData != null) {
          _currentTimeData = timeData;
          _currentTimeZone = timeData.timeZone;
          _currentTimeOfDay = determineTimeOfDay(timeData);
          _log.info('Time data updated: $_currentTimeZone (${_currentTimeOfDay.name})');
        } else {
          _currentTimeOfDay = fallbackTimeOfDay();
          _log.info('Using fallback time of day: ${_currentTimeOfDay.name}');
        }
      } else {
        // No location access - use device time and default currency
        _currentTimeOfDay = fallbackTimeOfDay();
        _currentCurrencyInfo = await ExchangeUtils.getCurrencyInfo('US'); // Default to USD
        _log.info('No location access. Using device time and USD currency');
      }
    } catch (e) {
      _log.severe('Error updating location and time: $e');
      // Ultimate fallback
      _currentTimeOfDay = fallbackTimeOfDay();
      _currentCurrencyInfo = await ExchangeUtils.getCurrencyInfo('US');
    }
  }

  // Calculate donation amount in local currency
  static double calculateLocalDonationAmount(double usdAmount) {
    if (_currentCurrencyInfo == null) return usdAmount;
    return ExchangeUtils.calculateLocalDonationAmount(usdAmount, _currentCurrencyInfo!);
  }

  // Format currency amount
  static String formatCurrencyAmount(double amount) {
    if (_currentCurrencyInfo == null) return '\$${amount.toStringAsFixed(2)}';
    return ExchangeUtils.formatCurrencyAmount(amount, _currentCurrencyInfo!);
  }

  // Get detailed location, time and currency information
  static Map<String, dynamic> get locationTimeInfo {
    return {
      'timeOfDay': _currentTimeOfDay,
      'timeOfDayString': currentTimeOfDayString,
      'timeZone': _currentTimeZone,
      'localDateTime': _currentTimeData?.dateTime,
      'dayOfYear': _currentTimeData?.dayOfYear,
      'isDayLightSaving': _currentTimeData?.isDayLightSavingsTime,
      'hasLocationAccess': _currentPosition != null,
      'hasTimeApiData': _currentTimeData != null,
      'latitude': _currentPosition?.latitude,
      'longitude': _currentPosition?.longitude,
      'country': _currentLocationInfo?.country,
      'countryCode': _currentLocationInfo?.countryCode,
      'city': _currentLocationInfo?.city,
      'state': _currentLocationInfo?.state,
      'currency': _currentCurrencyInfo?.toJson(),
    };
  }

  // Getters for current data
  static TimeOfDay get currentTimeOfDay => _currentTimeOfDay;
  static String get currentTimeZone => _currentTimeZone;
  static DateTime? get currentLocalTime => _currentTimeData?.dateTime;
  static Position? get currentPosition => _currentPosition;
  static TimeApiResponse? get currentTimeData => _currentTimeData;
  static LocationInfo? get currentLocationInfo => _currentLocationInfo;
  static CurrencyInfo? get currentCurrencyInfo => _currentCurrencyInfo;

  // Utility methods
  static String get currentTimeOfDayString {
    switch (_currentTimeOfDay) {
      case TimeOfDay.morning:
        return 'Morning';
      case TimeOfDay.afternoon:
        return 'Afternoon';
      case TimeOfDay.night:
        return 'Night';
    }
  }

  // Force update location and time data
  static Future<void> forceUpdate() async {
    await updateLocationAndTime();
  }

  // Check if we have accurate data
  static bool get hasAccurateTimeData => _currentTimeData != null;
  static bool get hasLocationData => _currentPosition != null;
  static bool get hasCompleteData => hasAccurateTimeData && hasLocationData;
  static bool get hasCurrencyData => _currentCurrencyInfo != null;
}