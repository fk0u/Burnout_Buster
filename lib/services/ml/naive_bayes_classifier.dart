import 'dart:math';

class NaiveBayesClassifier {
  // Map<Label, Count>
  final Map<String, int> _classCounts = {};
  // Map<Word, Map<Label, Count>>
  final Map<String, Map<String, int>> _wordCounts = {};
  // Map<Label, TotalWordsInClass>
  final Map<String, int> _classWordCounts = {};
  // Vocabulary size
  final Set<String> _vocab = {};

  int _totalDocs = 0;

  void train(List<Map<String, String>> dataset) {
    for (var doc in dataset) {
      final text = doc['text']!;
      final label = doc['label']!;
      _trainDoc(text, label);
    }
  }

  void _trainDoc(String text, String label) {
    _totalDocs++;
    _classCounts[label] = (_classCounts[label] ?? 0) + 1;

    final words = _tokenize(text);
    for (var word in words) {
      _vocab.add(word);

      // Update word counts per class
      if (!_wordCounts.containsKey(word)) {
        _wordCounts[word] = {};
      }
      _wordCounts[word]![label] = (_wordCounts[word]![label] ?? 0) + 1;

      // Update total words in class
      _classWordCounts[label] = (_classWordCounts[label] ?? 0) + 1;
    }
  }

  String predict(String text) {
    final words = _tokenize(text);
    double maxProb = -double.infinity;
    String bestClass = "neutral";

    for (var label in _classCounts.keys) {
      // P(Class)
      double logProb = _calculateClassProb(label);

      // P(Word | Class)
      for (var word in words) {
        logProb += _calculateWordProb(word, label);
      }

      if (logProb > maxProb) {
        maxProb = logProb;
        bestClass = label;
      }
    }

    return bestClass;
  }

  double _calculateClassProb(String label) {
    return log((_classCounts[label] ?? 0) / _totalDocs);
  }

  double _calculateWordProb(String word, String label) {
    // Laplace Smoothing
    final wordCount = _wordCounts[word]?[label] ?? 0;
    final int classWordCount = _classWordCounts[label] ?? 0;

    // P(w|c) = (count(w,c) + 1) / (count(c) + vocab_size)
    return log((wordCount + 1) / (classWordCount + _vocab.length));
  }

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .split(RegExp(r'\s+')) // Split by whitespace
        .where((w) => w.isNotEmpty && w.length > 2) // Filter short words
        .toList();
  }
}
