# Appendix — iOS Installation & Keyboard Extension Setup Guide

This guide covers building, deploying, activating, and troubleshooting **Appendix** and its native Swift keyboard extension on Apple iOS.

---

## 📱 System Requirements

| Requirement | Specification |
|---|---|
| **Operating System** | iOS 15.0 or later (Tested through iOS 17 & 18) |
| **Supported Devices** | 64-bit iPhone and iPad models (A12 Bionic or newer recommended) |
| **Development Host** | macOS 13+ with Xcode 15+ (required for building and sideloading) |
| **Network Access** | **NONE** (`RequestsOpenAccess = false` kernel-enforced offline isolation) |

---

## 📦 Deployment & Installation Options

Because Appendix is an independent open-source project without mandatory App Store subscriptions:

### Option A: Building & Deploying via Xcode (Recommended for Developers)

1. Clone the repository on a macOS machine:
   ```bash
   git clone https://github.com/tracolerd/appendix.git
   cd appendix
   ```
2. Build the native Apple binary artifacts:
   ```bash
   chmod +x scripts/build_apple.sh
   ./scripts/build_apple.sh
   ```
   This compiles `AppendixCore.xcframework` for both iOS devices and the iOS Simulator.
3. Open `app/ios/Runner.xcworkspace` in Xcode.
4. Select your connected iPhone/iPad or iOS Simulator.
5. In Xcode's **Signing & Capabilities** tab for both `Runner` and `AppendixKeyboard`:
   - Select your personal Apple Development Team.
   - Adjust the Bundle Identifier prefix if required for free personal provisioning.
6. Click **Run** (`Cmd + R`) to compile, sign, and install the app and keyboard extension onto your device.

### Option B: Sideloading via AltStore, Sideloadly, or TrollStore

1. Export the signed `.ipa` package from Xcode Organizer (Ad-Hoc or Development distribution).
2. Install via **AltStore** or **Sideloadly** by signing with your personal Apple ID.
3. On your iOS device, go to **Settings** → **General** → **VPN & Device Management** and trust your developer certificate.

---

## ⌨️ Activating the System-Wide Appendix Keyboard

1. On your iPhone or iPad, open **Settings**.
2. Navigate to **General** → **Keyboard** → **Keyboards**.
3. Tap **Add New Keyboard...**.
4. Under **Third-Party Keyboards**, select **Appendix Keyboard**.
5. Tap **Appendix Keyboard** in your list of active keyboards:
   - Notice the setting: **Allow Full Access** is **OFF** by default.

### 🛡️ Why Does Appendix NOT Require "Full Access"?
Apple's iOS security sandbox strictly enforces that keyboards with **Allow Full Access: OFF** have **NO network access whatsoever**. 
- Keystrokes cannot leave the isolated keyboard extension memory.
- Network sockets, pasteboard snooping, and microphone access are blocked at the kernel level.
- Appendix runs its **Harper Core 3.2.0** grammar engine, spell checker, and dialect logic directly inside the extension memory sandbox completely offline.

*(Note: If a future update utilizes a shared App Group container for offline neural model weights greater than the extension RAM quota, Full Access is only used for local file container access, never network transmission).*

---

## 🌍 Switching Keyboards in iOS

The Appendix keyboard adheres strictly to Apple's Human Interface Guidelines (HIG):
- Tap the **Globe (🌐)** icon at the bottom-left to cycle between your keyboards.
- Long-press the **Globe (🌐)** icon to bring up the iOS keyboard switcher popup menu.

---

## 🧠 iOS Memory Limitations & AI Rephrasing

Apple enforces a strict memory limit on keyboard extensions:
- **Keyboard Extension Memory Limit**: ~30 MB to 50 MB maximum resident memory.
- If an extension exceeds this quota, iOS terminates the process immediately (manifesting as a keyboard flash/disappearance).
- **Architecture Solution**:
  - The **Harper Core** grammar and spelling engine consumes `<12 MB`, operating well within the 30 MB ceiling.
  - The heavy **Qwen 2.5 0.5B neural model** (~491 MB) cannot be loaded inside the keyboard extension process directly due to Apple's kernel ceiling.
  - For full neural rephrasing and long-form document rewriting, open the **Appendix Companion App** directly on iOS, where the app has access to standard multi-gigabyte memory limits.

---

## 🔧 Troubleshooting

### 1. Keyboard Doesn't Open or Shows a Blank Box
- **Cause**: Memory limit exceeded during initialization.
- **Solution**: Ensure debug logging is disabled in release builds and no large dictionary datasets are embedded in the extension binary.

### 2. "Untrusted Developer" Warning
- **Cause**: Standard iOS security prompt for free personal Apple ID sideloading.
- **Solution**: Open **Settings** → **General** → **VPN & Device Management** → Tap your Apple ID profile → Tap **Trust**.

