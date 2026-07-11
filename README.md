# MedGate

MedGate is a Flutter starter app for a secure, glassy medical data transmission experience. The current build focuses on a clean foundation with routing, theming, reusable shell widgets, and feature folders so future business logic can be added in a structured way.

## Setup

1. Install Flutter and ensure the SDK is available on your PATH.
2. Run `flutter pub get` in the project root.
3. Launch the app with `flutter run`.

## Project structure

- core contains shared theming, routing, widgets, and constants.
- features holds feature-first modules for auth, onboarding, home, NFC capture, transmission, specialist review, and settings.
- The app entry point lives in lib/main.dart and the root app shell in lib/app.dart.
