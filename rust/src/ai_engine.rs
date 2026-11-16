use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Mutex, RwLock};
use std::time::Instant;

use candle_core::quantized::gguf_file;
use candle_core::{Device, Tensor};
use candle_transformers::generation::{LogitsProcessor, Sampling};
use candle_transformers::models::quantized_qwen2::ModelWeights as Qwen2;
use once_cell::sync::Lazy;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use tokenizers::Tokenizer;

use crate::ai_rephrase::{RewriteMode, RewriteResult};

pub const KNOWN_QWEN_05B_SHA256: &str =
    "74a4da8c9fdbcd15bd1f6d01d621410d31c6fc00986f5eb687824e7b93d7a9db";
pub const KNOWN_TOKENIZER_SHA256: &str =
    "c0382117ea329cdf097041132f6d735924b697924d6f6fc3945713e96ce87539";

static CANCEL_REQUESTED: AtomicBool = AtomicBool::new(false);
static AUTO_LOAD_ALLOWED: AtomicBool = AtomicBool::new(true);

pub struct TokenOutputStream {
    tokenizer: Tokenizer,
    tokens: Vec<u32>,
    prev_index: usize,
    current_index: usize,
}

impl TokenOutputStream {
    pub fn new(tokenizer: Tokenizer) -> Self {
        Self {
            tokenizer,
            tokens: Vec::new(),
            prev_index: 0,
            current_index: 0,
        }
    }

    fn decode(&self, tokens: &[u32]) -> anyhow::Result<String> {
        self.tokenizer
            .decode(tokens, true)
            .map_err(|e| anyhow::anyhow!("{e}"))
    }

    pub fn next_token(&mut self, token: u32) -> anyhow::Result<Option<String>> {
        let prev_text = if self.tokens.is_empty() {
            String::new()
        } else {
            let tokens = &self.tokens[self.prev_index..self.current_index];
            self.decode(tokens)?
        };
        self.tokens.push(token);
        let text = self.decode(&self.tokens[self.prev_index..])?;
        if text.len() > prev_text.len()
            && text
                .chars()
                .last()
                .map(|c| !c.is_control())
                .unwrap_or(false)
        {
            let text = text.split_at(prev_text.len());
            self.prev_index = self.current_index;
            self.current_index = self.tokens.len();
            Ok(Some(text.1.to_string()))
        } else {
            Ok(None)
        }
    }

    pub fn decode_rest(&self) -> anyhow::Result<Option<String>> {
        let prev_text = if self.tokens.is_empty() {
            String::new()
        } else {
            let tokens = &self.tokens[self.prev_index..self.current_index];
            self.decode(tokens)?
        };
        let text = self.decode(&self.tokens[self.prev_index..])?;
        if text.len() > prev_text.len() {
            let text = text.split_at(prev_text.len());
            Ok(Some(text.1.to_string()))
        } else {
            Ok(None)
        }
    }

    pub fn clear(&mut self) {
        self.tokens.clear();
        self.prev_index = 0;
        self.current_index = 0;
    }

    pub fn tokenizer(&self) -> &Tokenizer {
        &self.tokenizer
    }
}

pub struct LoadedModel {
    model: Mutex<Qwen2>,
    tokenizer: Tokenizer,
    device: Device,
    model_path: PathBuf,
    tokenizer_path: PathBuf,
    model_name: String,
    model_size_bytes: usize,
    loaded_at: Instant,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelStatus {
    pub loaded: bool,
    pub model_name: String,
    pub model_path: String,
    pub tokenizer_path: String,
    pub model_size_mb: f64,
    pub file_size_mb: f64,
    pub ram_working_set_mb: Option<f64>,
    pub ram_peak_mb: Option<f64>,
    pub ram_measured: bool,
    pub engine: String,
    pub uptime_seconds: u64,
}

static MODEL_HOLDER: Lazy<RwLock<Option<LoadedModel>>> = Lazy::new(|| RwLock::new(None));

/// Query Windows OS kernel for actual process working set and peak RAM consumption.
#[cfg(target_os = "windows")]
pub fn get_process_memory_mb() -> (Option<f64>, Option<f64>, bool) {
    #[repr(C)]
    #[allow(non_snake_case)]
    struct PROCESS_MEMORY_COUNTERS {
        cb: u32,
        PageFaultCount: u32,
        PeakWorkingSetSize: usize,
        WorkingSetSize: usize,
        QuotaPeakPagedPoolUsage: usize,
        QuotaPagedPoolUsage: usize,
        QuotaPeakNonPagedPoolUsage: usize,
        QuotaNonPagedPoolUsage: usize,
        PagefileUsage: usize,
        PeakPagefileUsage: usize,
    }
    extern "system" {
        fn GetCurrentProcess() -> isize;
        fn K32GetProcessMemoryInfo(
            hProcess: isize,
            ppsmemCounters: *mut PROCESS_MEMORY_COUNTERS,
            cb: u32,
        ) -> i32;
    }
    unsafe {
        let mut pmc: PROCESS_MEMORY_COUNTERS = std::mem::zeroed();
        pmc.cb = std::mem::size_of::<PROCESS_MEMORY_COUNTERS>() as u32;
        if K32GetProcessMemoryInfo(GetCurrentProcess(), &mut pmc, pmc.cb) != 0 {
            let ws_mb = pmc.WorkingSetSize as f64 / (1024.0 * 1024.0);
            let peak_mb = pmc.PeakWorkingSetSize as f64 / (1024.0 * 1024.0);
            (Some(ws_mb), Some(peak_mb), true)
        } else {
            (None, None, false)
        }
    }
}

#[cfg(not(target_os = "windows"))]
pub fn get_process_memory_mb() -> (Option<f64>, Option<f64>, bool) {
    (None, None, false)
}

/// Compute cryptographic SHA-256 hash using streaming buffer (memory efficient).
pub fn compute_file_sha256(path: &Path) -> Result<String, String> {
    use std::io::Read;

    let mut file = std::fs::File::open(path).map_err(|e| {
        format!(
            "Failed to open file for SHA-256 check {}: {}",
            path.display(),
            e
        )
    })?;
    let mut hasher = Sha256::new();
    let mut buffer = [0u8; 1024 * 1024]; // 1MB buffer

    loop {
        let bytes_read = file
            .read(&mut buffer)
            .map_err(|e| format!("Read error during hashing {}: {}", path.display(), e))?;
        if bytes_read == 0 {
            break;
        }
        hasher.update(&buffer[..bytes_read]);
    }

    Ok(format!("{:x}", hasher.finalize()))
}

pub struct AiEngine;

impl AiEngine {
    /// Signal the inference loop to abort immediately at the next token boundary.
    pub fn cancel_inference() {
        CANCEL_REQUESTED.store(true, Ordering::SeqCst);
    }

    /// Verify a file's SHA-256 checksum against an expected hex string.
    pub fn verify_file_checksum(file_path: &str, expected_sha256: &str) -> Result<bool, String> {
        let path = PathBuf::from(file_path);
        if !path.exists() {
            return Err(format!("File does not exist: {}", file_path));
        }
        let computed = compute_file_sha256(&path)?;
        Ok(computed.eq_ignore_ascii_case(expected_sha256.trim()))
    }

    /// Load a GGUF model and tokenizer into memory with optional cryptographic integrity check.
    pub fn load_model(
        model_path: &str,
        tokenizer_path: &str,
        verify_checksum: bool,
    ) -> Result<ModelStatus, String> {
        let m_path = PathBuf::from(model_path);
        let t_path = PathBuf::from(tokenizer_path);

        if !m_path.exists() {
            return Err(format!("Model file not found at: {}", model_path));
        }
        if !t_path.exists() {
            return Err(format!("Tokenizer file not found at: {}", tokenizer_path));
        }

        let model_size_bytes = std::fs::metadata(&m_path)
            .map(|m| m.len() as usize)
            .unwrap_or(0);

        if model_size_bytes == 0 {
            return Err(format!(
                "Corrupted model file: size is 0 bytes at {}",
                model_path
            ));
        }

        let tokenizer_size_bytes = std::fs::metadata(&t_path)
            .map(|m| m.len() as usize)
            .unwrap_or(0);

        if tokenizer_size_bytes == 0 {
            return Err(format!(
                "Corrupted tokenizer file: size is 0 bytes at {}",
                tokenizer_path
            ));
        }

        // Cryptographic integrity verification
        if verify_checksum {
            let filename = m_path.file_name().and_then(|f| f.to_str()).unwrap_or("");
            if filename.contains("qwen2.5-0.5b-instruct-q4_k_m") {
                let computed_hash = compute_file_sha256(&m_path)?;
                if !computed_hash.eq_ignore_ascii_case(KNOWN_QWEN_05B_SHA256) {
                    return Err(format!(
                        "Model integrity check failed! Expected SHA-256: {}, computed: {}",
                        KNOWN_QWEN_05B_SHA256, computed_hash
                    ));
                }
            }

            let tok_filename = t_path.file_name().and_then(|f| f.to_str()).unwrap_or("");
            if tok_filename == "tokenizer.json" {
                let computed_tok_hash = compute_file_sha256(&t_path)?;
                if !computed_tok_hash.eq_ignore_ascii_case(KNOWN_TOKENIZER_SHA256) {
                    return Err(format!(
                        "Tokenizer integrity check failed! Expected SHA-256: {}, computed: {}",
                        KNOWN_TOKENIZER_SHA256, computed_tok_hash
                    ));
                }
            }
        }

        let tokenizer = Tokenizer::from_file(&t_path)
            .map_err(|e| format!("Failed to parse tokenizer: {}", e))?;

        let mut file = std::fs::File::open(&m_path)
            .map_err(|e| format!("Failed to open GGUF model file: {}", e))?;

        let content = gguf_file::Content::read(&mut file).map_err(|e| {
            format!(
                "Failed to parse GGUF headers (file may be corrupted): {}",
                e
            )
        })?;

        let device = Device::Cpu;
        let model = Qwen2::from_gguf(content, &mut file, &device)
            .map_err(|e| format!("Failed to construct Qwen2 model from weights: {}", e))?;

        let filename = m_path
            .file_name()
            .map(|f| f.to_string_lossy().to_string())
            .unwrap_or_else(|| "Qwen2.5-GGUF".to_string());

        let loaded = LoadedModel {
            model: Mutex::new(model),
            tokenizer,
            device,
            model_path: m_path.clone(),
            tokenizer_path: t_path.clone(),
            model_name: filename.clone(),
            model_size_bytes,
            loaded_at: Instant::now(),
        };

        let file_mb = model_size_bytes as f64 / (1024.0 * 1024.0);
        let (ram_ws, ram_peak, measured) = get_process_memory_mb();

        let status = ModelStatus {
            loaded: true,
            model_name: filename,
            model_path: m_path.display().to_string(),
            tokenizer_path: t_path.display().to_string(),
            model_size_mb: file_mb,
            file_size_mb: file_mb,
            ram_working_set_mb: ram_ws,
            ram_peak_mb: ram_peak,
            ram_measured: measured,
            engine: "Qwen 2.5 Local Neural SLM (Candle Runtime)".to_string(),
            uptime_seconds: 0,
        };

        let mut lock = MODEL_HOLDER
            .write()
            .map_err(|e| format!("Lock error: {}", e))?;
        *lock = Some(loaded);
        AUTO_LOAD_ALLOWED.store(true, Ordering::SeqCst);

        Ok(status)
    }

    /// Unload model from memory and immediately reclaim RAM.
    pub fn unload_model() -> Result<(), String> {
        AUTO_LOAD_ALLOWED.store(false, Ordering::SeqCst);
        let mut lock = MODEL_HOLDER
            .write()
            .map_err(|e| format!("Lock error: {}", e))?;
        *lock = None;
        Ok(())
    }

    /// Check if a model is currently loaded in memory.
    pub fn is_loaded() -> bool {
        if let Ok(lock) = MODEL_HOLDER.read() {
            lock.is_some()
        } else {
            false
        }
    }

    /// Get current model status with live OS RAM working set statistics.
    pub fn get_status() -> ModelStatus {
        let (ram_ws, ram_peak, measured) = get_process_memory_mb();

        if let Ok(lock) = MODEL_HOLDER.read() {
            if let Some(loaded) = lock.as_ref() {
                let file_mb = loaded.model_size_bytes as f64 / (1024.0 * 1024.0);
                return ModelStatus {
                    loaded: true,
                    model_name: loaded.model_name.clone(),
                    model_path: loaded.model_path.display().to_string(),
                    tokenizer_path: loaded.tokenizer_path.display().to_string(),
                    model_size_mb: file_mb,
                    file_size_mb: file_mb,
                    ram_working_set_mb: ram_ws,
                    ram_peak_mb: ram_peak,
                    ram_measured: measured,
                    engine: "Qwen 2.5 Local Neural SLM (Candle Runtime)".to_string(),
                    uptime_seconds: loaded.loaded_at.elapsed().as_secs(),
                };
            }
        }

        ModelStatus {
            loaded: false,
            model_name: String::new(),
            model_path: String::new(),
            tokenizer_path: String::new(),
            model_size_mb: 0.0,
            file_size_mb: 0.0,
            ram_working_set_mb: ram_ws,
            ram_peak_mb: ram_peak,
            ram_measured: measured,
            engine: "None".to_string(),
            uptime_seconds: 0,
        }
    }

    /// Automatically find local model files in well-known standard locations without hardcoded personal paths.
    pub fn find_default_model_paths() -> Option<(PathBuf, PathBuf)> {
        let candidate_names = [
            "qwen2.5-0.5b-instruct-q4_k_m.gguf",
            "qwen2.5-0.5b-instruct-q4_0.gguf",
            "qwen2.5-1.5b-instruct-q4_k_m.gguf",
            "model.gguf",
        ];

        let mut search_dirs = Vec::new();

        // 1. Environment variable if user/system configured
        if let Ok(env_path) = std::env::var("APPENDIX_MODELS_DIR") {
            search_dirs.push(PathBuf::from(env_path));
        }

        // 2. Relative models directory in current working dir
        search_dirs.push(PathBuf::from("models"));

        // 3. Parent models directories (e.g. running from rust/ or app/)
        search_dirs.push(PathBuf::from("../models"));
        search_dirs.push(PathBuf::from("../../models"));

        // 4. Executable-adjacent models directory (packaged standalone desktop app)
        if let Ok(exe_path) = std::env::current_exe() {
            if let Some(exe_dir) = exe_path.parent() {
                search_dirs.push(exe_dir.join("models"));
                search_dirs.push(exe_dir.join("data").join("models"));
            }
        }

        for dir in &search_dirs {
            let tokenizer = dir.join("tokenizer.json");
            if tokenizer.exists() {
                for name in &candidate_names {
                    let model = dir.join(name);
                    if model.exists() {
                        return Some((model, tokenizer));
                    }
                }
            }
        }

        None
    }

    /// Auto-load model if found on disk and not already in memory.
    pub fn auto_load_if_available() -> bool {
        if Self::is_loaded() {
            return true;
        }

        if let Some((model_path, tokenizer_path)) = Self::find_default_model_paths() {
            if let Ok(_) = Self::load_model(
                &model_path.to_string_lossy(),
                &tokenizer_path.to_string_lossy(),
                false, // Fast auto-load (explicit verify can be called on demand)
            ) {
                return true;
            }
        }

        false
    }

    /// Perform neural rewriting on the input text.
    pub fn rewrite(text: &str, mode: RewriteMode, max_tokens: Option<usize>) -> RewriteResult {
        let trimmed_input = text.trim();
        if trimmed_input.is_empty() {
            return RewriteResult {
                original: text.to_string(),
                revised: String::new(),
                mode: mode.title().to_string(),
                engine: "Qwen 2.5 Local Neural SLM".to_string(),
                latency_ms: Some(0.0),
                prompt_eval_ms: Some(0.0),
                token_eval_ms: Some(0.0),
                tokens_generated: Some(0),
                tokens_per_sec: Some(0.0),
                model_name: None,
                status: "success".to_string(),
                error_message: None,
            };
        }

        // Try to auto-load if not already loaded and not explicitly unloaded
        if !Self::is_loaded() && AUTO_LOAD_ALLOWED.load(Ordering::Relaxed) {
            Self::auto_load_if_available();
        }

        let read_guard = match MODEL_HOLDER.read() {
            Ok(g) => g,
            Err(e) => {
                return RewriteResult {
                    original: text.to_string(),
                    revised: String::new(),
                    mode: mode.title().to_string(),
                    engine: "None".to_string(),
                    latency_ms: None,
                    prompt_eval_ms: None,
                    token_eval_ms: None,
                    tokens_generated: None,
                    tokens_per_sec: None,
                    model_name: None,
                    status: "lock_error".to_string(),
                    error_message: Some(format!("Model lock error: {}", e)),
                };
            }
        };

        let loaded = match read_guard.as_ref() {
            Some(m) => m,
            None => {
                return RewriteResult {
                    original: text.to_string(),
                    revised: String::new(),
                    mode: mode.title().to_string(),
                    engine: "None".to_string(),
                    latency_ms: None,
                    prompt_eval_ms: None,
                    token_eval_ms: None,
                    tokens_generated: None,
                    tokens_per_sec: None,
                    model_name: None,
                    status: "model_not_loaded".to_string(),
                    error_message: Some(
                        "Local AI model is not loaded. Please download and load Qwen 2.5 0.5B GGUF first."
                            .to_string(),
                    ),
                };
            }
        };

        let mut model_lock = match loaded.model.lock() {
            Ok(m) => m,
            Err(e) => {
                return RewriteResult {
                    original: text.to_string(),
                    revised: String::new(),
                    mode: mode.title().to_string(),
                    engine: "None".to_string(),
                    latency_ms: None,
                    prompt_eval_ms: None,
                    token_eval_ms: None,
                    tokens_generated: None,
                    tokens_per_sec: None,
                    model_name: Some(loaded.model_name.clone()),
                    status: "mutex_error".to_string(),
                    error_message: Some(format!("Mutex error: {}", e)),
                };
            }
        };

        // Check if cancellation was already requested before starting inference
        if CANCEL_REQUESTED.swap(false, Ordering::SeqCst) {
            return RewriteResult {
                original: text.to_string(),
                revised: String::new(),
                mode: mode.title().to_string(),
                engine: "Qwen 2.5 0.5B Neural (Cancelled)".to_string(),
                latency_ms: Some(0.0),
                prompt_eval_ms: Some(0.0),
                token_eval_ms: Some(0.0),
                tokens_generated: Some(0),
                tokens_per_sec: Some(0.0),
                model_name: Some(loaded.model_name.clone()),
                status: "cancelled".to_string(),
                error_message: Some("Inference was cancelled by user".to_string()),
            };
        }

        let mut tos = TokenOutputStream::new(loaded.tokenizer.clone());
        let prompt_str = mode.format_chatml_prompt(trimmed_input);

        let tokens = match tos.tokenizer().encode(prompt_str, true) {
            Ok(encoding) => encoding.get_ids().to_vec(),
            Err(e) => {
                return RewriteResult {
                    original: text.to_string(),
                    revised: String::new(),
                    mode: mode.title().to_string(),
                    engine: "None".to_string(),
                    latency_ms: None,
                    prompt_eval_ms: None,
                    token_eval_ms: None,
                    tokens_generated: None,
                    tokens_per_sec: None,
                    model_name: Some(loaded.model_name.clone()),
                    status: "tokenization_error".to_string(),
                    error_message: Some(format!("Tokenizer error: {}", e)),
                };
            }
        };

        let eos_token = tos
            .tokenizer()
            .get_vocab(true)
            .get("<|im_end|>")
            .copied()
            .unwrap_or(151645);

        let mut logits_processor = LogitsProcessor::from_sampling(42, Sampling::ArgMax);
        let start_total = Instant::now();

        // 1. Prefill / Prompt Processing Phase
        let start_prefill = Instant::now();
        let input =
            match Tensor::new(tokens.as_slice(), &loaded.device).and_then(|t| t.unsqueeze(0)) {
                Ok(tensor) => tensor,
                Err(e) => {
                    return RewriteResult {
                        original: text.to_string(),
                        revised: String::new(),
                        mode: mode.title().to_string(),
                        engine: "None".to_string(),
                        latency_ms: None,
                        prompt_eval_ms: None,
                        token_eval_ms: None,
                        tokens_generated: None,
                        tokens_per_sec: None,
                        model_name: Some(loaded.model_name.clone()),
                        status: "tensor_error".to_string(),
                        error_message: Some(format!("Tensor creation error: {}", e)),
                    };
                }
            };

        let logits = match model_lock.forward(&input, 0).and_then(|l| l.squeeze(0)) {
            Ok(logits) => logits,
            Err(e) => {
                return RewriteResult {
                    original: text.to_string(),
                    revised: String::new(),
                    mode: mode.title().to_string(),
                    engine: "None".to_string(),
                    latency_ms: None,
                    prompt_eval_ms: None,
                    token_eval_ms: None,
                    tokens_generated: None,
                    tokens_per_sec: None,
                    model_name: Some(loaded.model_name.clone()),
                    status: "inference_error".to_string(),
                    error_message: Some(format!("Forward pass error: {}", e)),
                };
            }
        };
        let prompt_eval_ms = start_prefill.elapsed().as_secs_f64() * 1000.0;

        // 2. Token Generation Phase
        let start_generation = Instant::now();
        let mut next_token = match logits_processor.sample(&logits) {
            Ok(tok) => tok,
            Err(e) => {
                return RewriteResult {
                    original: text.to_string(),
                    revised: String::new(),
                    mode: mode.title().to_string(),
                    engine: "None".to_string(),
                    latency_ms: None,
                    prompt_eval_ms: Some(prompt_eval_ms),
                    token_eval_ms: None,
                    tokens_generated: None,
                    tokens_per_sec: None,
                    model_name: Some(loaded.model_name.clone()),
                    status: "sampling_error".to_string(),
                    error_message: Some(format!("Sampling error: {}", e)),
                };
            }
        };

        let mut generated_tokens = vec![next_token];
        let mut output_str = String::new();
        if let Ok(Some(t)) = tos.next_token(next_token) {
            output_str.push_str(&t);
        }

        let token_limit = max_tokens.unwrap_or(80);
        let mut was_cancelled = false;

        for i in 0..token_limit {
            // Check cancellation request at each token boundary
            if CANCEL_REQUESTED.load(Ordering::Relaxed) {
                was_cancelled = true;
                CANCEL_REQUESTED.store(false, Ordering::SeqCst);
                break;
            }

            if next_token == eos_token {
                break;
            }
            let input =
                match Tensor::new(&[next_token], &loaded.device).and_then(|t| t.unsqueeze(0)) {
                    Ok(t) => t,
                    Err(_) => break,
                };

            let logits = match model_lock
                .forward(&input, tokens.len() + i)
                .and_then(|l| l.squeeze(0))
            {
                Ok(l) => l,
                Err(_) => break,
            };

            // Apply repetition penalty if needed
            let logits = if generated_tokens.len() > 1 {
                let start_at = generated_tokens.len().saturating_sub(32);
                candle_transformers::utils::apply_repeat_penalty(
                    &logits,
                    1.1,
                    &generated_tokens[start_at..],
                )
                .unwrap_or(logits)
            } else {
                logits
            };

            next_token = match logits_processor.sample(&logits) {
                Ok(tok) => tok,
                Err(_) => break,
            };

            generated_tokens.push(next_token);
            if let Ok(Some(t)) = tos.next_token(next_token) {
                output_str.push_str(&t);
            }
        }

        if let Ok(Some(rest)) = tos.decode_rest() {
            output_str.push_str(&rest);
        }

        let token_eval_sec = start_generation.elapsed().as_secs_f64();
        let token_eval_ms = token_eval_sec * 1000.0;
        let total_latency_ms = start_total.elapsed().as_secs_f64() * 1000.0;

        let num_tokens = generated_tokens.len();
        let tokens_per_sec = if token_eval_sec > 0.0 {
            num_tokens as f64 / token_eval_sec
        } else {
            0.0
        };

        // Post-process generated string: strip quotes, trim markers
        let cleaned = clean_ai_output(&output_str);

        if was_cancelled {
            return RewriteResult {
                original: text.to_string(),
                revised: cleaned,
                mode: mode.title().to_string(),
                engine: "Qwen 2.5 0.5B Neural (Cancelled)".to_string(),
                latency_ms: Some(total_latency_ms),
                prompt_eval_ms: Some(prompt_eval_ms),
                token_eval_ms: Some(token_eval_ms),
                tokens_generated: Some(num_tokens),
                tokens_per_sec: Some(tokens_per_sec),
                model_name: Some(loaded.model_name.clone()),
                status: "cancelled".to_string(),
                error_message: Some("Inference was cancelled by user".to_string()),
            };
        }

        if cleaned.is_empty() {
            return RewriteResult {
                original: text.to_string(),
                revised: String::new(),
                mode: mode.title().to_string(),
                engine: "Qwen 2.5 0.5B Neural (Local GGUF)".to_string(),
                latency_ms: Some(total_latency_ms),
                prompt_eval_ms: Some(prompt_eval_ms),
                token_eval_ms: Some(token_eval_ms),
                tokens_generated: Some(num_tokens),
                tokens_per_sec: Some(tokens_per_sec),
                model_name: Some(loaded.model_name.clone()),
                status: "empty_output".to_string(),
                error_message: Some("Model returned an empty response".to_string()),
            };
        }

        RewriteResult {
            original: text.to_string(),
            revised: cleaned,
            mode: mode.title().to_string(),
            engine: "Qwen 2.5 0.5B Neural (Local GGUF)".to_string(),
            latency_ms: Some(total_latency_ms),
            prompt_eval_ms: Some(prompt_eval_ms),
            token_eval_ms: Some(token_eval_ms),
            tokens_generated: Some(num_tokens),
            tokens_per_sec: Some(tokens_per_sec),
            model_name: Some(loaded.model_name.clone()),
            status: "success".to_string(),
            error_message: None,
        }
    }
}

/// Clean generated output to ensure zero conversational artifacts.
fn clean_ai_output(raw: &str) -> String {
    let mut s = raw.trim();

    // Strip ChatML tags if any leaked
    if let Some(pos) = s.find("<|im_end|>") {
        s = &s[..pos];
    }
    if let Some(pos) = s.find("<|im_start|>") {
        s = &s[..pos];
    }

    s = s.trim();

    // Strip leading "Passive:" or "Active:" if model mirrored the prompt label
    if s.starts_with("Passive:") || s.starts_with("passive:") {
        s = s[8..].trim();
    } else if s.starts_with("Active:") || s.starts_with("active:") {
        s = s[7..].trim();
    }

    // Strip enclosing quotes if model added them
    if (s.starts_with('"') && s.ends_with('"') && s.len() >= 2)
        || (s.starts_with('\'') && s.ends_with('\'') && s.len() >= 2)
    {
        s = &s[1..s.len() - 1].trim();
    }

    s.to_string()
}
