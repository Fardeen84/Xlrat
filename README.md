# xlrat

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Development Setup

To run or build the app, compile-time environment variables for Firebase configuration must be supplied.

### Option 1: Using `env.json` (Recommended)
1. Copy the template `env.json.example` to `env.json`:
   ```bash
   cp env.json.example env.json
   ```
2. Open `env.json` and fill in your actual Firebase API key and project ID. Note that `env.json` is ignored by git and must not be committed.
3. Run the app using:
   ```bash
   flutter run --dart-define-from-file=env.json
   ```

   *Note: Using `--dart-define-from-file=env.json` is optional since `env.json` is also bundled into the app assets as a fallback. You can now also run or debug the app directly (e.g. via the IDE's Run button).*

### Option 2: Using command-line flags
Alternatively, you can pass these parameters directly to the run/build commands:
```bash
flutter run --dart-define=FIREBASE_API_KEY=xxxx --dart-define=FIREBASE_PROJECT_ID=xxxx
```
