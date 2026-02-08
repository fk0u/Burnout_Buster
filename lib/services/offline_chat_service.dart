import 'dart:math';
import 'ml/naive_bayes_classifier.dart';
import 'ml/training_data.dart';

class OfflineChatService {
  static final NaiveBayesClassifier _classifier = NaiveBayesClassifier();
  static bool _isTrained = false;

  static void _ensureTrained() {
    if (!_isTrained) {
      _classifier.train(trainingData);
      _isTrained = true;
    }
  }

  static final Map<String, List<String>> _responses = {
    'stress': [
      "Wah, kedengerannya heavy banget. Coba tarik napas dulu 5 detik... buang pelan-pelan.",
      "Istirahat dulu bentar, dunia gak bakal kiamat kok kalau lo rebahan 5 menit.",
      "Capek fisik apa capek hati nih? Dua-duanya butuh validasi sih.",
      "Duh, berat banget ya beban lo. Coba breakdown satu-satu yuk biar gak overload.",
    ],
    'sad': [
      "Nangis aja kalau perlu, jangan ditahan. Gue temenin di sini.",
      "Sending virtual hug 🫂. Lo gak sendirian ya.",
      "Gapapa buat ngerasa gak oke hari ini. Besok kita coba lagi.",
      "Gue ngerti rasanya hampa. Sini cerita lagi.",
    ],
    'happy': [
      "Wih mantap! Ikut seneng gue dengernya! 🎉",
      "Gas terusss! Energi positif nih.",
      "Nah gitu dong, senyum lo mahal harganya.",
      "Keren! Pertahanin mood bagus ini ya.",
    ],
    'neutral': [
      "Gue dengerin kok. Cerita aja terus.",
      "Hmm, terus gimana?",
      "Iya, gue ngerti rasanya.",
      "Ada lagi yang mau diceritain?",
      "Sip, gue di sini.",
    ],
  };

  static Map<String, String> generateResponseWithIntent(String input) {
    _ensureTrained();

    // Predict intent
    final predictedLabel = _classifier.predict(input);

    final possibleResponses =
        _responses[predictedLabel] ?? _responses['neutral']!;
    final responseText =
        possibleResponses[Random().nextInt(possibleResponses.length)];

    return {
      'text': responseText,
      'intent': predictedLabel,
    };
  }

  // Keep old method for backward compatibility if needed, mimicking old signature
  static String generateResponse(String input) {
    return generateResponseWithIntent(input)['text']!;
  }
}
