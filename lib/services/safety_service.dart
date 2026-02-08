import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SafetyService {
  // Keywords that might indicate a crisis
  static final List<String> _crisisKeywords = [
    'bunuh diri',
    'ingin mati',
    'akhiri hidup',
    'suicide',
    'kill myself',
    'die',
    'gak kuat hidup',
    'mau mati',
  ];

  /// Checks if the input contains any crisis keywords.
  static bool isCrisis(String input) {
    final lowerInput = input.toLowerCase();
    for (final keyword in _crisisKeywords) {
      if (lowerInput.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  /// Returns a safe, supportive message and offering help.
  static String getSafetyResponse() {
    return "Bro, gw denger lo lgi berat banget. Tapi please, jangan lakuin hal nekat. \n\n"
        "Lo gak sendirian. Ada orang yang peduli dan siap bantu lo sekarang juga. \n\n"
        "Hubungi **Lisle (119)** atau **Sehat Jiwa (119 ext 8)**. Mereka profesional dan gratis. \n\n"
        "Gw di sini buat nemenin lo, tapi mereka bisa bantuin lo lebih jauh. Please call them. ❤️";
  }

  /// Launches the hotline number.
  static Future<void> launchHotline() async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: '119',
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
}
