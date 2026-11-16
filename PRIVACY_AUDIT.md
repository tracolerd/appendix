# Appendix — Privacy Implementation Notes

**Review date:** 17 November 2026  
**Project version:** 0.2.0  
**Review type:** Repository source, dependency manifest, and platform-configuration review

> This document records implementation details visible in the repository. It is not an independent penetration test, formal security certification, or proof that every runtime path on every supported operating system has been exhaustively tested.

## 1. Design intent

Appendix is designed to perform grammar checking, writing insights, draft-history operations, heuristic rewriting, and optional imported-model inference locally on the user's device. The project does not require an account or a hosted writing/AI service for its core local workflows.

The optional Qwen GGUF model is obtained separately by the user and stored locally. It is not bundled in the platform installers.

## 2. Platform configuration reviewed

### Android

File reviewed: app/android/app/src/main/AndroidManifest.xml

The manifest declares:
- android.permission.VIBRATE for keyboard haptic feedback.
- android.permission.BIND_INPUT_METHOD on the native keyboard service.

The manifest does **not** declare android.permission.INTERNET. This is a useful platform-level restriction on ordinary app network access. Re-check the final packaged APK's merged manifest when producing a release.

### iOS keyboard extension

File reviewed: app/ios/AppendixKeyboard/Info.plist

The keyboard extension declares RequestsOpenAccess = false. The extension therefore does not request Apple's Open Access capability.

This setting applies to the keyboard extension. It should not be represented as independent proof about every possible behavior of the containing app or every operating-system interaction. The keyboard's dialect preference is stored locally; cross-process App Group synchronization is not currently implemented.

### macOS

File reviewed: app/macos/Runner/Release.entitlements

The release entitlement enables App Sandbox and does not declare com.apple.security.network.client. This is evidence of a sandboxed configuration without the explicit network-client entitlement. It is not a substitute for runtime network testing or a complete review of all macOS entitlements and signing behavior.

### Windows

The Windows desktop application uses the local Flutter runner and Rust native library. This source review did not include a packet-capture test of the Windows release executable. Do not interpret the architecture description alone as an independently verified network-isolation certification.

## 3. Dependencies and local processing

The direct Flutter dependencies in app/pubspec.yaml are Flutter SDK, cupertino_icons, and ffi. The Rust manifest includes Harper Core, Candle components, tokenizers, SQLite, serialization, JNI, and supporting utility crates. No first-party cloud writing API or analytics SDK is configured in those direct dependency lists.

This review does not constitute a complete audit of every transitive dependency, build tool, or platform runtime.

## 4. User data and model handling

- Grammar checks and writing analytics are performed by the local Rust engine.
- Draft history uses local SQLite storage.
- The optional model is manually obtained and imported by the user; it is not fetched automatically by the release installer.
- The 0.5B model's expected SHA-256 is documented in models/model_manifest.json. Verify the actual downloaded file against that manifest before use.
- This review does not claim application-level encryption of the SQLite history database.

## 5. Verification steps for release reviewers

Before publishing a new binary, reviewers should independently:

1. Inspect the APK's merged permissions and confirm the INTERNET permission is absent.
2. Inspect the iOS keyboard extension's final packaged Info.plist and verify RequestsOpenAccess remains false.
3. Inspect the macOS app's signed entitlements after packaging.
4. Run network monitoring on each released platform if a strict no-network guarantee is required.
5. Review dependency updates and regenerate package checksums for every release.

Example Android permission inspection:

    aapt dump permissions appendix-android.apk

## 6. Scope and limitations

This document is a project-maintainer review of selected source files and manifests. It is not an external audit, penetration test, notarization result, platform-store approval, or guarantee against every possible third-party dependency or operating-system behavior. Build-time telemetry from developer tools is separate from the behavior of the installed Appendix application.
