# Namma MedGate

Namma MedGate is an Android-first Flutter prototype for contactless patient intake and protected transmission workflows. The app is designed to demonstrate a realistic clinical handoff experience from intake to specialist review, with a polished glass UI, an NFC-friendly workflow, and a simulated network layer that makes reliability and recovery behavior visible.

## What this app is trying to show

MedGate is not a finished medical product. It is a proof-of-concept experience for:
- contactless patient intake on Android devices
- protected payload packaging and chunked transmission
- recovery behavior when packets are disrupted or partially lost
- a specialist-side review flow that shows what was reconstructed and what changed

## Current features

### Core experience
- Local registration and sign-in flow
- Onboarding and route-based navigation
- A glass-style dashboard shell for patient overview and workflow status
- NFC capture with manual fallback entry when NFC is unavailable
- Patient data editing, validation, and optional tag writing for supported devices
- Local SQLite persistence via sqflite for patient records, including the last successfully transmitted baseline used for delta comparison

### Transmission and recovery demo
- Real DEFLATE/gzip compression applied before encryption so payloads shrink before they leave the device
- The transport pipeline is raw payload -> positional field/tuple encoding -> max-level gzip/DEFLATE -> encryption -> redundancy chunks -> network chunking, with raw, encoded, compressed, and final on-wire byte counts shown in the integrity log
- Delta-based payload preparation so only changed fields are emphasized when possible; the implementation uses field-level hashing against the last successfully transmitted local database record, not just the last locally edited value
- Encrypted payload packaging and chunked transmission simulation
- Simplified XOR-based parity recovery that is conceptually similar to RAID 5 parity; it can reconstruct a single lost chunk per group from the remaining members of that group, and it fails honestly when loss exceeds that group capacity
- MedGate's Recovery Confidence score reflects genuine mathematical recovery limits, the same way QR codes fail to scan when damage exceeds their designed error-correction threshold. This transparency is intentional, so severe packet loss can produce partial recovery or failure.
- Adaptive clinical priority ordering so critical vital data is transmitted first
- Progressive specialist review that unlocks sections as data becomes available
- Store-and-forward queueing with retry handling for later delivery attempts
- Urgent Case mode that visibly accelerates fallback behavior and preserves a tiny thumbnail in fallback mode
- Adaptive network profiles for ultra-low, low, medium, and high-bandwidth conditions
- Live transmission budget, packet-loss, recovery, delivery-time, and compression-size feedback in the simulator
- Specialist review view with rebuilt data, changed-field highlighting, checksum context, and transmission proof

### Recent protocol enhancements
- The transmission engine now behaves like a protocol-centric experience under the MedGate Protocol (MGP) concept
- Priority badges highlight which fields are critical, high, medium, or low importance
- Local validation warns on clinically implausible values without using any cloud service
- Transmission state now tracks missing chunks, retransmission activity, and recovery progress
- The network simulator exposes active strategy, chunk size, compression level, redundancy, and parity settings
- The redundancy control is a live tradeoff: higher parity survives more random loss but increases final on-wire bytes; lower parity keeps transmissions smaller but fails sooner as loss increases
- **Reed-Solomon Image Tier Recovery**: The same XOR/Reed-Solomon erasure coding pipeline used for clinical vitals delta is applied to image tile payloads, enabling photos to survive network losses.
- **Image Recovery Visual Demo**: Specialist console renders side-by-side or toggled visual comparisons of naive uncorrected transmissions (corrupted/missing tile blocks) vs rebuilt error-corrected outputs, displaying real-time loss and recovery statistics.
- **Clinical Alert System**: Glass-style persistable banner notifications and transient SnackBar toast overlays mapped directly to real events (critical rebuild failure, degraded channel, satellite/cellular fallback activation, NFC hardware warning, implausible vital entry).

### Platform and UX polish
- Android-focused UX patterns and NFC guidance
- Local theme persistence
- Lightweight animation and glass-style visual language

## What is dummy or demo-only

The following parts are intentionally simplified for demonstration purposes:
- Authentication is local-only and not connected to a real identity provider
- Patient data is persisted locally in SQLite for demo-grade store-and-forward behavior; it is not a production clinical database
- NFC scanning is real when supported by the device, but it falls back gracefully when unavailable or blocked
- The transport path is a strong prototype, not a production-grade medical transport system
- The app is designed to demonstrate workflow credibility, not to satisfy full HIPAA, medical-device, or regulated clinical deployment requirements

## User flow

1. A clinician signs in and arrives on the dashboard.
2. They open the intake flow and begin a contactless NFC capture session.
3. If the device supports NFC and a tag is available, MedGate captures and validates the patient details.
4. If NFC is unavailable, the app offers a manual fallback path so the flow still continues.
5. The patient payload is packaged, encrypted, chunked, and passed through a simulated network layer.
6. The specialist console progressively unlocks sections as the record rebuilds and displays the rebuilt payload, changed fields, recovery behavior, and the transmission evidence.

## Tech stack

- Flutter and Dart for the app UI, navigation, and state flow
- Riverpod for state management
- Go Router for navigation
- NFC Manager for contactless capture on supported devices
- Shared Preferences for local persistence
- sqflite for local patient-record storage and durable delta baselines
- Flutter Animate for light motion polish
- Optional Rust native acceleration for the chunking hot path

## Why these choices

MedGate uses established open-source building blocks rather than inventing every transport primitive from scratch. The current stack credits:
- archive for DEFLATE/gzip compression
- crypto for field-level hashing and integrity checks
- encrypt for payload encryption
- flutter_image_compress for image-side compression concepts in the broader demo story

That is a credibility strength: the app is demonstrating how familiar, well-understood algorithms can be composed into a believable clinical handoff experience rather than pretending to have built an entirely novel transport stack.

## Why Rust was added

Rust is used for the chunking path because that part of the app is CPU-bound, repetitive, and byte-oriented. The transmission engine repeatedly processes strings and byte payloads, which makes it a good candidate for a native acceleration layer.

Rust is better than Flutter/Dart for this specific use case because:
- it is very fast for deterministic, low-level byte processing
- it can avoid some of the overhead and GC-related variability that shows up in repeated string and buffer work
- it gives precise control over memory and encoding operations
- it can be called from Flutter through FFI when the hot path needs a performance boost

That said, the app is still designed to work without Rust installed. The Dart implementation remains the fallback, so the experience is reliable even on a machine that does not have the Rust toolchain available.

## Android-first notes

- The experience is optimized for Android devices and NFC-enabled hardware.
- Physical-device testing is recommended for NFC behavior.
- The app should be run on a real Android phone for the most accurate experience.

## Setup

1. Install Flutter and ensure the SDK is available on your PATH.
2. Run `flutter pub get` in the project root.
3. Launch the app with `flutter run`.
4. For NFC testing, use a physical Android device and enable NFC in the device settings.

## Optional Rust setup

If you want to enable the native acceleration path:
1. Install Rust from https://www.rust-lang.org/
2. Build the native library from the native/cih_chunk_engine folder with `cargo build --release`
3. Ensure the resulting shared library is available in the expected target/release output path for your platform

If Rust is not available, the app will continue to use the Dart fallback implementation automatically.

## Testing

- Unit tests cover chunking, payload recovery, delta handling, and transmission-flow behavior.
- Run `flutter test` to execute the regression suite.
