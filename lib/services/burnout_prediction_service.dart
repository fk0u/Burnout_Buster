import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'digital_wellbeing_service.dart';
// import 'ai_service.dart'; // Future integration

enum BurnoutRisk { low, medium, high, critical }

class BurnoutPredictionService extends ChangeNotifier {
  BurnoutRisk _risk = BurnoutRisk.low;
  String _advice = "Keep vibing. You're doing great. ✨";
  bool _isLoading = false;

  BurnoutRisk get risk => _risk;
  String get advice => _advice;
  bool get isLoading => _isLoading;

  Future<void> analyzeBurnout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Get Mood Data (Last 7 days)
      final moodBox = Hive.box('moodHistory');
      final now = DateTime.now();
      int totalMood = 0;
      int moodCount = 0;

      for (int i = 0; i < 7; i++) {
        final d = now.subtract(Duration(days: i));
        final key = DateFormat('yyyy-MM-dd').format(d);
        if (moodBox.containsKey(key)) {
          totalMood += (moodBox.get(key) as int);
          moodCount++;
        }
      }

      double avgMood =
          moodCount > 0 ? totalMood / moodCount : 3.0; // Default to neutral

      // 2. Get Usage Stats (Today)
      // Check permission first
      bool hasPerm = await DigitalWellbeingService.hasPermission();
      double hoursUsed = 0.0;

      if (hasPerm) {
        final stats = await DigitalWellbeingService.getUsageStats();
        // Sum top 5 apps usage
        for (var app in stats.take(5)) {
          // totalTime is in millis
          hoursUsed += (app['totalTime'] as int? ?? 0) / (1000 * 60 * 60);
        }
      }

      // 3. Calculate Risk
      if (hoursUsed > 6.0 || avgMood < 2.0) {
        _risk = BurnoutRisk.critical;
        _advice = "RED ALERT! 🚨 Touch Grass immediately or you will crash.";
      } else if (hoursUsed > 4.0 || avgMood < 3.0) {
        _risk = BurnoutRisk.high;
        _advice = "Whoa, slowing down wouldn't hurt. Consider a detox.";
      } else if (hoursUsed > 2.0 || avgMood < 4.0) {
        _risk = BurnoutRisk.medium;
        _advice = "You're okay, but keep an eye on that screen time.";
      } else {
        _risk = BurnoutRisk.low;
        _advice = "Smooth sailing. Keep vibing! 🌊";
      }
    } catch (e) {
      if (kDebugMode) print("Burnout Analysis Error: $e");
      _advice = "My crystal ball is foggy. Try again later.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 4. Chat Sentiment Impact
  int _stressChatCount = 0;

  void logChatSentiment(String sentiment) {
    if (sentiment == 'stress') {
      _stressChatCount++;
      // If user vents about stress frequently, increase risk immediately
      if (_stressChatCount > 2 && _risk.index < 2) {
        _risk = BurnoutRisk.high;
        _advice =
            "Lo sering banget bilang stress. Jangan dipendam sendiri, istirahat yuk.";
        notifyListeners();
      }
    } else if (sentiment == 'happy') {
      // Positive reframing
      if (_stressChatCount > 0) _stressChatCount--;
    }
  }

  // .. existing analyzeBurnout code ..
}
