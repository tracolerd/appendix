# Appendix — Platform Acceptance & Real-Device Testing Checklist

**Document Version**: 1.0.0 (Phase 9 Qualification Deliverable)  
**Author**: Cross-Platform QA Lead & Principal Release Engineer  
**Status**: Real-Device Execution Pending (Physical Device Testing Checklist)

---

## 🤖 Part 1: Android Physical Device Acceptance Checklist (20 Tests)

> [!IMPORTANT]
> **Pre-conditions**: Physical Android hardware device running Android 7.0+ (API 24+) connected via USB with Developer Options enabled, or sideloaded via direct APK transfer.  
> **Package under test**: `dist/appendix-android.apk` (SHA-256: `b489241cbceb9ad0c8d5a6f92d9ccf4e1500e0097edc99e41d862254ec72c56b`).

| # | Test Scenario | Execution Procedure | Expected Result | Actual Result / Status |
|---|---|---|---|:---:|
| **1** | **APK Installation** | `adb install -r appendix-android.apk` | Installation finishes with `Success` without signature error. | ⚪ **Pending Device** |
| **2** | **App Cold Boot** | Tap Appendix launcher icon | Companion app launches cleanly; editor renders. | ⚪ **Pending Device** |
| **3** | **Enable Keyboard** | Navigate to Settings -> System -> Languages & Input -> On-screen keyboard -> Manage keyboards -> Toggle Appendix | Standard Android warning shown; Appendix toggles ON. | ⚪ **Pending Device** |
| **4** | **Select Input Method** | Tap keyboard selector icon in navigation bar; select Appendix Keyboard | Appendix IME becomes active default input method. | ⚪ **Pending Device** |
| **5** | **Editor Text Input** | Open a standard text field (e.g. Google Keep, Notes, WhatsApp) | Full QWERTY keyboard appears with candidates bar. | ⚪ **Pending Device** |
| **6** | **Grammar Error Detection** | Type: `"She go to school yesterday."` | Harper engine flags `"go"` with suggestion `"went"`. | ⚪ **Pending Device** |
| **7** | **Candidate Strip Latency** | Observe suggestion strip latency while typing | Candidate appears within `<50ms` on local CPU. | ⚪ **Pending Device** |
| **8** | **One-Tap Replacement** | Tap candidate chip `"went"` | `"go"` is replaced with `"went"` seamlessly in editor. | ⚪ **Pending Device** |
| **9** | **Cursor Repositioning** | Move cursor between words; edit middle of sentence | Suggestion strip updates context to active word token. | ⚪ **Pending Device** |
| **10** | **Fast Typing / Concurrency** | Type rapid characters (`>80 WPM`) | Stale async responses do not overwrite newer typed input. | ⚪ **Pending Device** |
| **11** | **Multiline Editing** | Press Enter multiple times; type multiline paragraphs | Keyboard scrolls or text view expands without crashing. | ⚪ **Pending Device** |
| **12** | **Email & URL Fields** | Focus an email input field (`textEmailAddress`) | Keyboard displays dedicated `@` and `.com` / URL keys. | ⚪ **Pending Device** |
| **13** | **Password Fields** | Focus a secure password input field (`textPassword`) | Suggestions strip hides private tokens; text is masked. | ⚪ **Pending Device** |
| **14** | **Numeric / Phone Fields** | Focus numeric input (`number` / `phone`) | Keyboard presents numeric keypad layout. | ⚪ **Pending Device** |
| **15** | **Application Switching** | Switch between WhatsApp, Chrome, and Gmail | IME maintains state across backgrounding/foregrounding. | ⚪ **Pending Device** |
| **16** | **Keyboard Switching** | Tap language/globe switch key | Cycles back to Gboard or default OEM keyboard smoothly. | ⚪ **Pending Device** |
| **17** | **Airplane Mode (Offline)** | Turn ON Airplane Mode (Wi-Fi and Cellular OFF); type | Grammar suggestions function 100% identically offline. | ⚪ **Pending Device** |
| **18** | **Zero Network Verification** | Inspect device App Info -> Data Usage | Mobile Data and Wi-Fi usage display **0.0 KB**. | ⚪ **Pending Device** |
| **19** | **Process Lifecycle Reopen** | Kill companion app in Recent Apps; open Notes & type | Keyboard InputMethodService continues typing without crash. | ⚪ **Pending Device** |
| **20** | **Engine Graceful Fallback**| Force native library reload failure in test environment | Keyboard logs warning and falls back without ANR or crash. | ⚪ **Pending Device** |

---

## 🍏 Part 2: iPhone Physical Device Acceptance Checklist (18 Tests)

> [!IMPORTANT]
> **Pre-conditions**: Physical iPhone running iOS 15+ deployed with personal developer certificate via Xcode, AltStore, or TestFlight.  
> **Source Package**: Built from `APPENDIX_MAC_BUILD_HANDOFF.zip`.

| # | Test Scenario | Execution Procedure | Expected Result | Actual Result / Status |
|---|---|---|---|:---:|
| **1** | **IPA / App Installation** | Deploy via Xcode (`Cmd + R`) or AltStore | App and Keyboard Extension install onto device. | ⚪ **Pending Mac Build** |
| **2** | **iOS Settings Activation** | Settings -> General -> Keyboard -> Keyboards -> Add New Keyboard -> Appendix | Appendix Keyboard appears under Third-Party Keyboards. | ⚪ **Pending Mac Build** |
| **3** | **Allow Full Access Status** | Open Appendix Keyboard in Settings; inspect "Allow Full Access" | **Allow Full Access** is **OFF** by default. | ⚪ **Pending Mac Build** |
| **4** | **Initial Launch & Typing** | Open Apple Notes or Messages; tap Globe icon to switch to Appendix | Custom QWERTY layout renders with responsive keys. | ⚪ **Pending Mac Build** |
| **5** | **Harper Suggestion Strip** | Type sentence with typo: `"Their are two options."` | Suggestion strip highlights `"There"` within `<50ms`. | ⚪ **Pending Mac Build** |
| **6** | **One-Tap Suggestion Apply**| Tap `"There"` in top bar | Text replaces immediately in UITextView. | ⚪ **Pending Mac Build** |
| **7** | **American Dialect Test** | Type `"color"` with American dialect active | No grammar or spelling warning issued. | ⚪ **Pending Mac Build** |
| **8** | **British Dialect Test** | Switch dialect in companion app to British; type `"color"` | Suggestion offers `"colour"`. | ⚪ **Pending Mac Build** |
| **9** | **Globe Key HIG Compliance** | Tap Globe (🌐) icon briefly | Cycles seamlessly to standard Apple keyboard. | ⚪ **Pending Mac Build** |
| **10** | **Globe Key Long Press** | Press and hold Globe (🌐) icon | Standard iOS system input switcher popup menu appears. | ⚪ **Pending Mac Build** |
| **11** | **Secure Text Entry** | Tap on a password field (e.g. Safari login form) | iOS automatically switches to secure system keyboard. | ⚪ **Pending Mac Build** |
| **12** | **Phone Pad Input** | Focus a telephone number input field | System displays standard iOS phone dial pad. | ⚪ **Pending Mac Build** |
| **13** | **Memory Ceiling Adherence** | Type continuously for 5 minutes; monitor resident RAM | Extension memory remains `<25 MB` (under 30 MB quota). | ⚪ **Pending Mac Build** |
| **14** | **No App Group Dependency** | Verify Harper Core runs directly inside extension memory | Operates completely independent of shared containers. | ⚪ **Pending Mac Build** |
| **15** | **Zero Network Transmission**| Enable Airplane Mode; verify network traffic in Xcode Instruments | 0 bytes transmitted; kernel enforces network block. | ⚪ **Pending Mac Build** |
| **16** | **App Backgrounding/Resume** | Leave app to home screen; reopen app | Keyboard recovers state immediately without lag. | ⚪ **Pending Mac Build** |
| **17** | **Haptic Feedback** | Enable haptics in companion settings; press keys | Subtle Taptic Engine feedback triggers per keystroke. | ⚪ **Pending Mac Build** |
| **18** | **Companion Neural AI** | Open companion app; run deep rephrase on 500-word paragraph | Neural SLM executes on device CPU/Metal safely. | ⚪ **Pending Mac Build** |

---

## 💻 Part 3: Windows Desktop Qualification & Toolchain Assessment

### Current Host Toolchain Status:
- **Rust Core DLL**: 🟢 **QUALIFIED & BUILT** (`appendix_core.dll`, 24.8 MB, 21 symbols exported).
- **Flutter Windows Runner**: 🔴 **BLOCKED ON WORKSTATION**
  - `where.exe cl`: Found at `C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64\cl.exe`.
  - `where.exe cmake`: Found at `C:\Users\Nurul Faiyaz\flutter\bin\cache\artifacts\engine\windows-x64\cmake\bin\cmake.exe`.
  - **Toolchain Blocker**: Flutter's `flutter build windows` invokes the `vswhere.exe` query for `Microsoft.VisualStudio.Workload.NativeDesktop` (Visual Studio IDE "Desktop development with C++"). The workstation has standalone BuildTools, not the full Visual Studio IDE setup.

### Required Steps to Complete Windows Desktop Application Packaging:
1. When authorized, install the **Desktop development with C++** workload in Visual Studio Installer:
   ```cmd
   vs_buildtools.exe --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended
   ```
2. Execute the release compilation:
   ```powershell
   cd app
   flutter pub get
   flutter build windows --release
   ```
3. Assemble the portable package:
   - Copy `app\build\windows\x64\runner\Release\*` to `dist\appendix-windows-x64\`.
   - Copy `dist\appendix_core.dll` directly alongside `appendix.exe`.
   - Compress to `dist\appendix-windows-x64.zip`.
4. Smoke test:
   - Extract zip to fresh folder.
   - Run `appendix.exe` and confirm editor renders and FFI checks pass.

