# Appendix

**An offline-first English writing assistant for Windows and macOS, with native mobile keyboards for Android and iOS.**

[![CI](https://github.com/tracolerd/appendix/actions/workflows/ci.yml/badge.svg?branch=feat/local-ai-inference)](https://github.com/tracolerd/appendix/actions/workflows/ci.yml?query=branch%3Afeat%2Flocal-ai-inference)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache--2.0-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.50.0-02569B.svg)](https://flutter.dev/)
[![Core](https://img.shields.io/badge/Core-Rust-orange.svg)](https://www.rust-lang.org/)

Appendix is a local writing workspace built with Flutter and a Rust language engine. It combines grammar and spelling checks, writing insights, draft history, optional local-model rewriting, and mobile system keyboards. It is an independent open-source project and is not affiliated with Grammarly or QuillBot.

> **Early testing release.** The desktop and Android packages are intended for hands-on evaluation. Read each platform's signing notes before installing.

---

## Download Appendix

These are direct links to the latest GitHub Release assets.

| Platform | Direct download | Package |
|---|---|---|
| **Windows 10/11 (x64)** | [Download Appendix for Windows](https://github.com/tracolerd/appendix/releases/latest/download/appendix-windows-x64.zip) | Portable ZIP with Flutter desktop app and Rust DLL |
| **macOS (Universal)** | [Download Appendix for macOS](https://github.com/tracolerd/appendix/releases/latest/download/appendix-macos.zip) | App ZIP for Apple Silicon and Intel Macs |
| **Android (64-bit)** | [Download Appendix APK](https://github.com/tracolerd/appendix/releases/latest/download/appendix-android.apk) | Debug-signed APK for sideloading and evaluation |
| Android developers | [Download Android App Bundle](https://github.com/tracolerd/appendix/releases/latest/download/appendix-android.aab) | Debug-signed AAB for internal evaluation; not Play Store ready |

The direct download URLs resolve after a tagged GitHub Release has published its assets. Until then, check the [Releases page](https://github.com/tracolerd/appendix/releases) for availability.

**Checksums:** [SHA256SUMS.txt](https://github.com/tracolerd/appendix/releases/latest/download/SHA256SUMS.txt) contains SHA-256 hashes for the release packages. Verify a downloaded file before installing it.

**All releases:** [GitHub Releases](https://github.com/tracolerd/appendix/releases)

### Installation guides

- [Windows installation](INSTALL_WINDOWS.md)
- [macOS installation](INSTALL_MACOS.md)
- [Android installation and keyboard activation](INSTALL_ANDROID.md)
- [iOS developer build and simulator status](INSTALL_IOS.md)

### Signing and distribution notes

- **Windows:** The portable package is not code-signed. Windows SmartScreen may show an unknown-publisher warning.
- **macOS:** The app is not Developer ID signed or notarized. Gatekeeper may require the user to approve opening it.
- **Android:** The APK is debug-signed for sideloading and device testing. It is **not** a production Play Store release. An update signed with a different debug key may require uninstalling the earlier build first.
- **iOS:** The repository includes the iOS app and Swift keyboard-extension source. The app and keyboard were built and manually exercised in an iOS Simulator. Physical-device signing, provisioning, a signed IPA, App Store archive, review, and publication have **not** been completed. There is no iOS App Store download in this release.

---

## What Appendix does

### Grammar and spelling

- Rust-based grammar and spelling engine using Harper Core.
- American English and British English dialect selection.
- Native C ABI used by the Flutter app, with JNI for Android and a Swift bridge for the iOS keyboard.

### Writing insights

- Flesch Reading Ease and Flesch-Kincaid grade-level estimates.
- Vocabulary-diversity and repeated-word indicators.
- Sentence-length and readability feedback.

These are writing aids and estimates, not professional editorial or academic assessments.

### Rewriting and local AI

- Multiple rewrite styles are available in the app.
- Built-in heuristic rewriting works locally.
- Optional Qwen 2.5 0.5B Instruct GGUF inference can be enabled by importing the model. The model is not bundled in the app packages and must be obtained separately.
- If the optional model is not installed or initialized, model-powered rewriting is unavailable; heuristic options remain available.

[Model manifest and download details](models/model_manifest.json)

### Mobile keyboards

- **Android:** Native Kotlin InputMethodService keyboard with the Rust engine bridged through JNI.
- **iOS:** Native Swift keyboard extension. Its current configuration sets RequestsOpenAccess to false. The keyboard has been tested in the iOS Simulator, not on a provisioned physical iPhone.

---

## Platform status

| Platform | Source | Build and test evidence | Distribution status |
|---|---|---|---|
| Windows | Flutter desktop + Rust DLL | Windows build is defined in the release workflow; verify the current Release asset before installing | Portable ZIP, unsigned |
| macOS | Flutter desktop + universal Rust dylib | Release app built and launched on an Apple Silicon Mac; grammar-check smoke test passed | Universal ZIP, not notarized |
| Android | Flutter app + Rust JNI libraries + Kotlin keyboard | Android build validation is part of CI; release APK uses debug signing | APK sideload only |
| iOS | Flutter app + XCFramework + Swift keyboard | Simulator build and manual keyboard test passed | No public IPA; device signing and App Store work pending |

The iOS source is present and simulator-tested, but it is inaccurate to describe it as App Store-ready. Physical-device signing, provisioning, device validation, archive generation, App Store review, and release remain separate tasks.

---

## Privacy and offline design

Appendix is designed to process writing locally and does not require an account or a hosted writing service for its core workflows. The grammar engine, writing insights, SQLite draft history, heuristic rewriting, and optional imported-model inference run on the device.

Platform-level implementation details:

- **Android:** The app manifest does not declare the Android INTERNET permission. It declares vibration permission for haptics and the OS-protected input-method service.
- **iOS keyboard:** The extension plist sets RequestsOpenAccess to false. This is a property of the keyboard extension, not proof that every possible host-app behavior has been independently security-tested.
- **macOS:** The release entitlement enables App Sandbox and does not include the network-client entitlement.
- **Local model:** Model weights are obtained separately by the user and stored locally; they are not included in the platform installers.

See [Privacy implementation notes](PRIVACY_AUDIT.md). This is a project-level source and configuration review, not an independent penetration test or third-party certification.

---

## Technology

| Layer | Technology |
|---|---|
| Application UI | Flutter 3.50 / Dart |
| Core engine | Rust |
| Grammar and spelling | Harper Core |
| Native integration | Dart FFI, Android JNI, Swift C bridge |
| Local storage | SQLite |
| Android keyboard | Kotlin InputMethodService |
| iOS keyboard | Swift UIInputViewController |
| Optional local model | Candle / GGUF / Tokenizers |

## Build from source

### Prerequisites

- Rust stable toolchain
- Flutter 3.50.0 and the matching Dart SDK
- Android SDK and NDK for Android builds
- Xcode for macOS and iOS builds
- Visual Studio 2022 with Desktop development with C++ for Windows desktop builds

### Flutter setup and tests

    cd app
    flutter pub get
    flutter analyze
    flutter test

### Windows

Build the Rust DLL for the Windows MSVC target and place it beside the Flutter runner as described in [INSTALL_WINDOWS.md](INSTALL_WINDOWS.md), then run:

    cd app
    flutter build windows --release

### Android

Build the Rust JNI libraries for the required Android ABIs, then run:

    cd app
    flutter build apk --release

See [INSTALL_ANDROID.md](INSTALL_ANDROID.md) for the complete native build and keyboard steps.

### macOS and iOS

From the repository root:

    chmod +x scripts/build_apple.sh
    ./scripts/build_apple.sh

Then build the macOS app:

    cd app
    flutter pub get
    flutter build macos --release

The Apple build script creates the universal macOS Rust dylib and the iOS XCFramework. iOS device installation additionally requires Apple signing and provisioning; see [INSTALL_IOS.md](INSTALL_IOS.md).

---

## Repository layout

    app/                    Flutter application and platform projects
      android/              Android app and Kotlin keyboard
      ios/                  iOS app and Swift keyboard extension
      macos/                macOS desktop runner
      windows/              Windows desktop runner
      lib/                  Dart UI and application logic
      test/                 Flutter tests
    rust/                   Rust core engine and native bridges
    include/                Public C ABI header
    models/                 Local-model manifest and setup information
    scripts/                Native build scripts
    .github/workflows/      CI and release automation

## Contributing and issue reports

Bug reports, reproducible steps, platform details, and sanitized logs are welcome through [GitHub Issues](https://github.com/tracolerd/appendix/issues). Do not include private documents or sensitive text in bug reports.

## License

Appendix is distributed under the [Apache License 2.0](LICENSE). Third-party notices and component licensing details are in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
