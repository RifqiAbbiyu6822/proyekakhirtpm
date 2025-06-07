import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ImageService {
  static final ImagePicker _picker = ImagePicker();
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Get Android SDK version
  static Future<int> _getAndroidSDK() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    }
    return 0;
  }

  // Request camera and storage permissions
  static Future<bool> requestPermissions() async {
    logger.i('Starting permission requests...');
    try {
      if (Platform.isAndroid) {
        final sdkInt = await _getAndroidSDK();
        logger.d('Android SDK version: $sdkInt');

        // For Android 13 (API 33) and above
        if (sdkInt >= 33) {
          logger.d('Using Android 13+ permission model');
          
          // Request photos permission
          logger.d('Requesting photos permission...');
          var photosStatus = await Permission.photos.request();
          logger.i('Photos permission status: $photosStatus');
          
          // Request camera permission
          logger.d('Requesting camera permission...');
          var cameraStatus = await Permission.camera.request();
          logger.i('Camera permission status: $cameraStatus');
          
          // Request videos permission (might be needed for some image pickers)
          logger.d('Requesting videos permission...');
          var videosStatus = await Permission.videos.request();
          logger.i('Videos permission status: $videosStatus');

          return photosStatus.isGranted && 
                 cameraStatus.isGranted && 
                 videosStatus.isGranted;
        }
        // For Android 10-12 (API 29-32)
        else if (sdkInt >= 29) {
          logger.d('Using Android 10-12 permission model');
          
          // Request storage permission
          logger.d('Requesting storage permission...');
          var storageStatus = await Permission.storage.request();
          logger.i('Storage permission status: $storageStatus');
          
          // Request camera permission
          logger.d('Requesting camera permission...');
          var cameraStatus = await Permission.camera.request();
          logger.i('Camera permission status: $cameraStatus');

          return storageStatus.isGranted && cameraStatus.isGranted;
        }
        // For Android 9 and below (API <= 28)
        else {
          logger.d('Using legacy Android permission model');
          
          // Request storage permission
          logger.d('Requesting storage permission...');
          var storageStatus = await Permission.storage.request();
          logger.i('Storage permission status: $storageStatus');
          
          // Request camera permission
          logger.d('Requesting camera permission...');
          var cameraStatus = await Permission.camera.request();
          logger.i('Camera permission status: $cameraStatus');

          return storageStatus.isGranted && cameraStatus.isGranted;
        }
      }
      // For iOS or other platforms
      else {
        logger.d('Using non-Android permission model');
        
        // Request photos permission
        logger.d('Requesting photos permission...');
        var photosStatus = await Permission.photos.request();
        logger.i('Photos permission status: $photosStatus');
        
        // Request camera permission
        logger.d('Requesting camera permission...');
        var cameraStatus = await Permission.camera.request();
        logger.i('Camera permission status: $cameraStatus');

        return photosStatus.isGranted && cameraStatus.isGranted;
      }
    } catch (e) {
      logger.e('Error requesting permissions: $e');
      return false;
    }
  }

  // Pick image from gallery
  static Future<File?> pickImageFromGallery() async {
    logger.i('Attempting to pick image from gallery...');
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        logger.i('Image picked successfully from gallery: ${image.path}');
        return File(image.path);
      }
      logger.w('No image selected from gallery');
      return null;
    } catch (e) {
      logger.e('Error picking image from gallery: $e');
      return null;
    }
  }

  // Take photo using camera
  static Future<File?> takePhoto() async {
    logger.i('Attempting to take photo...');
    try {
      // Verify permissions first
      final hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        logger.e('Camera permissions not granted');
        return null;
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (photo != null) {
        logger.i('Photo taken successfully at: ${photo.path}');
        
        try {
          // Create a File instance from the XFile
          final File tempFile = File(photo.path);
          
          // Verify the file exists
          if (!await tempFile.exists()) {
            logger.e('Camera file does not exist at: ${photo.path}');
            return null;
          }
          
          logger.i('Camera file verified at: ${photo.path}');
          return tempFile;
        } catch (e) {
          logger.e('Error processing camera file: $e');
          return null;
        }
      }
      
      logger.w('No photo taken - user cancelled');
      return null;
    } catch (e) {
      logger.e('Error taking photo: $e');
      return null;
    }
  }

  // Get profile images directory
  static Future<Directory> _getProfileImagesDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final profileImagesDir = Directory('${appDir.path}/assets/profile_images');
    
    if (!await profileImagesDir.exists()) {
      await profileImagesDir.create(recursive: true);
    }
    
    return profileImagesDir;
  }

  // Save profile image to local storage
  static Future<String?> saveProfileImage(File image, String userId) async {
    logger.i('Starting to save profile image for user $userId from: ${image.path}');
    try {
      final profileImagesDir = await _getProfileImagesDir();
      logger.d('Profile images directory path: ${profileImagesDir.path}');

      // Generate unique filename with timestamp to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'profile_${userId}_$timestamp${path.extension(image.path)}';
      final relativePath = 'assets/profile_images/$filename';
      final targetPath = '${profileImagesDir.path}/$filename';
      logger.d('Target file path: $targetPath');

      try {
        // Verify source image exists and is readable
        if (!await image.exists()) {
          logger.e('Source image does not exist at: ${image.path}');
          return null;
        }

        // Ensure the target directory exists
        final targetDir = Directory(path.dirname(targetPath));
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
          logger.d('Created target directory: ${targetDir.path}');
        }

        // Copy the image file
        final savedImage = await image.copy(targetPath);
        logger.i('Image copied successfully to: ${savedImage.path}');
        
        // Verify the saved file exists and is readable
        if (await savedImage.exists()) {
          try {
            // Try to read the file to ensure it's valid
            await savedImage.readAsBytes();
            logger.d('Verified: Saved file is readable at ${savedImage.path}');
            
            // Delete old profile images
            final directory = await getApplicationDocumentsDirectory();
            final files = await directory
                .list(recursive: true)
                .where((entity) => 
                    entity is File && 
                    path.basename(entity.path).startsWith('profile_$userId'))
                .cast<File>()
                .toList();
                
            for (var file in files) {
              if (file.path != savedImage.path) {
                try {
                  await file.delete();
                  logger.d('Deleted old profile image: ${file.path}');
                } catch (e) {
                  logger.e('Error deleting old profile image: $e');
                }
              }
            }
            
            return relativePath;
          } catch (e) {
            logger.e('Saved file exists but is not readable: $e');
            return null;
          }
        } else {
          logger.e('Failed to verify saved image at: $targetPath');
          return null;
        }
      } catch (e) {
        logger.e('Error copying image file: $e');
        return null;
      }
    } catch (e) {
      logger.e('Error in saveProfileImage: $e');
      return null;
    }
  }

  // Delete profile image
  static Future<bool> deleteProfileImage(String imagePath) async {
    logger.i('Attempting to delete profile image at: $imagePath');
    try {
      File? fileToDelete;
      
      // First try the path as is
      var file = File(imagePath);
      logger.d('Checking direct path: ${file.path}');
      if (await file.exists()) {
        fileToDelete = file;
      } else {
        logger.d('File not found at direct path');

        // If not found, try resolving from app documents directory
        final appDir = await getApplicationDocumentsDirectory();
        final fullPath = path.join(appDir.path, imagePath);
        logger.d('Checking resolved path: $fullPath');
        file = File(fullPath);
        
        if (await file.exists()) {
          fileToDelete = file;
        }
      }

      if (fileToDelete != null) {
        await fileToDelete.delete();
        logger.i('Profile image deleted successfully from path: ${fileToDelete.path}');
        return true;
      }
      
      // Log the directory contents for debugging
      final appDir = await getApplicationDocumentsDirectory();
      final directory = Directory(path.join(appDir.path, 'assets/profile_images'));
      if (await directory.exists()) {
        logger.d('Directory contents of ${directory.path}:');
        await for (var entity in directory.list()) {
          logger.d('Found file: ${entity.path}');
        }
      } else {
        logger.d('Directory does not exist: ${directory.path}');
      }
      
      logger.w('Profile image file not found at any path');
      return false;
    } catch (e) {
      logger.e('Error deleting profile image: $e');
      return false;
    }
  }

  // Get image file from path
  static Future<File?> getImageFile(String? imagePath) async {
    if (imagePath == null) {
      logger.w('Image path is null');
      return null;
    }
    
    logger.i('Attempting to get image file from path: $imagePath');
    try {
      // First try the path as is
      var file = File(imagePath);
      if (await file.exists()) {
        logger.i('Image file found successfully at direct path');
        return file;
      }

      // If not found, try resolving from app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final fullPath = path.join(appDir.path, imagePath);
      file = File(fullPath);
      
      if (await file.exists()) {
        logger.i('Image file found successfully at resolved path');
        return file;
      }
      
      logger.w('Image file not found at any path');
      return null;
    } catch (e) {
      logger.e('Error getting image file: $e');
      return null;
    }
  }
} 