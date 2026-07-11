# MedGate

MedGate is a Flutter-based clinical communications prototype for secure, contactless patient intake and protected transmission workflows. The app combines a glassy UI, Riverpod-based state management, NFC capture logic, a simulated network layer, and a specialist review experience so the full handoff path can be demonstrated end to end.

## Current status

### What is complete
- Authentication flow with local registration and sign-in
- Onboarding and route-based navigation with Go Router
- Glass-style dashboard shell and reusable UI widgets
- NFC capture, manual fallback entry, patient-card writing, and permission-aware guidance
- A real transmission engine with delta encoding, priority ordering, encrypted payload packaging, and parity-style chunk recovery
- A network simulator with Resilience Score, Integrity Log, and Compare Mode
- A specialist console that shows a proof-oriented receipt of rebuilt data and changed fields
- Local persistence for theme preferences

### What is still a prototype / demo-oriented
- NFC scanning is wired for real device testing, but the app still gracefully falls back when NFC is unavailable, disabled, or blocked by device permissions
- The transport path is a strong demo prototype rather than a production-grade medical transport system
- Patient data is still managed in app state and is not yet backed by a real clinical database or authentication service
- The app is designed to demonstrate workflow and credibility rather than satisfy full HIPAA or medical-device compliance requirements

## Feature overview

### 1. Authentication and onboarding
- Users can register or sign in locally.
- The router protects the main app experience until authentication succeeds.
- The onboarding screen introduces the clinical workflow and sets up the mental model for the app.

### 2. Home dashboard
- The home view offers a patient overview, transmission status, triage insight, and recent activity.
- It shows how the intake process connects to the specialist review experience.

### 3. NFC capture
- The NFC screen supports a guided scan experience with an animated popup while a session is active.
- If NFC is unavailable, the app shows a permission-aware guidance state and allows manual entry instead of failing silently.
- Patient details can be edited after capture, written to a writable NFC tag, and validated before sending.

### 4. Protected transmission flow
- Patient updates are transformed into a protected payload and chunked for preview.
- The app uses delta encoding so only changed fields are sent when possible.
- Reliability and latency changes directly affect survival and rebuild outcomes.
- Resilience Score, Integrity Log, and Compare Mode show MedGate recovery beside a naive full-payload resend.
- The doctor side can review rebuilt records, changed fields, capture source, checksum state, and the encrypted payload preview.

### 5. Specialist console
- The specialist screen surfaces the reconstructed patient payload, network quality, triage recommendation, and transmission outcome.

## Tech stack
- Flutter 3.x
- Dart SDK 3.11+
- Riverpod for state management
- Go Router for navigation
- NFC Manager for contactless scanning
- Google Fonts for polished typography
- Shared Preferences for local theme persistence
- Flutter Animate for lightweight motion polish
- Lucide Icons for the app shell and action icons

## Project structure
- lib/app.dart: app shell and router bootstrap
- lib/main.dart: app entry point and provider scope setup
- lib/core: shared routing, theming, widget primitives, and glass-style UI assets
- lib/features/auth: login, register, and authentication state
- lib/features/home: dashboard experience
- lib/features/nfc_capture: NFC intake flow, provider state, and scan guidance
- lib/features/network_simulator: reliability and latency simulation
- lib/features/transmission_engine: chunking and protected transmission logic
- lib/features/specialist_view: doctor-facing review console
- lib/features/settings: user-facing preferences

## How the flow works
1. A clinician signs in and lands on the dashboard.
2. They tap the NFC intake flow and begin a contactless scan.
3. If an NFC tag is available, the app captures and validates patient details.
4. If scanning is unavailable, the app offers an accessible manual fallback path.
5. The intake data is packaged, encrypted, chunked, and sent through a simulated network channel.
6. The specialist console then shows a receipt-style proof of what was reconstructed and which fields changed.

## Setup
1. Install Flutter and ensure the SDK is available on your PATH.
2. Run `flutter pub get` in the project root.
3. Launch the app with `flutter run`.
4. For NFC testing, use a physical device and enable NFC in the device settings.

## Testing
- Unit tests cover the transmission engine, including chunk recovery, delta encoding, and secure packaging.
- Run `flutter test` to execute the regression suite.
