# Local AI Models for Appendix

Appendix is designed from the ground up to run Small Language Models (SLMs) completely offline.

## Privacy & Security Guarantee

- **Zero Cloud Calls**: Models execute strictly on local CPU / GPU hardware.
- **No Analytics / Telemetry**: Prompt text never leaves your device.
- **Open-Weights**: All recommended models use the permissive Apache 2.0 license.

## Supported Format: GGUF

Appendix uses the industry-standard **GGUF** format (`llama.cpp`), which enables fast quantized inference on standard consumer CPUs without requiring discrete high-end GPUs.

## Available Model Profiles

| Model | Parameters | Quantization | Size | Minimum RAM | Target Hardware |
|---|---|---|---|---|---|
| **Qwen 2.5 0.5B Instruct** | 0.49B | `Q4_K_M` | ~380 MB | 800 MB | Mobile, Laptops, Low-spec PCs |
| **Qwen 2.5 1.5B Instruct** | 1.54B | `Q4_K_M` | ~940 MB | 1.8 GB | Standard Desktop, Fast Rewriting |
| **Qwen 2.5 3B Instruct** | 3.09B | `Q4_K_M` | ~1.85 GB | 3.5 GB | High-spec Desktop (8GB+ RAM) |

## Manual Model Installation

If you prefer to download the model file yourself:
1. Download any `.gguf` file from the [Qwen HuggingFace repository](https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF).
2. Place the file inside the `models/` directory or import it directly inside the Appendix application settings.
3. The app will immediately detect the local file and switch to on-device AI inference.
