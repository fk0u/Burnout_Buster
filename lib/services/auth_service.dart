import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _pinKey = 'user_pin';

  /// Sets the user's PIN.
  static Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  /// Verifies if the entered PIN matches the stored PIN.
  static Future<bool> verifyPin(String enteredPin) async {
    final storedPin = await _storage.read(key: _pinKey);
    return storedPin == enteredPin;
  }

  /// Checks if a PIN has been set.
  static Future<bool> isPinSet() async {
    final pin = await _storage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  /// Clears the PIN (e.g. on logout/reset).
  static Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
  }
}
