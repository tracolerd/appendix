# Local AI Models for Appendix

Appendix is designed from the ground up to run Small Language Models (SLMs) completely offline.

## Privacy & Security Guarantee

- **Zero Cloud Calls**: Models execute strictly on local CPU hardware via the pure-Rust Hugging Face `candle` inference engine.
- **No Analytics / Telemetry**: Prompt text never leaves your device.
- **Open-Weights**: All recommended models use the permissive Apache 2.0 license.

## Supported Format: GGUF

Appendix uses quantized **GGUF** models, enabling fast inference on standard consumer CPUs without requiring discrete GPUs.

## Recommended Model: Qwen 2.5 0.5B Instruct (Q4_K_M)

- **Model File**: `qwen2.5-0.5b-instruct-q4_k_m.gguf` (491,400,032 bytes)
- **SHA-256**: `74a4da8c9fdbcd15bd1f6d01d621410d31c6fc00986f5eb687824e7b93d7a9db`
- **Tokenizer**: `tokenizer.json` (7,031,645 bytes)
- **SHA-256**: `c0382117ea329cdf097041132f6d735924b697924d6f6fc3945713e96ce87539`
- **RAM Requirement**: ~800 MB active footprint
- **Speed**: ~5.8 to ~7.5 tokens/sec on modern 8-core CPU

## Manual Installation Guide

To install the model manually:

1. Download the quantized model from Hugging Face:
   ```bash
   curl -L -o models/qwen2.5-0.5b-instruct-q4_k_m.gguf \
     https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf
   ```
2. Download the official tokenizer:
   ```bash
   curl -L -o models/tokenizer.json \
     https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct/raw/main/tokenizer.json
   ```
3. Place both files in the `models/` directory of the application.
4. Launch Appendix. The application will detect the model automatically and activate the green **Neural AI** indicator.
