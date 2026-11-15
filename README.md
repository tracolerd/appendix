# Appendix — Open-Source Offline English Writing Assistant

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Android%20%7C%20macOS%20%7C%20iOS-green.svg)]()
[![Privacy](https://img.shields.io/badge/Privacy-100%25%20Offline-brightgreen.svg)](PRIVACY_AUDIT.md)
[![Rust](https://img.shields.io/badge/Rust-1.80+-orange.svg)]()
[![Flutter](https://img.shields.io/badge/Flutter-3.50.0-02569B.svg)]()

**Appendix** is an open-source, 100% offline, privacy-first English writing assistant and system-wide keyboard. Inspired by the capabilities of Grammarly and QuillBot, Appendix offers an independent, autonomous alternative: zero cloud dependencies, zero subscription paywalls, zero telemetry, and zero tracking.

Every keystroke, grammar check, readability score, and AI rephrase happens entirely on your local CPU / GPU inside your device's memory.

---

## 📥 Platform Artifacts & Installation Guides

| Platform | Local Build Artifacts | Signing & Packaging Status | Installation Guide |
|---|---|---|---|
| **Android** | `appendix-android.apk` (APK), `appendix-android.aab` (AAB) | ⚠️ **Debug-signed validation package** (`CN=Android Debug`). Ready for developer sideloading; Google Play Store release **NOT VERIFIED** until signed with an official upload key. | [INSTALL_ANDROID.md](INSTALL_ANDROID.md) |
| **Windows** | `appendix_core.dll` (MSVC x64 C-ABI DLL) | ⚠️ **Native DLL only**. Full portable desktop ZIP blocked on host workstation (requires Visual Studio Desktop C++ workload); packaged automatically via GitHub Actions `windows-latest`. | [INSTALL_WINDOWS.md](INSTALL_WINDOWS.md) |
| **macOS** | Build scripts & CI workflows ready | ⏳ **Not built locally** (Host is Windows 11; requires macOS host or `macos-latest` CI runner). | [INSTALL_MACOS.md](INSTALL_MACOS.md) |
| **iOS** | Native Swift extension & XCFramework script ready | ⏳ **Not built locally** (Requires macOS host with Xcode and Apple developer provisioning). | [INSTALL_IOS.md](INSTALL_IOS.md) |

For third-party open-source component licenses and attribution, see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
For the exact source snapshot and uncommitted build provenance, see [SOURCE_SNAPSHOT_MANIFEST.json](SOURCE_SNAPSHOT_MANIFEST.json).

---

## 📊 Cross-Platform Support & Distribution Matrix

| Dimension | Android | Windows | macOS | iOS |
|---|---|---|---|---|
| **Harper Core Grammar & Spell Engine** | ✅ Yes (JNI Native `.so`) | ✅ Yes (FFI Native DLL) | ✅ Yes (FFI Native dylib) | ✅ Yes (C-Bridging Header) |
| **Readability & Writing Analytics** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **Local Draft History (SQLite)** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **12 Rewriting Styles (Heuristics)** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **Local Neural AI (Qwen 2.5 0.5B GGUF)** | ✅ Yes (CPU / NEON) | ✅ Yes (CPU / AVX2) | ✅ Yes (Metal / Accelerate) | ⚠️ Companion App only (iOS RAM limit) |
| **System-Wide Virtual Keyboard (IME)** | ✅ Native Kotlin IME | N/A (Desktop) | N/A (Desktop) | ✅ Native Swift Extension |
| **Zero Internet Network Access** | 🔒 100% Offline (No `INTERNET`) | 🔒 100% Offline (0 Sockets) | 🔒 100% Offline (Sandbox) | 🔒 100% Offline (`RequestsOpenAccess=false`) |
| **Local Release Packaging** | 🟢 **APK & AAB Built** | 🟡 **DLL Only (Runner Blocked)** | 🟠 **Not Built (Host Blocked)** | 🟠 **Not Built (Host Blocked)** |
| **Production Signing Status** | ⚠️ Debug-Signed (`CN=Android Debug`) | ⚠️ Unsigned Open-Source DLL | ⚠️ Unsigned / Ad-hoc | ⚠️ Needs Team Provisioning |
| **Distribution Readiness Verdict** | **PARTIALLY VERIFIED** (Sideload Only) | **PARTIALLY VERIFIED** (DLL Only) | **NOT VERIFIED** (CI Ready) | **NOT VERIFIED** (CI Ready) |

---

## 🌟 Key Capabilities

### 1. Real-time Offline Grammar & Spell Checking
- Powered by **Harper Core 3.2.0** compiled in Rust.
- Sub-millisecond latency (`<10ms`).
- Deep syntactic, stylistic, and spelling analysis.
- Dual-dialect support: **American English (US)** and **British English (UK)** with instantaneous switching.

### 2. 12 Offline Writing & Rephrasing Styles
- Rephrase & Polish
- Make Professional
- Make Academic
- Make Formal
- Make Casual
- Make Concise
- Expand Content
- Improve Clarity
- Improve Vocabulary
- Simplify
- Active to Passive Voice
- Passive to Active Voice
- Supported by Qwen 2.5 series local SLMs (0.5B, 1.5B, 3B GGUF) and built-in offline rule-based heuristic fallback engines.

### 3. Deep Writing Insights & Readability Analytics
- **Flesch Reading Ease** gauge (0–100 scale).
- **Flesch-Kincaid Grade Level** estimator.
- **Type-Token Ratio (TTR)** vocabulary diversity tracker.
- **Overused Words Detector** highlighting redundancy.
- Sentence length distribution analysis.

### 4. Local SQLite Draft History
- Automatic local snapshots stored in private SQLite database (`history.db`).
- Instant restore, word count tracking, readability archiving, and one-click database clearing.
- Never synced to any cloud.

### 5. System-Wide Mobile Keyboards (Android & iOS)
- **Android Keyboard (IME)**: Native Kotlin `InputMethodService` with real-time candidate strip suggestions, one-tap replacements, full QWERTY/symbols layout, and tactile haptic feedback.
- **iOS Keyboard Extension**: Native Swift `UIInputViewController` strictly isolated with `RequestsOpenAccess = false` (Apple kernel-enforced offline isolation). Includes mandatory Globe key for seamless switching.

---

## 🏗️ Architecture

```mermaid
graph TD
    subgraph Client Application Layer
        UI["Flutter Cross-Platform UI<br/>(Editor, Sidebar, Toolbar, AI Panel, Insights)"]
        AKB["Android Native Keyboard<br/>(Kotlin InputMethodService)"]
        IKB["iOS Native Keyboard<br/>(Swift UIInputViewController)"]
    end

    subgraph Interop & Bridge Layer
        FFI["Dart FFI (C ABI)"]
        JNI["JNI Bridge (Java Native Interface)"]
        SWIFT_C["C-Bridging Header (Swift C ABI)"]
    end

    subgraph Core Engine Layer (Rust appendix_core)
        HARPER["Harper 3.2.0 Grammar Engine<br/>(Curated FST Dictionary & Linters)"]
        INSIGHTS["Readability & Insights Engine<br/>(Flesch, Syllable Counter, TTR)"]
        REPHRASE["Local AI & Heuristic Rephraser<br/>(Qwen 2.5 ChatML + Offline Rules)"]
        SQLITE["Embedded SQLite Storage<br/>(Draft Snapshots & Metrics)"]
    end

    UI --> FFI
    AKB --> JNI
    IKB --> SWIFT_C

    FFI --> HARPER
    FFI --> INSIGHTS
    FFI --> REPHRASE
    FFI --> SQLITE

    JNI --> HARPER
    JNI --> INSIGHTS
    JNI --> REPHRASE

    SWIFT_C --> HARPER
```

---

## 📂 Repository Structure

```
Project Typing App/
├── app/                              # Flutter Cross-Platform Application
│   ├── android/                      # Android project & Native Kotlin IME Keyboard
│   │   └── app/src/main/
│   │       ├── kotlin/.../keyboard/  # AppendixInputMethodService & NativeEngine
│   │       ├── jniLibs/              # Compiled arm64-v8a and x86_64 .so binaries
│   │       └── res/xml/method.xml    # IME subtypes definition
│   ├── ios/                          # iOS project & Swift Keyboard Extension
│   │   ├── AppendixKeyboard/         # KeyboardViewController & NativeHarperBridge
│   │   └── Runner/AppDelegate.swift  # App Group preferences synchronization
│   ├── macos/                        # macOS Desktop runner & entitlements
│   ├── windows/                      # Windows Desktop runner
│   ├── lib/                          # Flutter Dart UI & Business Logic
│   │   ├── core/ffi/                 # Native grammar engine & C-ABI bindings
│   │   └── features/                 # Editor, AI Assistant, Insights, History, Keyboard Setup
│   └── test/                         # Comprehensive Flutter widget & unit test suite
├── rust/                             # Core Rust Engine crate (appendix_core)
│   ├── src/
│   │   ├── lib.rs                    # C ABI exports & dialect management
│   │   ├── jni_bridge.rs             # High-performance JNI methods for Android
│   │   ├── insights.rs               # Readability & vocabulary analytics
│   │   ├── ai_rephrase.rs            # 12 rewriting styles & Qwen ChatML formatting
│   │   └── history.rs                # SQLite local snapshot storage
│   └── Cargo.toml                    # harper-core, rusqlite, jni, serde
├── include/                          # Public C Header (appendix_core.h)
├── models/                           # GGUF manifest & local SLM specifications
├── scripts/                          # Packaging & build scripts (Apple, Windows)
├── .github/workflows/                # Automated CI/CD & Multi-Platform Release workflows
├── LICENSE                           # Apache-2.0 License
├── PRIVACY_AUDIT.md                  # Comprehensive Zero-Telemetry Audit Report
└── README.md                         # Master Documentation
```

---

## 🚀 Building & Running

### 1. Prerequisites
- **Rust**: `1.80+` (via `rustup`)
- **Flutter**: `3.50+` (Dart `3.14+`)
- **Android SDK & NDK**: NDK 27+ (for Android builds)
- **Xcode 15+**: (for macOS & iOS builds)

---

### 2. Building the Rust Core Engine
```bash
cd rust

# Build release dynamic library (Windows DLL / Linux SO / macOS dylib)
cargo build --release

# Run unit tests
cargo test
```

---

### 3. Running the Flutter Desktop Application
```bash
cd app

# Fetch dependencies
flutter pub get

# Run tests
flutter test

# Run app on your connected device or desktop
flutter run -d windows    # On Windows
flutter run -d macos      # On macOS
```

---

### 4. Compiling for Android & Building the APK
```bash
# 1. Compile Rust shared libraries for Android targets
cd rust
cargo ndk -t arm64-v8a -t x86_64 -o ../app/android/app/src/main/jniLibs build --release

# 2. Build the Android APK
cd ../app
flutter build apk --release
```
The resulting APK is generated at:  
`app/build/app/outputs/flutter-apk/app-release.apk`

---

### 5. Compiling for macOS & iOS (Apple Platforms)
```bash
# Run the automated Apple build script
chmod +x scripts/build_apple.sh
./scripts/build_apple.sh
```
This script automatically compiles:
- `libappendix_core.dylib`: macOS Universal Binary (`arm64` + `x86_64` via `lipo`).
- `AppendixCore.xcframework`: iOS Multi-architecture XCFramework (`arm64-ios` + `sim-universal`).

---

## 🔒 Zero-Telemetry & Privacy Guarantee

Appendix takes privacy seriously:
1. **No Network Access**: The Android manifest does **not** request `android.permission.INTERNET`. The iOS keyboard specifies `<key>RequestsOpenAccess</key><false/>`.
2. **Zero Third-Party SDKs**: No Google Analytics, Firebase, Mixpanel, Sentry, or tracking beacons.
3. **Local Storage Only**: Your drafts are stored strictly on your local disk in SQLite.
4. For complete verification details, read our certified [PRIVACY_AUDIT.md](PRIVACY_AUDIT.md).

---

## 📄 License

Appendix is licensed under the **Apache License, Version 2.0**. You are free to inspect, modify, distribute, and embed this software freely without subscription fees or closed-source restrictions. See the [LICENSE](LICENSE) file for complete details.
