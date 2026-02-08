# Burnout Buster

App curhat digital & mental health tracker buat Gen Z.

## Getting Started

1.  **Initialize Project** (If not already done):
    ```bash
    flutter create --org com.burnoutbuster .
    ```
    *Note: If asked to overwrite, choose 'no' or backup your `lib/` folder first. ideally run this on empty folder before copying files, but currently files are already here.*
    *Better approach:* Run `flutter create` *first*, then these files are placed. Since files are already here, run:
    ```bash
    flutter create --org com.burnoutbuster --project-name burnout_buster .
    ```

2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run App**:
    ```bash
    flutter run
    ```

## Project Structure
- `lib/screens`: UI Screens (Chat, Mood, Healing, Onboarding).
- `lib/services`: Logic (AI, Digital Wellbeing).
- `android/`: Native Kotlin code for Usage Stats.
- `ios/`: Native Swift code for Screen Time Auth.

## AI Configuration
Check `lib/api_key.dart` to configure your Gemini API Key.
