import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class EncryptionService {
  static const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  static final Random _random = Random.secure();

  // Generate a random salt
  static String generateSalt([int length = 32]) {
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => _chars.codeUnitAt(_random.nextInt(_chars.length)),
    ));
  }

  // Hash password with HMAC-MD5
  static String hashPassword(String password, String salt) {
    var key = utf8.encode(salt);
    var bytes = utf8.encode(password);
    var hmacMd5 = Hmac(md5, key);
    var digest = hmacMd5.convert(bytes);
    return digest.toString();
  }

  // Verify password
  static bool verifyPassword(String password, String hashedPassword, String salt) {
    var computedHash = hashPassword(password, salt);
    return computedHash == hashedPassword;
  }
} 