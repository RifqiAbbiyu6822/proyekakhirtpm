import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:logger/logger.dart';

class PermissionService {
  static final logger = Logger();

  static Future<void> requestAllPermissions() async {
    if (!Platform.isAndroid) return;

    logger.i('=== Starting Permission Requests ===');
    
    // Request notification permission first (Android 13+)
    await _requestNotificationPermission();

    // Request storage permissions based on Android version
    await _requestStoragePermissions();

    // Request location permission if needed
    await _requestLocationPermission();

    logger.i('=== Permission Requests Completed ===');
    await _printPermissionStatuses();
  }

  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    logger.i('=== Requesting Storage Permissions ===');
    
    // For Android 13 and above
    if (await _isAndroid13OrHigher()) {
      logger.d('Android 13+ detected, requesting media permissions...');
      var photos = await Permission.photos.request();
      var videos = await Permission.videos.request();
      var audio = await Permission.audio.request();
      
      logger.d('Photos permission: ${await Permission.photos.status}');
      logger.d('Videos permission: ${await Permission.videos.status}');
      logger.d('Audio permission: ${await Permission.audio.status}');
      
      return photos.isGranted && videos.isGranted && audio.isGranted;
    } 
    // For Android 11-12
    else {
      logger.d('Android 11/12 detected, requesting storage permissions...');
      var storageStatus = await Permission.storage.request();
      logger.d('Storage permission: $storageStatus');
      
      var manageStatus = await Permission.manageExternalStorage.request();
      logger.d('Manage storage permission: $manageStatus');

      return storageStatus.isGranted || manageStatus.isGranted;
    }
  }

  static Future<void> _requestStoragePermissions() async {
    logger.i('=== Requesting Storage Permissions ===');
    
    // For Android 13 and above
    if (await _isAndroid13OrHigher()) {
      logger.d('Android 13+ detected, requesting media permissions...');
      await Permission.photos.request();
      await Permission.videos.request();
      await Permission.audio.request();
      
      logger.d('Photos permission: ${await Permission.photos.status}');
      logger.d('Videos permission: ${await Permission.videos.status}');
      logger.d('Audio permission: ${await Permission.audio.status}');
    } 
    // For Android 11-12
    else {
      logger.d('Android 11/12 detected, requesting storage permissions...');
      var storageStatus = await Permission.storage.request();
      logger.d('Storage permission: $storageStatus');
      
      var manageStatus = await Permission.manageExternalStorage.request();
      logger.d('Manage storage permission: $manageStatus');
    }
    
    logger.i('=== Storage Permission Requests Completed ===');
  }

  static Future<void> _requestNotificationPermission() async {
    logger.i('=== Requesting Notification Permission ===');
    var status = await Permission.notification.request();
    logger.d('Notification permission status: $status');
    logger.i('=== Notification Permission Request Completed ===');
  }

  static Future<void> _requestLocationPermission() async {
    logger.i('=== Requesting Location Permission ===');
    var status = await Permission.location.request();
    logger.d('Location permission status: $status');
    logger.i('=== Location Permission Request Completed ===');
  }

  static Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    return await Permission.photos.status != PermissionStatus.denied;
  }

  static Future<bool> checkStoragePermission() async {
    if (!Platform.isAndroid) return true;

    if (await _isAndroid13OrHigher()) {
      return await Permission.photos.isGranted &&
             await Permission.videos.isGranted &&
             await Permission.audio.isGranted;
    } else {
      var storageStatus = await Permission.storage.status;
      var manageStatus = await Permission.manageExternalStorage.status;
      return storageStatus.isGranted || manageStatus.isGranted;
    }
  }

  static Future<bool> checkNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    return await Permission.notification.isGranted;
  }

  static Future<bool> checkLocationPermission() async {
    if (!Platform.isAndroid) return true;
    return await Permission.location.isGranted;
  }

  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
      logger.i('App settings opened');
    } catch (e) {
      logger.e('Error opening settings: $e');
    }
  }

  static Future<void> _printPermissionStatuses() async {
    if (!Platform.isAndroid) return;

    logger.i('=== Current Permission Statuses ===');
    if (await _isAndroid13OrHigher()) {
      logger.d('Photos: ${await Permission.photos.status}');
      logger.d('Videos: ${await Permission.videos.status}');
      logger.d('Audio: ${await Permission.audio.status}');
    } else {
      logger.d('Storage: ${await Permission.storage.status}');
      logger.d('Manage External Storage: ${await Permission.manageExternalStorage.status}');
    }
    logger.d('Notification: ${await Permission.notification.status}');
    logger.d('Location: ${await Permission.location.status}');
    logger.i('=== End Permission Statuses ===');
  }
} 