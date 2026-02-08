import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class EncryptionService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _keyName = 'hiveKey';

  /// Returns the encryption key for Hive.
  /// Generates a new one if it doesn't exist.
  static Future<Uint8List> getHiveKey() async {
    // 1. Check if key exists
    String? keyString = await _secureStorage.read(key: _keyName);

    if (keyString == null) {
      // 2. Generate new key (32 bytes = 256 bits)
      final List<int> key = Hive.generateSecureKey();
      // 3. Store as base64 string
      keyString = base64UrlEncode(key);
      await _secureStorage.write(key: _keyName, value: keyString);
    }

    // 4. Return as Uint8List
    return base64Url.decode(keyString);
  }

  /// Initialize Hive with Encryption
  static Future<void> initSecureHive() async {
    await Hive.initFlutter();

    final encryptionKey = await getHiveKey();

    // Open boxes with encryption
    // Note: If you have EXISTING UNENCRYPTED data, this will crash.
    // For MVP/Phase 3, we assume clean slate or overwrite.
    try {
      await Hive.openBox('chatHistory',
          encryptionCipher: HiveAesCipher(encryptionKey));
      await Hive.openBox('moodHistory',
          encryptionCipher: HiveAesCipher(encryptionKey));
      await Hive.openBox('sessions',
          encryptionCipher:
              HiveAesCipher(encryptionKey)); // New for Multi-Session
    } catch (e) {
      // Recovery: If key mismatch (dev mode), delete and recreate
      print('Encryption Error (Likely Migration): $e');
      print('Deleting old boxes...');
      await Hive.deleteBoxFromDisk('chatHistory');
      await Hive.deleteBoxFromDisk('moodHistory');
      await Hive.deleteBoxFromDisk('sessions');

      // Retry
      await Hive.openBox('chatHistory',
          encryptionCipher: HiveAesCipher(encryptionKey));
      await Hive.openBox('moodHistory',
          encryptionCipher: HiveAesCipher(encryptionKey));
      await Hive.openBox('sessions',
          encryptionCipher: HiveAesCipher(encryptionKey));
    }
  }
}
