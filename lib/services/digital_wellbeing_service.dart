import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class DigitalWellbeingService {
  static const MethodChannel _channel = MethodChannel(
    'com.burnoutbuster/digital_wellbeing',
  );

  static Future<void> requestPermission() async {
    // Return early if on Web
    if (kIsWeb) return;

    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('requestPermission');
      } on PlatformException catch (e) {
        print("Failed to request permission: '${e.message}'.");
      }
    }
  }

  static Future<bool> hasPermission() async {
    if (kIsWeb) return true;
    if (Platform.isAndroid) {
      try {
        final bool result = await _channel.invokeMethod('hasPermission');
        return result;
      } on PlatformException catch (e) {
        print("Failed to check permission: '${e.message}'.");
        return false;
      }
    }
    return true; // Default to true on other platforms
  }

  static Future<List<Map<String, dynamic>>> getUsageStats() async {
    // Return mock data for Web
    if (kIsWeb) {
      return [
        {'packageName': 'Web Demo', 'totalTime': 1000 * 60 * 30},
      ];
    }

    if (Platform.isAndroid) {
      try {
        final List<dynamic> result = await _channel.invokeMethod(
          'getUsageStats',
        );
        return result.cast<Map<String, dynamic>>();
      } on PlatformException catch (e) {
        print("Failed to get usage stats: '${e.message}'.");
        return [];
      }
    }
    // Mock data for iOS/Error
    return [
      {
        'packageName': 'com.tiktok.android',
        'totalTime': 1000 * 60 * 60 * 2,
      }, // 2 hours
      {'packageName': 'instagram', 'totalTime': 1000 * 60 * 45}, // 45 mins
    ];
  }
}
