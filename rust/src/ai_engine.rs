use std::path::PathBuf;
use std::sync::{Mutex, RwLock};
use std::time::Instant;

use candle_core::quantized::gguf_file;
use candle_core::{Device, Tensor};
use candle_transformers::generation::{LogitsProcessor, Sampling};
use candle_transformers::models::quantized_qwen2::ModelWeights as Qwen2;
use once_cell::sync::Lazy;
use serde::{Deserialize, Serialize};
use tokenizers::Tokenizer;

use crate::ai_rephrase::{RewriteMode, RewriteResult};

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
        self.tokenizer.decode(tokens, true).map_err(|e| anyhow::anyhow!("{e}"))
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
        if text.len() > prev_text.len() && text.chars().last().map(|c| !c.is_control()).unwrap_or(false) {
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
    pub engine: String,
    pub uptime_seconds: u64,
}

static MODEL_HOLDER: Lazy<RwLock<Option<LoadedModel>>> = Lazy::new(|| RwLock::new(None));

pub struct AiEngine;

impl AiEngine {
    /// Load a GGUF model and tokenizer into memory.
    pub fn load_model(model_path: &str, tokenizer_path: &str) -> Result<ModelStatus, String> {
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

        let tokenizer = Tokenizer::from_file(&t_path)
            .map_err(|e| format!("Failed to parse tokenizer: {}", e))?;

        let mut file = std::fs::File::open(&m_path)
            .map_err(|e| format!("Failed to open GGUF model file: {}", e))?;

        let content = gguf_file::Content::read(&mut file)
            .map_err(|e| format!("Failed to parse GGUF headers: {}", e))?;

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

        let status = ModelStatus {
            loaded: true,
            model_name: filename,
            model_path: m_path.display().to_string(),
            tokenizer_path: t_path.display().to_string(),
            model_size_mb: model_size_bytes as f64 / (1024.0 * 1024.0),
            engine: "Qwen 2.5 Local Neural SLM (Candle Runtime)".to_string(),
            uptime_seconds: 0,
        };

        let mut lock = MODEL_HOLDER.write().map_err(|e| format!("Lock error: {}", e))?;
        *lock = Some(loaded);

        Ok(status)
    }

    /// Unload model from memory and immediately reclaim RAM.
    pub fn unload_model() -> Result<(), String> {
        let mut lock = MODEL_HOLDER.write().map_err(|e| format!("Lock error: {}", e))?;
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

    /// Get current model status.
    pub fn get_status() -> ModelStatus {
        if let Ok(lock) = MODEL_HOLDER.read() {
            if let Some(loaded) = lock.as_ref() {
                return ModelStatus {
                    loaded: true,
                    model_name: loaded.model_name.clone(),
                    model_path: loaded.model_path.display().to_string(),
                    tokenizer_path: loaded.tokenizer_path.display().to_string(),
                    model_size_mb: loaded.model_size_bytes as f64 / (1024.0 * 1024.0),
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
            engine: "None".to_string(),
            uptime_seconds: 0,
        }
    }

    /// Automatically find local model files in well-known standard locations.
    pub fn find_default_model_paths() -> Option<(PathBuf, PathBuf)> {
        let candidate_names = [
            "qwen2.5-0.5b-instruct-q4_k_m.gguf",
            "qwen2.5-0.5b-instruct-q4_0.gguf",
            "qwen2.5-1.5b-instruct-q4_k_m.gguf",
            "model.gguf",
        ];

        let search_dirs = [
            PathBuf::from("models"),
            PathBuf::from(r"c:\AA. Disks\Workstation\Project Typing App\models"),
            PathBuf::from("../models"),
            PathBuf::from("../../models"),
            PathBuf::from("../../../models"),
            std::env::current_exe()
                .ok()
                .and_then(|p| p.parent().map(|d| d.join("models")))
                .unwrap_or_else(|| PathBuf::from("models")),
        ];

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
                tokens_generated: Some(0),
                tokens_per_sec: Some(0.0),
                model_name: None,
                status: "success".to_string(),
                error_message: None,
            };
        }

        // Try to auto-load if not already loaded
        if !Self::is_loaded() {
            Self::auto_load_if_available();
        }

        let read_guard = match MODEL_HOLDER.read() {
            Ok(g) => g,
            Err(e) => {
                return RewriteResult {
                    original: text.to_string(),
                    revised: mode.heuristic_fallback(text),
                    mode: mode.title().to_string(),
                    engine: "Heuristic Fallback".to_string(),
                    latency_ms: None,
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
                    revised: mode.heuristic_fallback(text),
                    mode: mode.title().to_string(),
                    engine: "Heuristic Fallback".to_string(),
                    latency_ms: None,
                    tokens_generated: None,
                    tokens_per_sec: None,
                    model_name: None,
                    status: "model_not_found".to_string(),
                    error_message: Some(
                        "Local AI model is not loaded. Place qwen2.5-0.5b-instruct-q4_k_m.gguf in models/ directory."
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
                    revised: mode.heuristic_fallback(text),
                    mode: mode.title().to_string(),
                    engine: "Heuristic Fallback".to_string(),
                    latency_ms: None,
                    tokens_generated: None,
                    tokens_per_sec: None,
                    model_name: Some(loaded.model_name.clone()),
                    status: "mutex_error".to_string(),
                    error_message: Some(format!("Mutex error: {}", e)),
                };
            }
        };

        let mut tos = TokenOutputStream::new(loaded.tokenizer.clone());
        let prompt_str = mode.format_chatml_prompt(trimmed_input);

        let tokens = match tos.tokenizer().encode(prompt_str, true) {
            Ok(encoding) => encoding.get_ids().to_vec(),
            Err(e) => {
                return RewriteResult {
                    original: text.to_string(),
                    revised: mode.heuristic_fallback(text),
                    mode: mode.title().to_string(),
                    engine: "Heuristic Fallback".to_string(),
                    latency_ms: None,
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
        let start_infer = Instant::now();

        // Prefill / Prompt Processing
        let input = match Tensor::new(tokens.as_slice(), &loaded.device)
            .and_then(|t| t.unsqueeze(0))
        {
            Ok(tensor) => tensor,
            Err(e) => {
                return RewriteResult {
                    original: text.to_string(),
                    revised: mode.heuristic_fallback(text),
                    mode: mode.title().to_string(),
                    engine: "Heuristic Fallback".to_string(),
                    latency_ms: None,
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
                    revised: mode.heuristic_fallback(text),
                    mode: mode.title().to_string(),
                    engine: "Heuristic Fallback".to_string(),
                    latency_ms: None,
                    tokens_generated: None,
                    tokens_per_sec: None,
                    model_name: Some(loaded.model_name.clone()),
                    status: "inference_error".to_string(),
                    error_message: Some(format!("Forward pass error: {}", e)),
                };
            }
        };

        let mut next_token = match logits_processor.sample(&logits) {
            Ok(tok) => tok,
            Err(e) => {
                return RewriteResult {
                    original: text.to_string(),
                    revised: mode.heuristic_fallback(text),
                    mode: mode.title().to_string(),
                    engine: "Heuristic Fallback".to_string(),
                    latency_ms: None,
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
        for i in 0..token_limit {
            if next_token == eos_token {
                break;
            }
            let input = match Tensor::new(&[next_token], &loaded.device)
                .and_then(|t| t.unsqueeze(0))
            {
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

        let total_time = start_infer.elapsed();
        let total_sec = total_time.as_secs_f64();
        let latency_ms = total_sec * 1000.0;
        let num_tokens = generated_tokens.len();
        let tokens_per_sec = if total_sec > 0.0 {
            num_tokens as f64 / total_sec
        } else {
            0.0
        };

        // Post-process generated string: strip quotes, trim markers
        let cleaned = clean_ai_output(&output_str);

        RewriteResult {
            original: text.to_string(),
            revised: cleaned,
            mode: mode.title().to_string(),
            engine: "Qwen 2.5 0.5B Neural (Local GGUF)".to_string(),
            latency_ms: Some(latency_ms),
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

    // Strip leading conversational phrases if any slipped through
    let prefixes = [
        "Here is the rewritten text:",
        "Here's the rewritten text:",
        "Rewritten text:",
        "Here is the revised sentence:",
        "Here's the revised sentence:",
        "Revised sentence:",
        "Sure, here is the text:",
        "Sure, here's the text:",
    ];

    for prefix in prefixes {
        if s.to_lowercase().starts_with(&prefix.to_lowercase()) {
            s = s[prefix.len()..].trim();
        }
    }

    // Strip wrapping quotes
    if (s.starts_with('"') && s.ends_with('"')) || (s.starts_with('\'') && s.ends_with('\'')) {
        if s.len() >= 2 {
            s = &s[1..s.len() - 1].trim();
        }
    }

    // Strip markdown code fences if wrapped
    if s.starts_with("```") && s.ends_with("```") {
        let lines: Vec<&str> = s.lines().collect();
        if lines.len() >= 2 {
            let inner = lines[1..lines.len() - 1].join("\n");
            return inner.trim().to_string();
        }
    }

    s.to_string()
}
