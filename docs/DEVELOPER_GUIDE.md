# Burnout Buster - Developer Guide 🛠️

Technical documentation for maintainers and contributors of Burnout Buster V2.0.

---

## 📂 Project Structure

```
lib/
├── main.dart                  # App Entry Point & Provider Setup
├── api_key.dart               # API Configuration (GitIgnored)
├── screens/                   # UI Layer
│   ├── dashboard_screen.dart  # Home: Battery, Radar, Quick Actions
│   ├── chat_screen.dart       # AI Chat Interface
│   ├── zen_mode_screen.dart   # Focus Timer & Gamification
│   └── ...
├── services/                  # Business Logic & State Management
│   ├── ai_service.dart        # Gemini API & Offline Fallback
│   ├── burnout_prediction_service.dart # Risk Analysis Logic
│   ├── energy_service.dart    # Battery Drain/Recharge Logic
│   └── ml/                    # Machine Learning (Naive Bayes)
└── widgets/                   # Reusable UI Components
```

---

## 🚀 Setup & Installation

1. **Prerequisites**: 
   - Flutter SDK (>=3.2.0)
   - Android Studio / VS Code
   - Java 11/17 (for Gradle)

2. **Clone & Install**:
   ```bash
   git clone <repo_url>
   flutter pub get
   ```

3. **API Configuration**:
   Create `lib/api_key.dart`:
   ```dart
   // lib/api_key.dart
   const String geminiApiKey = "YOUR_API_KEY_HERE";
   ```

4. **Run Debug**:
   ```bash
   flutter run
   ```

---

## 🧠 Core Services

### 1. Burnout Prediction (`BurnoutPredictionService`)
- **Key Logic**: Combines `DigitalWellbeingService` (Screen Time) and generic Mood History to calculate a `BurnoutRisk` enum.
- **Inputs**: 
  - `logChatSentiment(intent)`: Updates risk based on 'stress'/'happy' chat intents.
  - `analyzeBurnout()`: Triggers analysis.

### 2. Offline AI (`NaiveBayesClassifier`)
- **Location**: `lib/services/ml/`
- **Implementation**: Pure Dart implementation of Naive Bayes.
- **Training**: Uses a hardcoded dataset in `training_data.dart` (Indonesian mental health phrases).
- **Usage**: Automatically triggered by `AIService` when the device is offline or API fails.

### 3. Energy System (`EnergyService`)
- **Persistence**: Uses `SharedPreferences` to track energy level and last updated timestamp.
- **logic**: Passive drain based on time elapsed since last open.

---

## 🧪 Testing

We use `flutter_test` for unit testing core logic.

**Run All Tests**:
```bash
flutter test
```

**Key Test Files**:
- `test/services/ml/naive_bayes_classifier_test.dart`: Validates ML intent detection.
- `test/services/burnout_prediction_service_test.dart`: Verifies risk calculation.
- `test/services/energy_service_test.dart`: Checks battery logic.

---

## 📦 Building for Release

1. **Update Icons** (Optional):
   ```bash
   flutter pub run flutter_launcher_icons
   ```

2. **Build APK**:
   ```bash
   flutter build apk --release
   ```
   Output: `build/app/outputs/flutter-apk/app-release.apk`

3. **Proguard**:
   Rules are configured in `android/app/proguard-rules.pro` to keep specific classes (like Hive adapters) from being obfuscated.

---

## 🤝 Contribution Guidelines
- Use **Conventional Commits** (e.g., `feat: add zen mode`, `fix: battery drain bug`).
- Always run tests before pushing.
- Formatter: `dart format .`
