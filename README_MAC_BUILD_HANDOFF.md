# Appendix — Apple Platform Development & Build Handoff Guide

This package contains the complete, frozen source tree and build pipeline for compiling, testing, and packaging **Appendix** on Apple macOS and iOS platforms.

---

## 📋 Handoff Overview

Appendix is a 100% offline, privacy-first English writing assistant featuring:
- **Rust Core**: Harper Core grammar checker, readability metrics, and offline rephrasing heuristics.
- **Flutter UI**: Desktop editor, sidebar, and companion application.
- **macOS Desktop**: Universal binary (`arm64` Apple Silicon + `x86_64` Intel) via `lipo`.
- **iOS Native Keyboard**: Swift `UIInputViewController` strictly isolated with `<key>RequestsOpenAccess</key><false/>`.

Because the primary engineering workstation operates on Windows 11 (which cannot compile Apple Darwin binaries or sign iOS packages), this handoff bundle enables a seamless, reproducible build on any standard Apple Mac.

---

## 🛠️ System & Toolchain Prerequisites

Before initiating builds, verify your Mac meets the following requirements:

| Tool | Recommended Version | Minimum Version | Installation Command |
|---|---|---|---|
| **Operating System** | macOS 14 Sonoma or 15 Sequoia | macOS 12 Monterey | System Settings -> Software Update |
| **Hardware** | Apple Silicon (M1/M2/M3/M4) | Intel Core i5/i7 (x86_64) | N/A |
| **Xcode** | Xcode 15.3 or 16.x | Xcode 14.3 | Mac App Store |
| **Flutter SDK** | Flutter 3.50.0+ | Flutter 3.24.0+ | `brew install --cask flutter` or [flutter.dev](https://flutter.dev) |
| **Rust Toolchain** | Rust 1.80.0+ (stable) | Rust 1.75.0+ | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| **CocoaPods** | CocoaPods 1.15+ | CocoaPods 1.12+ | `brew install cocoapods` or `sudo gem install cocoapods` |

### Required Rustup Targets:
Install the Apple compilation targets in your terminal:
```bash
rustup target add aarch64-apple-darwin       # macOS Apple Silicon
rustup target add x86_64-apple-darwin        # macOS Intel
rustup target add aarch64-apple-ios          # Physical iPhone / iPad
rustup target add aarch64-apple-ios-sim      # Apple Silicon iOS Simulator
rustup target add x86_64-apple-ios           # Intel Mac iOS Simulator
```

---

## 🚀 Quick Start: Automated Build Pipeline

The handoff package includes automated scripts for environment qualification and end-to-end building:

### Step 1: Run Environment Qualification
```bash
chmod +x MAC_BUILD_ENVIRONMENT_CHECK.sh
./MAC_BUILD_ENVIRONMENT_CHECK.sh
```
This script audits your hardware, disk space, Xcode installation, simulator runtimes, and Rust targets, reporting any missing prerequisites.

### Step 2: Execute Master Apple Build
```bash
chmod +x MAC_BUILD_COMMANDS.sh
./MAC_BUILD_COMMANDS.sh
```
This script automatically executes:
1. Rust compilation for all macOS and iOS targets.
2. Packaging of `libappendix_core.dylib` (Universal 2) and `AppendixCore.xcframework`.
3. Flutter dependency resolution, static analysis, and unit test execution.
4. macOS release application build (`app/build/macos/Build/Products/Release/appendix.app`).
5. iOS Simulator build validating that `AppendixKeyboard.appex` builds and embeds cleanly inside `Runner.app/PlugIns/`.

---

## 🔨 Step-by-Step Manual Build Instructions

If you prefer building each platform component individually:

### 1. Compile Rust Core Libraries (`libappendix_core.dylib` & `AppendixCore.xcframework`)
```bash
chmod +x scripts/build_apple.sh
./scripts/build_apple.sh
```
**Outputs Generated**:
- `app/macos/libappendix_core.dylib`: Universal binary containing both `arm64` and `x86_64`.
- `app/ios/Frameworks/AppendixCore.xcframework`: Multi-platform framework containing `ios-arm64` (device) and `ios-arm64_x86_64-simulator`.

### 2. Build the macOS Desktop Application
```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter build macos --release
```
**Output Package**:
- Located at: `app/build/macos/Build/Products/Release/appendix.app`.
- Drag and drop `appendix.app` into `/Applications` to test.

### 3. Build & Deploy iOS Application & Native Keyboard Extension
1. Open the iOS workspace in Xcode:
   ```bash
   open app/ios/Runner.xcworkspace
   ```
2. In the Xcode Project Navigator:
   - Select the top-level **Runner** project.
   - Under **TARGETS**, click on **Runner**:
     - Navigate to **Signing & Capabilities**.
     - Select your personal Apple Development Team.
   - Under **TARGETS**, click on **AppendixKeyboard**:
     - Navigate to **Signing & Capabilities**.
     - Select the same Apple Development Team.
3. Select your connected iPhone/iPad or an iOS Simulator in the scheme destination selector.
4. Press `Cmd + B` to build, or `Cmd + R` to deploy and run.

---

## 🔒 Security & Privacy Guarantees

- **Zero Network Permissions**: The application contains no network stack and zero tracking beacons.
- **Strict Keyboard Sandbox**: In `app/ios/AppendixKeyboard/Info.plist`, `<key>RequestsOpenAccess</key><false/>` is strictly enforced. Keystrokes cannot leave the isolated keyboard process memory.

---

## 🔧 Troubleshooting

### 1. "Command Line Tools" vs Full Xcode
- **Error**: `xcodebuild: error: SDK "iphonesimulator" cannot be located.`
- **Solution**: Switch your active developer directory to the full Xcode app:
  ```bash
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  ```

### 2. Signing Certificate Collision on Free Apple ID
- **Error**: Bundle identifier already registered by another team.
- **Solution**: In Xcode's Signing tab, change the bundle identifier prefix (e.g. from `org.appendix.appendix` to `com.yourname.appendix`). Update both the `Runner` and `AppendixKeyboard` targets (the extension's bundle ID must start with the Runner's bundle ID).

### 3. Missing Simulator Runtimes
- **Solution**: In Xcode, go to **Settings** -> **Platforms** -> Click `+` and install the latest **iOS Simulator**.

