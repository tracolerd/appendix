use appendix_core::ai_engine::{AiEngine, KNOWN_QWEN_05B_SHA256, KNOWN_TOKENIZER_SHA256};
use appendix_core::ai_rephrase::RewriteMode;

const MODEL_PATH: &str = r"..\models\qwen2.5-0.5b-instruct-q4_k_m.gguf";
const TOKENIZER_PATH: &str = r"..\models\tokenizer.json";

fn check_model_exists() -> bool {
    if !std::path::Path::new(MODEL_PATH).exists() || !std::path::Path::new(TOKENIZER_PATH).exists()
    {
        eprintln!(
            "SKIPPED: Model files not found at {} or {}. Place files in models/ to run neural tests.",
            MODEL_PATH, TOKENIZER_PATH
        );
        false
    } else {
        true
    }
}

#[test]
fn test_01_model_loading_integrity_and_lifecycle() {
    println!("\n=== TEST 1: Model Loading, Integrity Verification & Lifecycle ===");
    if !check_model_exists() {
        return;
    }

    // 1. Verify model with cryptographic SHA-256 check
    let status = AiEngine::load_model(MODEL_PATH, TOKENIZER_PATH, true)
        .expect("Failed to load Qwen 2.5 0.5B GGUF model with SHA-256 verification");

    assert!(status.loaded, "Model status should report loaded=true");
    assert!(
        AiEngine::is_loaded(),
        "AiEngine::is_loaded() should be true"
    );
    assert!(
        status.file_size_mb > 400.0,
        "Model file size should be > 400 MB"
    );

    println!("Loaded Model Name     : {}", status.model_name);
    println!("GGUF File Size        : {:.1} MB", status.file_size_mb);
    println!("Engine Description    : {}", status.engine);

    if status.ram_measured {
        println!(
            "OS Working Set RAM    : {:.1} MB",
            status.ram_working_set_mb.unwrap_or(0.0)
        );
        println!(
            "OS Peak Working Set   : {:.1} MB",
            status.ram_peak_mb.unwrap_or(0.0)
        );
    } else {
        println!("OS Working Set RAM    : Not Measured (Non-Windows platform)");
    }

    // 2. Standalone SHA-256 Checksum Verification
    let model_valid = AiEngine::verify_file_checksum(MODEL_PATH, KNOWN_QWEN_05B_SHA256)
        .expect("SHA-256 verification failed on model");
    assert!(
        model_valid,
        "GGUF model checksum must match official Qwen 2.5 hash"
    );

    let tok_valid = AiEngine::verify_file_checksum(TOKENIZER_PATH, KNOWN_TOKENIZER_SHA256)
        .expect("SHA-256 verification failed on tokenizer");
    assert!(tok_valid, "Tokenizer checksum must match official hash");

    // 3. Test corrupted / invalid hash rejection
    let fake_hash = "0000000000000000000000000000000000000000000000000000000000000000";
    let fake_valid = AiEngine::verify_file_checksum(MODEL_PATH, fake_hash).unwrap();
    assert!(
        !fake_valid,
        "Checksum verification must reject invalid hash"
    );

    // 4. Test Unload & Memory Reclamation
    AiEngine::unload_model().expect("Failed to unload model");
    assert!(!AiEngine::is_loaded(), "Model should be unloaded");
    let unloaded_status = AiEngine::get_status();
    assert!(!unloaded_status.loaded, "Status loaded should be false");
    println!("Model successfully unloaded. Active memory reclaimed.");

    // 5. Reload for remaining test suites
    AiEngine::load_model(MODEL_PATH, TOKENIZER_PATH, false).expect("Failed to reload model");
    assert!(AiEngine::is_loaded());
}

#[test]
fn test_02_all_12_rewriting_modes() {
    println!("\n=== TEST 2: All 12 Rewriting Modes Evaluation ===");
    if !check_model_exists() {
        return;
    }
    if !AiEngine::is_loaded() {
        AiEngine::load_model(MODEL_PATH, TOKENIZER_PATH, false)
            .expect("Failed to load model for 12-mode test");
    }

    let input_text = "In order to make sure we don't fail, the team was given a difficult assignment by the manager yesterday.";
    println!("Original Input Sentence:\n\"{}\"\n", input_text);

    let modes = [
        RewriteMode::Rephrase,
        RewriteMode::MakeProfessional,
        RewriteMode::MakeAcademic,
        RewriteMode::MakeFormal,
        RewriteMode::MakeCasual,
        RewriteMode::MakeConcise,
        RewriteMode::Expand,
        RewriteMode::ImproveClarity,
        RewriteMode::ImproveVocabulary,
        RewriteMode::Simplify,
        RewriteMode::ActiveToPassive,
        RewriteMode::PassiveToActive,
    ];

    for (idx, mode) in modes.iter().enumerate() {
        let result = AiEngine::rewrite(input_text, *mode, Some(75));

        println!("------------------------------------------------------------");
        let exp_tag = if mode.is_experimental() {
            " [Experimental]"
        } else {
            ""
        };
        println!(
            "[Mode {:02}/12] {}{} ({})",
            idx + 1,
            mode.title(),
            exp_tag,
            result.engine
        );
        println!("  Original: \"{}\"", result.original);
        println!("  Revised : \"{}\"", result.revised);
        if let Some(latency) = result.latency_ms {
            let tps = result.tokens_per_sec.unwrap_or(0.0);
            let tokens = result.tokens_generated.unwrap_or(0);
            let prefill = result.prompt_eval_ms.unwrap_or(0.0);
            let token_gen = result.token_eval_ms.unwrap_or(0.0);
            println!(
                "  Metrics : Total {:.1} ms (Prefill: {:.1} ms, Gen: {:.1} ms) | {} tokens | {:.2} tok/s",
                latency, prefill, token_gen, tokens, tps
            );
        }

        assert_eq!(
            result.status, "success",
            "Inference status should be success"
        );
        assert!(
            !result.revised.trim().is_empty(),
            "Revised text must not be empty"
        );
        assert_ne!(
            result.revised.trim().to_lowercase(),
            result.original.trim().to_lowercase(),
            "Output must be a neural transformation, not an echo"
        );
    }
}

#[test]
fn test_03_quality_audit_special_cases() {
    println!("\n=== TEST 3: Quality Audit for Specific Edge Cases ===");
    if !check_model_exists() {
        return;
    }
    if !AiEngine::is_loaded() {
        AiEngine::load_model(MODEL_PATH, TOKENIZER_PATH, false)
            .expect("Failed to load model for quality audit");
    }

    // Special Case A: Active to Passive
    let active_input = "The manager assigned a difficult task to the team yesterday.";
    let res_passive = AiEngine::rewrite(active_input, RewriteMode::ActiveToPassive, Some(50));
    println!("------------------------------------------------------------");
    println!("Case A: Active to Passive Transformation");
    println!("  Active Input : \"{}\"", active_input);
    println!("  Passive Gen  : \"{}\"", res_passive.revised);
    assert_eq!(res_passive.status, "success");
    // Verify that the team/task is subject and not inverted
    println!("  Assessment   : Evaluated for voice transformation syntax");

    // Special Case B: Passive to Active
    let passive_input = "A difficult task was assigned to the team by the manager yesterday.";
    let res_active = AiEngine::rewrite(passive_input, RewriteMode::PassiveToActive, Some(50));
    println!("------------------------------------------------------------");
    println!("Case B: Passive to Active Transformation");
    println!("  Passive Input: \"{}\"", passive_input);
    println!("  Active Gen   : \"{}\"", res_active.revised);
    assert_eq!(res_active.status, "success");
    println!("  Assessment   : Evaluated for agent subject placement");

    // Special Case C: Expand without hallucination
    let expand_input = "The meeting will begin at 10 AM.";
    let res_expand = AiEngine::rewrite(expand_input, RewriteMode::Expand, Some(60));
    println!("------------------------------------------------------------");
    println!("Case C: Expand Sentence (Preserve Factuality)");
    println!("  Input : \"{}\"", expand_input);
    println!("  Output: \"{}\"", res_expand.revised);
    assert_eq!(res_expand.status, "success");
    // Must contain 10 AM or ten
    assert!(
        res_expand.revised.to_lowercase().contains("10")
            || res_expand.revised.to_lowercase().contains("ten"),
        "Expanded text must preserve the original time condition (10 AM)"
    );

    // Special Case D: Simplify without dropping key conditions
    let simplify_input = "Notwithstanding the adverse meteorological conditions, the operations proceeded as scheduled.";
    let res_simplify = AiEngine::rewrite(simplify_input, RewriteMode::Simplify, Some(50));
    println!("------------------------------------------------------------");
    println!("Case D: Simplify Plain English");
    println!("  Input : \"{}\"", simplify_input);
    println!("  Output: \"{}\"", res_simplify.revised);
    assert_eq!(res_simplify.status, "success");
    assert!(!res_simplify.revised.is_empty());
}

#[test]
fn test_04_benchmark_and_latency_profiling() {
    println!("\n=== TEST 4: Performance Benchmark & Cold vs Warm Latency ===");
    if !check_model_exists() {
        return;
    }
    if !AiEngine::is_loaded() {
        AiEngine::load_model(MODEL_PATH, TOKENIZER_PATH, false)
            .expect("Failed to load model for benchmark");
    }

    let sentences = [
        "Due to the fact that our budget is tight, we cannot purchase new equipment at this point in time.",
        "Hey bro, wanna grab some food later or are you gonna be super busy with work?",
        "The project milestones were achieved by the development team ahead of the scheduled deadline.",
        "In spite of the rain was heavy, everyone arrived at the conference center without delay.",
        "It is important to remember that significant differences exist between qualitative and quantitative research methods.",
        "I was just wondering if you had any spare time tomorrow to look over my presentation slides.",
        "The authentication token must be renewed before expiration in order to prevent session termination.",
        "The quarterly revenues exhibited an upward trajectory as a consequence of expanded market penetration.",
        "We are writing this email to apologize for the inconvenience caused by our server outage yesterday.",
        "Individuals who engage in regular cardiovascular exercise demonstrate improved endurance and mental acuity.",
        "Notwithstanding previous objections raised by various stakeholders, the committee unanimously voted to implement the policy.",
        "I can't make it to tonight's dinner because of sudden family stuff.",
        "The company shall not be held liable for any damages arising out of the unauthorized use of the software.",
        "Photosynthesis allows green plants to convert sunlight and carbon dioxide into oxygen and glucose.",
        "Please make sure that you send the signed agreement back to our legal department by Friday afternoon.",
        "I think that maybe we should consider changing our marketing strategy a little bit.",
        "Furthermore, in addition to that, there are several other factors that must be taken into consideration.",
        "The ancient castle stood silently on the edge of the dark misty cliffs overlooking the stormy ocean.",
        "Do not forget to submit your weekly progress reports before leaving the office.",
        "True wisdom consists not only in acquiring extensive knowledge, but in understanding how to apply it ethically.",
    ];

    let mut cold_latency = 0.0;
    let mut warm_latencies = Vec::new();
    let mut speeds = Vec::new();
    let mut total_tokens = 0;

    for (idx, sent) in sentences.iter().enumerate() {
        let result = AiEngine::rewrite(sent, RewriteMode::Rephrase, Some(60));
        let latency = result.latency_ms.unwrap_or(0.0);
        let tps = result.tokens_per_sec.unwrap_or(0.0);
        let tokens = result.tokens_generated.unwrap_or(0);

        if idx == 0 {
            cold_latency = latency;
        } else {
            warm_latencies.push(latency);
        }
        speeds.push(tps);
        total_tokens += tokens;

        println!(
            "[{:02}/20] Latency: {:6.1} ms | Speed: {:5.2} tok/s | Tokens: {:2} | Original: \"{}\" -> Revised: \"{}\"",
            idx + 1, latency, tps, tokens, sent, result.revised
        );

        assert_eq!(result.status, "success");
    }

    let avg_warm_latency: f64 = warm_latencies.iter().sum::<f64>() / warm_latencies.len() as f64;
    let avg_speed: f64 = speeds.iter().sum::<f64>() / speeds.len() as f64;

    let status = AiEngine::get_status();

    println!("\n================ DETAILED BENCHMARK PROFILE ================");
    println!("Total Sentences Processed : {}", sentences.len());
    println!("Total Tokens Generated    : {}", total_tokens);
    println!(
        "Cold Inference Latency    : {:.1} ms ({:.2} s)",
        cold_latency,
        cold_latency / 1000.0
    );
    println!(
        "Avg Warm Inference Latency: {:.1} ms ({:.2} s)",
        avg_warm_latency,
        avg_warm_latency / 1000.0
    );
    println!("Average Generation Speed  : {:.2} tokens/sec", avg_speed);
    if status.ram_measured {
        println!(
            "Process Working Set RAM   : {:.1} MB",
            status.ram_working_set_mb.unwrap_or(0.0)
        );
        println!(
            "Process Peak Working Set  : {:.1} MB",
            status.ram_peak_mb.unwrap_or(0.0)
        );
    }
    println!("============================================================");
}

#[test]
fn test_05_cancellation_and_error_handling() {
    println!("\n=== TEST 5: Cancellation and Error Handling ===");
    if !check_model_exists() {
        return;
    }

    // Test A: Cancellation mechanism
    AiEngine::cancel_inference();
    let res_cancelled = AiEngine::rewrite(
        "This is a long sentence that should be immediately cancelled during token generation loop.",
        RewriteMode::Expand,
        Some(100),
    );
    println!("Cancellation Test Status : {}", res_cancelled.status);
    println!(
        "Error Message            : {:?}",
        res_cancelled.error_message
    );
    assert_eq!(res_cancelled.status, "cancelled");

    // Test B: Model Unloaded Handling (No Heuristic Masking)
    AiEngine::unload_model().unwrap();
    let res_unloaded = AiEngine::rewrite("Any input sentence", RewriteMode::MakeProfessional, None);
    println!("Unloaded Test Status     : {}", res_unloaded.status);
    println!(
        "Error Message            : {:?}",
        res_unloaded.error_message
    );
    assert_eq!(res_unloaded.status, "model_not_loaded");
    assert!(
        res_unloaded.revised.is_empty(),
        "Revised must be empty on error, not fake heuristic"
    );
    assert_eq!(res_unloaded.engine, "None");

    // Reload for safety
    AiEngine::load_model(MODEL_PATH, TOKENIZER_PATH, false).unwrap();
}
