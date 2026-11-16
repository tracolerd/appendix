# Appendix — Android Installation, Keyboard Activation & User Guide

This guide covers installing the **Appendix** Android application and enabling the system-wide offline native keyboard (IME).

---

## 📱 System Requirements

| Requirement | Specification |
|---|---|
| **Operating System** | Android 7.0 (API Level 24 - Nougat) or higher |
| **Recommended OS** | Android 12+ (API 31+) |
| **Supported ABIs** | `arm64-v8a` (Primary mobile 64-bit ARM), `x86_64` (Android Emulators / Chromebooks) |
| **RAM** | 3 GB minimum (Grammar & IME); 6 GB+ recommended for local GGUF SLM |
| **Storage** | ~95 MB (Application + Core Engine); +491 MB optional for offline neural model |
| **Network Permission** | **NONE** (`android.permission.INTERNET` is neither requested nor declared) |
| **Signing Status** | **Debug-Signed Validation Package** (Development & Sideloading Only) |

---

## 🔐 Signing Status & Production Store Readiness

> [!WARNING]
> **Not Production Play Store Signed**  
> The artifacts currently provided (`appendix-android.apk` and `appendix-android.aab`) are signed with an **Android Debug Certificate** (`CN=Android Debug, O=Android, C=US`).  
> - **Sideloading (APK)**: Functional for local installation and developer testing on physical devices or emulators.  
> - **Google Play Store (AAB)**: **NOT READY / NOT VERIFIED**. The Google Play Console strictly rejects bundles signed with debug certificates.

### How to Produce a Production-Signed Release:
1. Generate an official release upload keystore (outside version control):
   ```bash
   keytool -genkey -v -keystore release.keystore -alias appendix-upload -keyalg RSA -keysize 2048 -validity 10000
   ```
2. Create `app/android/key.properties` (this file is excluded in `.gitignore`):
   ```properties
   storePassword=<SECURE_KEYSTORE_PASSWORD>
   keyPassword=<SECURE_KEY_PASSWORD>
   keyAlias=appendix-upload
   storeFile=../release.keystore
   ```
3. Re-run `./gradlew bundleRelease` or configure GitHub Secrets (`KEYSTORE_BASE64`, `STORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`) in CI.

---

## 📦 Installation Options

### Option A: Sideloading the Release APK via ADB (Developers & Power Users)

1. Connect your Android device with USB Debugging enabled in **Developer Options**.
2. Download `appendix-android.apk` and `appendix-android-apk.sha256` from [GitHub Releases](https://github.com/tracolerd/appendix/releases).
3. Verify integrity:
   ```bash
   sha256sum appendix-android.apk
   ```
4. Install directly:
   ```bash
   adb install -r appendix-android.apk
   ```

### Option B: Sideloading Directly on the Device

1. Download `appendix-android.apk` to your phone's storage.
2. In your device settings, enable **Install unknown apps** for your browser or file manager (**Settings** → **Apps** → **Special app access** → **Install unknown apps**).
3. Open `appendix-android.apk` and tap **Install**.
4. Play Protect may show an alert for sideloaded apps from unknown developers. Tap **More details** → **Install anyway**.

---

## ⌨️ Activating the System-Wide Appendix Keyboard (IME)

Once installed, enable the keyboard to use offline grammar corrections, spell check, and rephrasing across any application (WhatsApp, Chrome, Notes, Slack, Gmail, etc.):

1. Open **Settings** on your Android device.
2. Navigate to **System** → **Languages & input** (or **General management** on Samsung devices).
3. Tap **On-screen keyboard** → **Manage on-screen keyboards**.
4. Locate **Appendix Keyboard** and toggle the switch to **ON**.
5. Read the standard Android security disclaimer:
   > *"Attention: This input method may be able to collect all the text you type..."*
   *Note: This is the standard Android warning shown for third-party keyboards. The current app manifest does not declare the INTERNET permission. Review the final APK permissions and the project's privacy notes before enabling any third-party keyboard.*
6. Tap **OK** to activate.
7. To use it: Open any text field, tap the small keyboard icon in the navigation bar (or swipe down the notification shade), and select **Appendix Keyboard**.

---

## 🛡️ Privacy & Permissions Audit

You can independently verify that Appendix has **no internet access**:

```bash
# Verify using Android SDK AAPT tool:
aapt dump permissions app-release.apk

# Expected Output:
# package: org.appendix.appendix
# Zero permissions or only standard VIBRATE / POST_NOTIFICATIONS
# android.permission.INTERNET IS COMPLETELY ABSENT
```

On your device: Go to **Settings** → **Apps** → **Appendix** → **Permissions**. Notice that **Internet Access** is not even requested or listed in app permissions.

---

## 🧠 Local Neural AI Model Setup on Android

Appendix provides 12 rephrasing styles powered either by instant local heuristics or by the **Qwen 2.5 0.5B Instruct** GGUF model:

1. Open the **Appendix** app.
2. Go to **AI Assistant** or **Settings**.
3. Tap **Import Model (GGUF)** and select `qwen2.5-0.5b-instruct-q4_k_m.gguf` stored on your device.
4. The app verifies the SHA-256 checksum (`74a4da8c9fdbcd15bd1f6d01d621410d31c6fc00986f5eb687824e7b93d7a9db`).
5. Once imported, candidate strip rephrasing and deep neural tone shifts run fully offline on your device's CPU.

---

## 🔧 Troubleshooting

### 1. Appendix Keyboard Does Not Appear in On-Screen Keyboards
- **Cause**: Some device manufacturers (Xiaomi MIUI/HyperOS, Oppo ColorOS) restrict background services.
- **Solution**: Go to **App Info** for Appendix → **Autostart** / **Background activity** → Allow.

### 2. "App not installed as package appears to be invalid"
- **Cause**: Architecture mismatch (e.g. attempting to install on an obsolete 32-bit `armeabi-v7a` device).
- **Solution**: Appendix requires a 64-bit CPU (`arm64-v8a` or `x86_64`).

### 3. Out of Memory on Low-End Devices
- **Cause**: Neural SLM inference requires ~500 MB RAM overhead.
- **Solution**: Keep **Heuristic Engine** active for instant sub-millisecond suggestions without high memory consumption.

