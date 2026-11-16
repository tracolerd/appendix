# APPENDIX — PLATFORM SUPPORT MATRIX
## Comprehensive Platform Status, Verification Evidence, and Architecture Boundaries

**Last Updated:** 2026-11-15T22:20:00+06:00  
**Phase:** Phase 9 (Real-Device Validation, Source Handoff & Cross-Platform Build Qualification)  
**Project:** Appendix — Offline-First English Writing Assistant  

---

## 1. ARCHITECTURAL BOUNDARIES & WORKLOAD SEPARATION

To preserve battery life, responsive keystroke latencies, and strict OS sandbox memory limits (<40 MB RAM on iOS keyboard extensions), Appendix implements a strict architectural separation:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            MAIN HOST APPLICATION                            │
│  (Flutter Desktop & Mobile UI + Rust Core Dynamic Library)                  │
├─────────────────────────────────────────────────────────────────────────────┤
│  • Local AI Neural SLM Rewriting (Candle Runtime + Qwen 2.5 0.5B GGUF)      │
│  • 12 Rewriting Modes (Formal, Casual, Academic, Concise, etc.)             │
│  • Comprehensive Writing Insights (Flesch Reading Ease, Grade Level, TTR)   │
│  • Persistent Local Draft History & Versioning (SQLite)                     │
│  • Full Document Offline Grammar & Spell Checking (Harper Engine)           │
└─────────────────────────────────────────────────────────────────────────────┘
                                      ▲
                                      │ Independent Sandboxes / Privacy Isolation
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                       SYSTEM-WIDE MOBILE KEYBOARDS                          │
│  (Android InputMethodService & iOS UIInputViewController Extension)         │
├─────────────────────────────────────────────────────────────────────────────┤
│  • Real-time Keystroke Input & Custom Virtual Keyboards                     │
│  • 100% Offline Grammar & Spell Suggestions (Lightweight Rust Harper Engine)│
│  • American English (EN-US) vs British English (EN-GB) Dialect Support     │
│  • Zero-Cloud Privacy: NO INTERNET Permission, RequestsOpenAccess = false    │
│  • Sensitive Text Exclusion: Passwords, PINs, and secure fields bypass lint │
│  • Specialized Input Handling: Conservative bypass for numbers, URLs, email │
│  • Anti-Stale Suggestion Rejection on cursor movement                       │
│  • NO Neural GGUF Model inside Keyboards (Lightweight memory footprint)     │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. DETAILED PLATFORM SUPPORT MATRIX

| Platform / Component | Subsystem Architecture | Implemented | Built | Automated Tested | Emulator / Simulator Tested | Physical Device Tested | Current Status | Notes & Blockers |
|---|---|:---:|:---:|:---:|:---:|:---:|:---:|---|
| **Windows Desktop** | Flutter Desktop + `appendix_core.dll` + Candle Neural SLM | **YES** | **PARTIAL** | **YES** | N/A | **YES** | **PARTIALLY VERIFIED** | Rust DLL & unit tests 100% verified. Full `.exe` release packaging blocked by host missing VS C++ Desktop workload. |
| **Android Host App** | Flutter Android + `libappendix_core.so` (arm64, x86_64) | **YES** | **YES** | **YES** | **PENDING** | **PENDING** | **PARTIALLY VERIFIED** | Rebuilt release APK (92.5 MB, minSdkVersion 24). Package integrity verified; Debug signed. Physical device test pending hardware. |
| **Android System Keyboard (IME)** | Kotlin `AppendixInputMethodService` + JNI `NativeEngine` + Harper | **YES** | **YES** | **YES** | **PENDING** | **PENDING** | **PARTIALLY VERIFIED** | Packaged in release APK with source-compiled JNI libs. Zero `INTERNET` permission. Physical typing test pending hardware. |
| **iOS Host App** | Flutter iOS Runner + `AppDelegate.swift` | **YES** | **HANDOFF** | **YES** | **PENDING** | **PENDING** | **NOT VERIFIED ON HOST** | Flutter codebase & unit tests pass. Local build requires macOS/Xcode; handoff bundle prepared. |
| **iOS Keyboard Extension** | Swift `KeyboardViewController` + `NativeHarperBridge` + C ABI | **YES** | **HANDOFF** | **YES** | **PENDING** | **PENDING** | **NOT VERIFIED ON HOST** | Real Xcode Target `AppendixKeyboard` in `project.pbxproj`. `RequestsOpenAccess = false`. Handoff bundle prepared. |
| **macOS Desktop** | Flutter macOS + Universal `libappendix_core.dylib` | **YES** | **HANDOFF** | **YES** | N/A | **PENDING** | **NOT VERIFIED ON HOST** | Build script prepared in handoff bundle. Host is Windows 11; requires macOS host for compilation. |

---

## 3. COMPONENT & CAPABILITY BREAKDOWN

### A. Android Input Method Service (`AppendixInputMethodService.kt`)
- **Package:** `org.appendix.appendix.keyboard`
- **Native JNI Linkage:** `System.loadLibrary("appendix_core")` binding to `Java_org_appendix_appendix_keyboard_NativeEngine_*`.
- **Architectures Embedded (Fresh Source Build):**
  - `arm64-v8a`: Source binary 29.6 MB (`SHA256: 784FC7...`), Packaged stripped binary 23.2 MB (`SHA256: FCE0B4...`).
  - `x86_64`: Source binary 30.4 MB (`SHA256: 231641...`), Packaged stripped binary 25.6 MB (`SHA256: 63BF43...`).
- **Text Safety:**
  - Password and PIN fields (`TYPE_TEXT_VARIATION_PASSWORD`, `WEB_PASSWORD`, `VISIBLE_PASSWORD`, `TYPE_NUMBER_VARIATION_PASSWORD`): **100% Grammar Bypassed**, displays `Appendix 🔒 Password (Privacy Protected)`.
  - Specialized Input (Number, Phone, DateTime, URI, Email): Sentence-level grammar inspection conservatively suppressed to prevent false positives.
  - Composing Text & Selection: Replaces exact word spans using `deleteSurroundingText` and `commitText`.
- **Anti-Stale Protection:** Monotonic request ID tracking discards suggestions if text or cursor position changed during background analysis.
- **Privacy Audit:** `aapt dump permissions` confirms **ZERO `android.permission.INTERNET`** in release builds.

### B. iOS Custom Keyboard Extension (`AppendixKeyboard`)
- **Bundle Identifier:** `org.appendix.appendix.keyboard`
- **Xcode Target:** `PBXNativeTarget` (`com.apple.product-type.app-extension`) integrated into `Runner.xcodeproj` and embedded into `Runner.app/PlugIns`.
- **Privacy Enforcement:** `RequestsOpenAccess = false` in `AppendixKeyboard/Info.plist`. Keyboard runs strictly in Apple's restricted sandbox with zero network, zero unrestricted file storage, and zero clipboard access.
- **Independent Sandbox Preferences:** Does not depend on App Group shared preferences. Stores dialect preference locally in standard isolated `UserDefaults.standard` and provides a direct in-keyboard dialect toggle (US/UK).
- **Native Bridge:** `NativeHarperBridge.swift` calls Rust Harper C ABI (`appendix_engine_new`, `appendix_engine_check`, `appendix_engine_set_dialect`, `appendix_engine_free`) with safe bounds checking.
- **Sensitive Field Protection:** Detects `textDocumentProxy.isSecureTextEntry == true` and specialized inputs; suppresses context reading and displays privacy status badge.

### C. Main Host Application (`app/lib/`)
- **Local AI Rewriting Engine:** Qwen 2.5 0.5B Instruct GGUF running locally via Candle.
- **Isolate Execution:** Background Dart worker isolate prevents UI freezing.
- **RAM Reclamation:** Explicit model unload frees ~1,032 MB of OS working set memory.
- **Onboarding & Settings:** Platform-aware instructions for Android Settings and iOS Settings with truthful status indicators and clear feature boundaries.

---

## 4. REMAINING WORK FOR STORE DISTRIBUTION

1. **Android Play Store Distribution:**
   - Configure release signing keystore (`key.properties`).
   - Run `flutter build appbundle --release` (AAB packaging).
   - Execute physical-device testing across Android 12, 13, 14, and 15 devices.
2. **Apple App Store Distribution:**
   - Run build on macOS host with valid Apple Developer Team signing identity.
   - Test custom keyboard extension on physical iPhones running iOS 16+.
3. **Windows Desktop Installer:**
   - Install Visual Studio Desktop C++ workload on build machine to enable `flutter build windows --release`.
   - Package with Inno Setup or MSIX for Windows distribution.
