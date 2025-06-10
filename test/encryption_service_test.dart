import 'package:flutter_test/flutter_test.dart';
import 'package:historyquizapp/services/encryption_service.dart';

void main() {
  // Mengelompokkan tes untuk EncryptionService
  group('EncryptionService', () {
    
    test('generateSalt harus menghasilkan salt dengan panjang yang benar', () {
      // Memeriksa apakah salt yang dihasilkan adalah string dengan panjang 32
      final salt = EncryptionService.generateSalt(32);
      expect(salt, isA<String>());
      expect(salt.length, 32);
    });

    test('hashPassword harus menghasilkan hash yang konsisten untuk input yang sama', () {
      // Memastikan password yang sama dengan salt yang sama akan selalu menghasilkan hash yang sama
      const password = 'password123';
      const salt = 'saltysalt';
      final hash1 = EncryptionService.hashPassword(password, salt);
      final hash2 = EncryptionService.hashPassword(password, salt);
      expect(hash1, equals(hash2));
    });

    test('verifyPassword harus mengembalikan true untuk password yang benar', () {
      // Memverifikasi bahwa password yang benar akan divalidasi dengan sukses
      const password = 'password123';
      final salt = EncryptionService.generateSalt();
      final hashedPassword = EncryptionService.hashPassword(password, salt);
      final isValid = EncryptionService.verifyPassword(password, hashedPassword, salt);
      expect(isValid, isTrue);
    });

    test('verifyPassword harus mengembalikan false untuk password yang salah', () {
      // Memverifikasi bahwa password yang salah akan gagal divalidasi
      const password = 'password123';
      const wrongPassword = 'wrongpassword';
      final salt = EncryptionService.generateSalt();
      final hashedPassword = EncryptionService.hashPassword(password, salt);
      final isValid = EncryptionService.verifyPassword(wrongPassword, hashedPassword, salt);
      expect(isValid, isFalse);
    });
  });
}