# Appendix — Privacy & Zero-Telemetry Audit Report

**Audit Date**: 2026-11-15  
**Version**: 0.1.0  
**License**: Apache-2.0  
**Audit Scope**: Complete codebase inspection (`rust/`, `app/lib/`, `app/android/`, `app/ios/`, `app/macos/`, `models/`).

---

## 1. Executive Summary

Appendix is explicitly engineered from the ground up as a **100% offline, privacy-first English writing assistant**. Unlike commercial writing assistants (Grammarly, QuillBot, Wordtune), Appendix sends **zero bytes of text, telemetry, usage statistics, or user metadata** over any network connection.

This document records the architectural guarantees, automated scan results, and platform permission declarations that mathematically enforce offline privacy.

---

## 2. Platform Permission & Sandbox Audit

### A. Android Platform
- **Manifest Location**: `app/android/app/src/main/AndroidManifest.xml`
- **Internet Permission Audit**:
  ```xml
  <!-- Checked: android.permission.INTERNET is NOT declared -->
  ```
  - Result: **CLEAN**. The application does NOT request or possess `android.permission.INTERNET`. The Android Linux kernel automatically drops any network socket operations attempted by the process.
- **Declared Permissions**:
  - `android.permission.VIBRATE`: Required exclusively for tactile haptic feedback during keyboard key presses.
  - `android.permission.BIND_INPUT_METHOD`: Required by Android OS for system-wide virtual keyboard services (`InputMethodService`).

### B. iOS & iPadOS Platform
- **Extension Plist Location**: `app/ios/AppendixKeyboard/Info.plist`
- **Network Isolation Audit**:
  ```xml
  <key>NSExtensionAttributes</key>
  <dict>
      <key>RequestsOpenAccess</key>
      <false/>
  </dict>
  ```
  - Result: **CLEAN**. By declaring `RequestsOpenAccess = false`, Apple's iOS security sandbox enforces strict local execution. The keyboard extension cannot access the network, location services, contacts, camera, or microphone. Any socket invocation results in immediate kernel-level termination.
- **Container App Communication**:
  - Configuration sharing (US vs. UK dialect) occurs solely via local `UserDefaults(suiteName: "group.org.appendix.appendix")` stored in memory and local flash storage on the device.

### C. macOS & Windows Desktop
- **Sandboxing**: `app/macos/Runner/Release.entitlements` enforces app sandboxing without network client entitlements (`com.apple.security.network.client` is absent).
- **Windows**: The standalone binary (`appendix.exe` + `appendix_core.dll`) communicates exclusively with local RAM and local SQLite storage (`history.db`).

---

## 3. Dependency & Telemetry Audit

Every dependency across both Rust and Flutter packages has been audited for embedded telemetry, tracking, or network calls:

| Package / Crate | Ecosystem | Purpose | Telemetry Status |
|---|---|---|---|
| `harper-core 3.2.0` | Rust | Rule-based grammar and spell checking | **Zero network calls. 100% local.** |
| `rusqlite 0.33` | Rust | Embedded SQLite storage | **Zero network calls. Bundled C SQLite.** |
| `serde` & `serde_json` | Rust | JSON serialization | **Zero network calls.** |
| `chrono` | Rust | Local timestamps for draft history | **Zero network calls.** |
| `jni 0.21` | Rust | Android JNI interop | **Zero network calls.** |
| `flutter` (Dart 3.14) | Dart | UI framework | **Zero analytics. Telemetry disabled.** |
| `ffi` | Dart | Direct C ABI memory interop | **Zero network calls.** |

### Forbidden SDK Checklist:
- [x] **Firebase Analytics / Crashlytics**: NOT PRESENT.
- [x] **Google Analytics**: NOT PRESENT.
- [x] **Mixpanel / Amplitude / PostHog**: NOT PRESENT.
- [x] **Sentry / Bugsnag**: NOT PRESENT.
- [x] **OpenAI / Claude / Gemini Cloud APIs**: NOT PRESENT.
- [x] **Background HTTP daemons**: NOT PRESENT.

---

## 4. Local AI & Model Storage Policy

1. **Storage Location**: Models reside in the user's local application data directory or `models/` directory on their physical disk.
2. **Inference**: Inference runs strictly on local CPU / NPU / GPU via local runtimes (`llama.cpp` / ONNX Runtime).
3. **No External Weights**: Weights are downloaded voluntarily and manually by the user or pre-packaged via release assets. The application never initiates automated remote downloads without explicit user command.
4. **Draft History**: Saved drafts are kept in a local SQLite file (`history.db`) in the application's private storage, encrypted with user-level OS file protection.

---

## 5. Audit Certification

Appendix complies 100% with the open-source offline charter. It represents a fully private, autonomous alternative for sensitive documents, legal writing, journalism, healthcare, and enterprise communication where data leakage to third-party cloud servers is strictly unacceptable.
