# Appendix — Open-Source Offline English Writing Assistant

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Android%20%7C%20iOS-green.svg)]()
[![Privacy](https://img.shields.io/badge/Privacy-100%25%20Offline-orange.svg)]()

**Appendix** is a privacy-first, open-source, completely offline English writing companion. It provides real-time grammar checking, spelling correction, dialect adaptation (American & British English), and local AI-powered rewriting without sending a single byte of your writing to the cloud.

---

## 🌟 Core Pillars

1. **100% Offline & Private**: Zero external API calls, zero telemetry, zero accounts required. All processing runs entirely on your local machine.
2. **Lightning Fast**: Built on Harper's Rust engine (`<10ms` latency), checking mistakes as fast as you can type.
3. **Cross-Platform**: Designed for desktop (Windows, macOS) and mobile (Android, iOS) with a unified, elegant interface.
4. **Completely Free**: No premium tier, no paywalls, no ads, forever free under Apache 2.0.
5. **Dual English Dialects**: Full support for American English (US) and British English (UK).

---

## 🏗️ Architecture

```
Appendix/
├── app/                  # Flutter Cross-Platform UI (Dart)
├── rust/                 # Core Language & Grammar Engine (Rust + Harper + llama.cpp)
├── keyboard_android/     # Native Android Input Method (Kotlin)
├── keyboard_ios/         # Native iOS Keyboard Extension (Swift)
├── models/               # Local AI Model Manifests & Configurations
└── docs/                 # Architectural Decision Records & Specs
```

---

## 🛠️ Technology Stack

- **UI Framework**: Flutter (Dart 3.x) with Impeller GPU acceleration
- **Grammar & Spellchecking**: Rust (`harper-core` engine, Apache 2.0)
- **FFI Bridge**: `flutter_rust_bridge` (Async, zero-overhead Dart-Rust communication)
- **Local AI Engine**: `llama.cpp` runtime running quantized small language models (Qwen 2.5 series)
- **Local Persistence**: SQLite (`rusqlite` + `drift`)
- **Keyboards**: Native Kotlin (Android IME) and Native Swift (iOS Extension)

---

## 🚀 Getting Started

### Prerequisites

- Git
- Flutter SDK (>= 3.24.0)
- Rust toolchain (`rustc`, `cargo` >= 1.80.0)
- Android SDK (for Android builds)
- Visual Studio with C++ Desktop Workload (for Windows Desktop builds)
- Xcode (for macOS and iOS builds)

---

## 📄 License

Licensed under the [Apache License, Version 2.0](LICENSE).

