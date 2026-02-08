import 'package:flutter_test/flutter_test.dart';
import 'package:burnout_buster/services/burnout_prediction_service.dart';

void main() {
  group('BurnoutPredictionService Tests', () {
    late BurnoutPredictionService service;

    setUp(() {
      service = BurnoutPredictionService();
    });

    test('Initial risk should be low', () {
      expect(service.risk, BurnoutRisk.low);
    });

    test('logChatSentiment with stress should increase stress count', () {
      // 1. Send first stress message
      service.logChatSentiment('stress');
      // Risk shouldn't change yet (threshold > 2)
      expect(service.risk, BurnoutRisk.low);

      // 2. Send second stress message
      service.logChatSentiment('stress');
      expect(service.risk, BurnoutRisk.low);

      // 3. Send third stress message -> Should trigger High Risk
      service.logChatSentiment('stress');

      // Wait for notifyListeners? It's synchronous.
      // Logic: if (_stressChatCount > 2 && _risk.index < 2)
      expect(service.risk, BurnoutRisk.high);
      expect(service.advice, contains('Lo sering banget bilang stress'));
    });

    test('logChatSentiment with happy should decrease stress count', () {
      // Increase stress first
      service.logChatSentiment('stress'); // count = 1
      service.logChatSentiment('stress'); // count = 2

      // Decrease
      service.logChatSentiment('happy'); // count = 1

      // Now if we add 1 more stress, it should be 2, not 3.
      service.logChatSentiment('stress'); // count = 2
      expect(service.risk, BurnoutRisk.low); // Still low

      // Add another to trigger
      service.logChatSentiment('stress'); // count = 3
      expect(service.risk, BurnoutRisk.high);
    });
  });
}
