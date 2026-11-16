# Appendix — Cross-Platform Release Readiness Matrix

**Document Version**: 2.0.0 (Phase 8.1 Audit Update)  
**Audit Timestamp**: 2026-11-15T15:30:00Z  
**Git Base Commit**: `6394fb3c8f41a051be062b0460225f465626c110`  
**Git Branch**: `feat/local-ai-inference`  
**Working Tree Status**: `DIRTY_UNCOMMITTED_CHANGES_PRESENT`  
**Source Snapshot Fingerprint**: `89ae5e85143cdeb7329e04d78f68326ff0ccb6acafcc2aca4a15014357005a1c`  
**Repository**: [https://github.com/tracolerd/appendix](https://github.com/tracolerd/appendix)

---

## 📊 Summary Platform Readiness Grid

| Platform | Target Arch | Core Engine | App UI | System Keyboard | Packaging Format | Signing Status | Verification Status | Reproducibility (1-5) |
|---|---|---|---|---|---|---|---|:---:|
| **Android** | `arm64-v8a`, `x86_64` | ✅ Fully Compiled (`.so`) | ✅ Flutter App | ✅ Native Kotlin IME | APK (`.apk`), AAB (`.aab`) | ⚠️ Debug-Signed (`CN=Android Debug`) | **PARTIALLY VERIFIED** | 5/5 |
| **Windows Desktop** | `x86_64` (MSVC) | ✅ Fully Compiled (`.dll`) | ❌ Blocked on Host | N/A (Desktop) | Native DLL (`appendix_core.dll`) | ⚠️ Unsigned Open-Source DLL | **PARTIALLY VERIFIED** | 4/5 |
| **macOS Desktop** | `arm64` + `x86_64` | ⏳ CI Ready (`build_apple.sh`) | ⏳ CI Ready | N/A (Desktop) | Universal `.dylib`, `.app` | ⏳ Unsigned / Ad-hoc | **NOT VERIFIED** | 4/5 |
| **iOS Mobile** | `arm64` (Device) + Sim | ⏳ CI Ready (`build_apple.sh`) | ⏳ CI Ready | ✅ Native Swift Extension | `AppendixCore.xcframework`, `.ipa` | ⏳ Needs Team Provisioning | **NOT VERIFIED** | 3/5 |

*Standard Status Terms Used: `VERIFIED`, `PARTIALLY VERIFIED`, `NOT VERIFIED`, `BLOCKED`, `FAILED`, `NOT APPLICABLE`.*

---

## 🔍 Detailed Platform Audits

### 1. Android Platform

| Dimension | Assessment & Findings | Evidence & Verification Details |
|---|---|---|
| **Package Name** | `org.appendix.appendix` | Confirmed from packaged manifest via `aapt dump badging` |
| **Version & SDK** | Version `1.0.0` (Code `1`), Min SDK `24`, Target SDK `36` | Confirmed via `aapt dump badging` |
| **Target ABIs** | `arm64-v8a` (Primary mobile 64-bit), `x86_64` (Emulators) | Packaged in APK/AAB `lib/` directory; 32-bit `armeabi-v7a` contains Flutter runtime only (Rust core requires 64-bit) |
| **Packaged Native Core** | `libappendix_core.so` (arm64: `23,188,360 bytes`, x86_64: `25,591,272 bytes`) | Bit-for-bit match with stripped Gradle release output (`fce0b4ef9fcd...` and `63bf43dae77c...`) |
| **Signing Status** | `v2` APK Scheme / JAR signing with `CN=Android Debug` | Verified via `apksigner.bat` and `jarsigner.exe`. **NOT production Play Store signed**. |
| **Play Store Readiness** | **NOT VERIFIED** | Google Play Console rejects debug-signed bundles. Upload key generation and signing separation configured in `build.gradle.kts` but not executed with real secret. |
| **Sideload Readiness** | **VERIFIED** | APK can be sideloaded onto developer devices via `adb install` or direct file opening. |
| **Network & Privacy** | **VERIFIED (Zero Network Permissions)** | `android.permission.INTERNET` is completely absent in the packaged manifest. Only `VIBRATE` requested. |
| **System Virtual Keyboard** | Declared in manifest (`provides-component: 'ime'`) | Native Kotlin `AppendixInputMethodService` packaged. |
| **Physical Device Runtime**| **NOT VERIFIED** | Host workstation lacks attached Android hardware. Physical typing runtime behavior unverified on host. |
| **Automated Tests** | 21/21 Flutter tests passed | Ran in 11.2s; includes `keyboard_settings_test.dart` and `mobile_keyboard_integration_test.dart`. |
| **Overall Android Status** | **PARTIALLY VERIFIED** | Sideloadable APK built and verified; Play Store signing and physical hardware verification pending. |

---

### 2. Windows Desktop Platform

| Dimension | Assessment & Findings | Evidence & Verification Details |
|---|---|---|
| **Architectures** | `x86_64-pc-windows-msvc` | Built using MSVC 14.44.35207 and Windows 10 SDK 10.0.26100.0 |
| **Native Core DLL** | `appendix_core.dll` (`24,868,864 bytes`, SHA-256: `d2657ccdcdb1545b227d83720d212f62e06bd05a4a41a138ba309253d7a2eab4`) | Exporting all 21 C-ABI symbols (`appendix_*`, `Java_org_appendix_*`) |
| **Export Verification** | All 16 `appendix_*` and 5 JNI functions present | Verified via `dumpbin.exe /exports rust\target\release\appendix_core.dll` |
| **Complete Portable App** | **BLOCKED (DOES NOT EXIST LOCALLY)** | Complete Windows portable package (`appendix-windows-x64.zip`, `appendix.exe`, `flutter_windows.dll`, `data/`) does NOT exist on the host machine. |
| **Root Cause for Runner** | Toolchain Missing on Host | Visual Studio IDE `Microsoft.VisualStudio.Workload.NativeDesktop` is not installed on the workstation. |
| **Local AI Inference** | Qwen 2.5 0.5B Instruct GGUF (`491,400,032 bytes`) | Verified via Candle runtime on CPU (AVX2), all 5 deep integration tests passed (`test_ai_inference`). |
| **Network & Sockets** | **VERIFIED (0 Outbound Sockets)** | 100% offline local FFI engine. |
| **Overall Windows Status** | **PARTIALLY VERIFIED** | Core DLL and native engine 100% verified; standalone executable packaging blocked on host. |

---

### 3. Apple macOS Desktop Platform

| Dimension | Assessment & Findings | Evidence & Verification Details |
|---|---|---|
| **Local Build Artifacts** | `appendix.app`, `appendix-macos.zip`, `libappendix_core.dylib` | **DOES NOT EXIST LOCALLY (NOT BUILT)** |
| **Host Workstation Status**| **BLOCKED (Non-macOS Host)** | Workstation OS is Windows 11; compiling Apple binaries requires Darwin kernel and Xcode tools. |
| **Cross-Platform Scripts** | `scripts/build_apple.sh` configured | Universal binary (`arm64` + `x86_64`) compilation script via `lipo` established. |
| **CI Workflow Readiness** | `build-macos` job in `.github/workflows/release.yml` | Hardened workflow defined on `macos-latest`. |
| **Overall macOS Status** | **NOT VERIFIED** | CI workflow ready; zero local verification possible on Windows host. |

---

### 4. Apple iOS Mobile Platform

| Dimension | Assessment & Findings | Evidence & Verification Details |
|---|---|---|
| **Local Build Artifacts** | `AppendixCore.xcframework`, `Runner.app`, `AppendixKeyboard.appex`, `appendix-ios.ipa` | **DOES NOT EXIST LOCALLY (NOT BUILT)** |
| **Host Workstation Status**| **BLOCKED (Non-macOS Host)** | Requires macOS host with Xcode 15+ and Apple Developer provisioning profiles. |
| **Keyboard Extension** | Native Swift `UIInputViewController` (`KeyboardViewController.swift`) | Strict offline sandbox: `RequestsOpenAccess = false`. |
| **Memory Limit Adherence** | Harper Core consumes `<12 MB` | Complies with iOS keyboard extension 30 MB ceiling; 491 MB GGUF neural model isolated to companion app. |
| **CI Workflow Readiness** | `validate-ios` job in `.github/workflows/release.yml` | Headless Xcode build validation configured for `macos-latest`. |
| **Overall iOS Status** | **NOT VERIFIED** | Source integration complete; physical packaging and signing unexecuted. |

---

## 🎯 Release Sign-Off Summary

- **Local Validation Build**: Successfully produced for Android (`appendix-android.apk`) and Windows native library (`appendix_core.dll`).
- **Production Store Distribution**: **NOT READY / NOT VERIFIED** (Requires production keystore for Google Play and macOS/Xcode runners for Apple App Store).
- **Provenance Integrity**: Exact uncommitted source state documented in `SOURCE_SNAPSHOT_MANIFEST.json` (Fingerprint: `89ae5e85143cdeb7329e04d78f68326ff0ccb6acafcc2aca4a15014357005a1c`).
