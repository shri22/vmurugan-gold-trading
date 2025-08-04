import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// Encryption service for securing sensitive data like MPIN
class EncryptionService {
  // Salt for MPIN hashing - in production, use a more secure method
  static const String _mpinSalt = 'VMURUGAN_GOLD_MPIN_SALT_2025';
  
  /// Encrypt MPIN using SHA-256 with salt
  static String encryptMPIN(String mpin) {
    try {
      // Combine MPIN with salt
      final saltedMpin = mpin + _mpinSalt;
      
      // Convert to bytes
      final bytes = utf8.encode(saltedMpin);
      
      // Hash using SHA-256
      final digest = sha256.convert(bytes);
      
      // Return hex string
      final encryptedMpin = digest.toString();
      
      print('🔐 EncryptionService: MPIN encrypted successfully');
      return encryptedMpin;
    } catch (e) {
      print('❌ EncryptionService: MPIN encryption failed: $e');
      throw Exception('Failed to encrypt MPIN: $e');
    }
  }
  
  /// Verify MPIN by comparing hashes
  static bool verifyMPIN(String enteredMpin, String storedEncryptedMpin) {
    try {
      // Encrypt the entered MPIN
      final encryptedEnteredMpin = encryptMPIN(enteredMpin);
      
      // Compare with stored encrypted MPIN
      final isValid = encryptedEnteredMpin == storedEncryptedMpin;
      
      print('🔐 EncryptionService: MPIN verification ${isValid ? 'successful' : 'failed'}');
      return isValid;
    } catch (e) {
      print('❌ EncryptionService: MPIN verification error: $e');
      return false;
    }
  }
  
  /// Generate a secure random salt (for future use)
  static String generateSalt({int length = 32}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }
  
  /// Hash any string with SHA-256
  static String hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Encrypt sensitive data (for future use)
  static String encryptSensitiveData(String data, String salt) {
    final saltedData = data + salt;
    final bytes = utf8.encode(saltedData);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
