# Appendix — iOS Source, Simulator Validation & Developer Build Guide

This document describes the current iOS implementation status and how a developer can build it. It is not an end-user installation guide: Appendix does not currently provide a signed IPA or an App Store download.

## Current status (17 November 2026)

- The Flutter iOS app target and native Swift keyboard-extension source are in the repository.
- The Rust core has an iOS XCFramework build script and is linked into the app and keyboard targets.
- The iOS Simulator build succeeded on the development Mac, and the app plus keyboard were manually exercised in the Simulator.
- A physical-device signed build has not been completed.
- Apple development-team signing, provisioning, physical-device validation, App Store archive generation, review, and publication remain outstanding.

Do not describe the current iOS source as App Store-ready. Simulator success does not establish physical-device or App Store readiness.

## Developer build prerequisites

- A Mac with a compatible Xcode installation.
- Flutter 3.50.0 and the matching Dart SDK.
- Rust stable with the Apple iOS targets installed.
- An Apple development team and valid provisioning profile for physical-device installation.

## Build the native Apple libraries

From the repository root:

    chmod +x scripts/build_apple.sh
    ./scripts/build_apple.sh

The script builds a universal macOS dylib and an iOS XCFramework for device and simulator architectures.

## Build and run in the iOS Simulator

    cd app
    flutter pub get
    flutter build ios --simulator --debug --no-codesign

Open the simulator device through Xcode's Devices and Simulators interface or the simulator application supplied with the installed Xcode version. Install and launch the generated Runner.app using Xcode or simctl.

## Install on a physical iPhone or iPad

1. Open app/ios/Runner.xcworkspace in Xcode.
2. Connect and select the target iPhone or iPad.
3. In Signing & Capabilities, select the correct Apple development team for both Runner and AppendixKeyboard.
4. Resolve bundle-identifier and provisioning-profile requirements for that team.
5. Build and install the signed app to the device.
6. On the device, open Settings → General → Keyboard → Keyboards → Add New Keyboard and enable Appendix Keyboard.
7. Test grammar checking, keyboard switching, secure text fields, and behavior across multiple apps.

A free Personal Team may be sufficient for development testing, subject to Apple's current provisioning limits. App Store distribution requires the appropriate Apple Developer Program membership and App Store review.

## Keyboard privacy configuration

The keyboard extension currently declares RequestsOpenAccess = false. Keep that setting unless a separately reviewed product requirement justifies changing it. The extension does not request Apple's Open Access capability. The keyboard stores its dialect preference locally; cross-process App Group preference synchronization is not currently implemented.

## Local AI model

The Qwen GGUF model is not bundled into the keyboard extension. The current design keeps heavyweight model inference in the companion app rather than loading the model inside the system keyboard.

## Important limitations

- There is no distributable IPA in the current GitHub release packages.
- Simulator validation is not physical-device validation.
- App Store submission, review, and publication have not been performed.
