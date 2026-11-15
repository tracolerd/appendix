# Appendix — macOS Installation & User Guide

This guide describes how to install, configure, verify, and troubleshoot **Appendix** on Apple macOS.

---

## 💻 System Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| **Operating System** | macOS 12 Monterey or later | macOS 14 Sonoma or macOS 15 Sequoia |
| **Architecture** | Apple Silicon (M1/M2/M3/M4) or Intel x86_64 | Apple Silicon (Native ARM64) |
| **Memory (RAM)** | 4 GB Unified Memory | 8 GB+ Unified Memory |
| **Disk Space** | 250 MB for App Bundle | 1 GB+ (includes GGUF neural model) |

---

## 📦 Installation Steps

### Option A: Installing the Pre-built Application Bundle

1. Download `appendix-macos.zip` and `appendix-macos.sha256` from the [GitHub Releases](https://github.com/tracolerd/appendix/releases) page.
2. Verify the SHA-256 checksum in Terminal:
   ```bash
   shasum -a 256 appendix-macos.zip
   ```
   Confirm that the calculated hash matches the value in `appendix-macos.sha256`.
3. Unzip the archive:
   ```bash
   unzip appendix-macos.zip
   ```
4. Drag and drop `appendix.app` into your `/Applications` directory.

---

## 🛡️ Gatekeeper & Notarization Bypass

Because Appendix is an open-source, community-driven project and does not pay annual Apple Developer Program fees for notarization tickets, macOS Gatekeeper may display a warning on initial launch:

> *"appendix.app cannot be opened because the developer cannot be verified."*

### How to Open Safely:

#### Method 1: Right-Click Bypass (Recommended)
1. Open **Finder** and navigate to `/Applications`.
2. **Right-click** (or `Control` + Click) on `appendix.app`.
3. Select **Open** from the context menu.
4. In the dialog box that appears, click the **Open** button. macOS will save this exception permanently.

#### Method 2: Terminal Quarantine Removal
Alternatively, remove the quarantine attribute via Terminal:
```bash
xattr -cr /Applications/appendix.app
```

---

## ⚙️ Native Library Architecture

`appendix.app` bundles `libappendix_core.dylib` inside its framework/bundle directory:
- Compiled as a **Universal Binary** supporting both `arm64` (Apple Silicon) and `x86_64` (Intel) architectures via `lipo`.
- Contains the embedded **Harper 3.2.0** grammar engine, readability algorithms, and local rephrasing heuristics.

---

## 🧠 Local Neural AI Model Setup (Offline)

Appendix supports the offline **Qwen 2.5 0.5B Instruct** GGUF model:
1. Target directory:
   ```bash
   mkdir -p ~/Library/Application\ Support/appendix/models
   ```
2. Place `qwen2.5-0.5b-instruct-q4_k_m.gguf` inside:
   ```bash
   cp qwen2.5-0.5b-instruct-q4_k_m.gguf ~/Library/Application\ Support/appendix/models/
   ```
3. Checksum verification:
   ```bash
   shasum -a 256 ~/Library/Application\ Support/appendix/models/qwen2.5-0.5b-instruct-q4_k_m.gguf
   # Expected: 74a4da8c9fdbcd15bd1f6d01d621410d31c6fc00986f5eb687824e7b93d7a9db
   ```
4. If the model file is not present, Appendix operates normally using its instant rule-based heuristic rewriting engine.

---

## 🔨 Building from Source (macOS Host)

```bash
# 1. Compile Universal dylib & XCFramework
chmod +x scripts/build_apple.sh
./scripts/build_apple.sh

# 2. Build macOS Flutter Desktop
cd app
flutter pub get
flutter build macos --release
```

---

## 🔧 Troubleshooting

### 1. "App is damaged and can't be opened"
- **Cause**: macOS Gatekeeper quarantine flag applied to unnotarized downloaded zip.
- **Solution**: Run `sudo xattr -rd com.apple.quarantine /Applications/appendix.app`.

### 2. High CPU Usage during AI Rewriting
- **Cause**: Neural SLM inference on older Intel Core i5/i7 Macs without Apple Neural Engine / Metal acceleration.
- **Solution**: Select **Concise** or **Heuristic Rules** mode in the AI panel for immediate sub-millisecond rewriting.

