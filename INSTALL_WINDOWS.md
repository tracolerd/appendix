# Appendix — Windows Installation & User Guide

This guide describes how to install, configure, verify, and troubleshoot **Appendix** on Microsoft Windows.

---

## 💻 System Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| **Operating System** | Windows 10 (64-bit, Version 1903+) or Windows 11 | Windows 11 (64-bit, Latest Build) |
| **Architecture** | x86_64 (64-bit AMD/Intel) | x86_64 or ARM64 (via emulation/native) |
| **Processor** | Dual-core CPU with AVX2 support | Quad-core CPU or modern multi-core |
| **Memory (RAM)** | 4 GB RAM (Grammar & Heuristics only) | 8 GB+ RAM (when running Qwen 2.5 0.5B GGUF neural SLM) |
| **Storage** | 200 MB for Application + Core Engine | 1 GB+ (includes 491 MB GGUF neural model) |
| **C++ Runtime** | Microsoft Visual C++ 2015–2022 Redistributable (x64) | Latest VC++ Redistributable installed |

---

## 📦 Installation Options

### Option A: Portable Release Archive (Recommended)

1. Download the release archive `appendix-windows-x64.zip` and checksum file `appendix-windows-x64.sha256` from the [GitHub Releases](https://github.com/tracolerd/appendix/releases) page.
2. Verify the SHA-256 integrity of the archive before extracting:
   ```powershell
   Get-FileHash -Path .\appendix-windows-x64.zip -Algorithm SHA256
   ```
   Compare the output hash against `appendix-windows-x64.sha256`.
3. Extract `appendix-windows-x64.zip` to your preferred folder (for example, `C:\Program Files\Appendix` or `D:\Tools\Appendix`).
4. Ensure the native engine DLL `appendix_core.dll` is located **in the same directory** as `appendix.exe`.
5. Launch `appendix.exe`.

### Option B: Building from Source

If you have developer tools installed:
1. Ensure Rust toolchain (`stable-x86_64-pc-windows-msvc`), Flutter SDK (3.50+), and Visual Studio 2022 with the **Desktop development with C++** workload are installed.
2. Compile the Rust core DLL:
   ```powershell
   cd rust
   cargo build --release
   Copy-Item target\release\appendix_core.dll ..\app\appendix_core.dll
   Copy-Item target\release\appendix_core.dll ..\app\windows\appendix_core.dll
   ```
3. Compile the Flutter Windows Desktop application:
   ```powershell
   cd ..\app
   flutter pub get
   flutter build windows --release
   ```
4. Find the resulting executable in `app\build\windows\x64\runner\Release\`.

---

## 🧠 Local Neural AI Model Setup (100% Offline)

Appendix uses the compact and capable **Qwen 2.5 0.5B Instruct** model quantized in GGUF format (`qwen2.5-0.5b-instruct-q4_k_m.gguf`).

To enable offline neural rewriting:
1. Check `models/model_manifest.json` for the model specifications:
   - **Filename**: `qwen2.5-0.5b-instruct-q4_k_m.gguf`
   - **Size**: 491,400,032 bytes (~468.6 MB)
   - **SHA-256**: `74a4da8c9fdbcd15bd1f6d01d621410d31c6fc00986f5eb687824e7b93d7a9db`
2. Download or copy the model file to the local Appendix models directory:
   ```powershell
   $modelDir = "$env:APPDATA\appendix\models"
   New-Item -ItemType Directory -Force -Path $modelDir
   # Place qwen2.5-0.5b-instruct-q4_k_m.gguf inside $modelDir
   ```
3. Verify the checksum:
   ```powershell
   Get-FileHash -Path "$env:APPDATA\appendix\models\qwen2.5-0.5b-instruct-q4_k_m.gguf" -Algorithm SHA256
   ```
4. Within Appendix, navigate to **AI Assistant** settings and confirm the model status displays **Loaded (Local Qwen 2.5 0.5B)**.
   *Note: If no model file is loaded, Appendix automatically falls back to its built-in rule-based heuristic rewriting engine without interruption.*

---

## 🛡️ Security, SmartScreen & Antivirus Verification

- **Windows SmartScreen**: Because Appendix is community-built and not signed with an expensive Extended Validation (EV) code-signing certificate, Windows Defender SmartScreen may display:
  > *"Windows protected your PC — Microsoft Defender SmartScreen prevented an unrecognized app from starting."*
  - **Resolution**: Click **More info** and then click **Run anyway**.
- **Antivirus False Positives**: Rust-compiled native binaries and JIT runtimes can occasionally trigger heuristic false positives in generic anti-malware tools. Appendix is 100% open-source with reproducible builds; you can verify the SHA-256 hash or compile directly from source code.
- **Network Safety**: Appendix contains zero network code. The executable performs **0 outbound connections**. You can inspect its network activity via Sysinternals TCPView or Resource Monitor at any time.

---

## 🔧 Troubleshooting

### 1. `VCRUNTIME140.dll` or `MSVCP140.dll` Missing
- **Cause**: The Microsoft Visual C++ Redistributable is missing on your machine.
- **Solution**: Download and install the official Microsoft Visual C++ 2015–2022 Redistributable (x64) from [Microsoft's official site](https://aka.ms/vs/17/release/vc_redist.x64.exe).

### 2. `appendix_core.dll` Not Found / Dynamic Link Failure
- **Cause**: The native Rust DLL is missing or not in the same folder as `appendix.exe`.
- **Solution**: Ensure `appendix_core.dll` is located directly beside `appendix.exe` in the application root directory.

### 3. High Memory Usage or Out-of-Memory during AI Inference
- **Cause**: Systems with less than 6 GB available RAM may struggle when loading the neural GGUF model into memory.
- **Solution**: Switch the AI mode to **Heuristic Rules** in the settings panel, or ensure other memory-heavy applications are closed during local inference.

