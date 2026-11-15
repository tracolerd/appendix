use appendix_core::ai_engine::AiEngine;
use appendix_core::ai_rephrase::RewriteMode;

const MODEL_PATH: &str = r"..\models\qwen2.5-0.5b-instruct-q4_k_m.gguf";
const TOKENIZER_PATH: &str = r"..\models\tokenizer.json";

#[test]
fn test_01_model_loading_and_lifecycle() {
    println!("\n=== TEST 1: Model Loading & Lifecycle ===");
    let status = AiEngine::load_model(MODEL_PATH, TOKENIZER_PATH)
        .expect("Failed to load Qwen 2.5 0.5B GGUF model");

    assert!(status.loaded, "Model status should report loaded=true");
    assert!(AiEngine::is_loaded(), "AiEngine::is_loaded() should be true");
    assert!(status.model_size_mb > 100.0, "Model size should be > 100 MB");
    println!("Loaded model: {}", status.model_name);
    println!("Model size: {:.1} MB", status.model_size_mb);
    println!("Engine: {}", status.engine);
}

#[test]
fn test_02_all_12_rewriting_modes() {
    println!("\n=== TEST 2: All 12 Rewriting Modes Evaluation ===");
    if !AiEngine::is_loaded() {
        AiEngine::load_model(MODEL_PATH, TOKENIZER_PATH)
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
        println!("[Mode {:02}/12] {} ({})", idx + 1, mode.title(), result.engine);
        println!("  Original: \"{}\"", result.original);
        println!("  Revised : \"{}\"", result.revised);
        if let Some(latency) = result.latency_ms {
            let tps = result.tokens_per_sec.unwrap_or(0.0);
            let tokens = result.tokens_generated.unwrap_or(0);
            println!("  Metrics : {:.1} ms | {} tokens | {:.2} tok/s", latency, tokens, tps);
        }

        assert_eq!(result.status, "success", "Inference status should be success");
        assert!(!result.revised.trim().is_empty(), "Revised text must not be empty");
        // Verify output is a distinct neural transformation
        assert_ne!(
            result.revised.trim().to_lowercase(),
            result.original.trim().to_lowercase(),
            "Output must be a neural transformation, not an echo"
        );
    }
}

#[test]
fn test_03_benchmark_20_sentences() {
    println!("\n=== TEST 3: Performance Benchmark on 20 Sentences ===");
    if !AiEngine::is_loaded() {
        AiEngine::load_model(MODEL_PATH, TOKENIZER_PATH)
            .expect("Failed to load model for benchmark");
    }

    let sentences = [
        // 1. Redundant business phrasing
        "Due to the fact that our budget is tight, we cannot purchase new equipment at this point in time.",
        // 2. Casual slang
        "Hey bro, wanna grab some food later or are you gonna be super busy with work?",
        // 3. Passive voice / convoluted
        "The project milestones were achieved by the development team ahead of the scheduled deadline.",
        // 4. Grammar / awkward clauses
        "In spite of the rain was heavy, everyone arrived at the conference center without delay.",
        // 5. Wordy academic intro
        "It is important to remember that significant differences exist between qualitative and quantitative research methods.",
        // 6. Conversational email
        "I was just wondering if you had any spare time tomorrow to look over my presentation slides.",
        // 7. Tech documentation sentence
        "The authentication token must be renewed before expiration in order to prevent session termination.",
        // 8. Financial report
        "The quarterly revenues exhibited an upward trajectory as a consequence of expanded market penetration.",
        // 9. Customer support
        "We are writing this email to apologize for the inconvenience caused by our server outage yesterday.",
        // 10. Medical/health advisory
        "Individuals who engage in regular cardiovascular exercise demonstrate improved endurance and mental acuity.",
        // 11. Overly complex sentence
        "Notwithstanding previous objections raised by various stakeholders, the committee unanimously voted to implement the policy.",
        // 12. Short casual statement
        "I can't make it to tonight's dinner because of sudden family stuff.",
        // 13. Legal disclaimer
        "The company shall not be held liable for any damages arising out of the unauthorized use of the software.",
        // 14. Educational summary
        "Photosynthesis allows green plants to convert sunlight and carbon dioxide into oxygen and glucose.",
        // 15. Action item
        "Please make sure that you send the signed agreement back to our legal department by Friday afternoon.",
        // 16. Weak phrasing
        "I think that maybe we should consider changing our marketing strategy a little bit.",
        // 17. Clunky transition
        "Furthermore, in addition to that, there are several other factors that must be taken into consideration.",
        // 18. Creative narrative
        "The ancient castle stood silently on the edge of the dark misty cliffs overlooking the stormy ocean.",
        // 19. Direct command
        "Do not forget to submit your weekly progress reports before leaving the office.",
        // 20. Philosophical / Abstract
        "True wisdom consists not only in acquiring extensive knowledge, but in understanding how to apply it ethically.",
    ];

    let mut latencies = Vec::new();
    let mut speeds = Vec::new();
    let mut total_tokens = 0;

    for (idx, sent) in sentences.iter().enumerate() {
        let result = AiEngine::rewrite(sent, RewriteMode::Rephrase, Some(60));
        let latency = result.latency_ms.unwrap_or(0.0);
        let tps = result.tokens_per_sec.unwrap_or(0.0);
        let tokens = result.tokens_generated.unwrap_or(0);

        latencies.push(latency);
        speeds.push(tps);
        total_tokens += tokens;

        println!(
            "[{:02}/20] Latency: {:6.1} ms | Speed: {:5.2} tok/s | Tokens: {:2} | Original: \"{}\" -> Revised: \"{}\"",
            idx + 1, latency, tps, tokens, sent, result.revised
        );

        assert!(!result.revised.is_empty(), "Sentence {} output must not be empty", idx + 1);
    }

    let avg_latency: f64 = latencies.iter().sum::<f64>() / latencies.len() as f64;
    let min_latency: f64 = latencies.iter().cloned().fold(f64::INFINITY, f64::min);
    let max_latency: f64 = latencies.iter().cloned().fold(0.0, f64::max);
    let avg_speed: f64 = speeds.iter().sum::<f64>() / speeds.len() as f64;

    println!("\n================ BENCHMARK SUMMARY (20 SENTENCES) ================");
    println!("Total Sentences Processed : {}", sentences.len());
    println!("Total Tokens Generated    : {}", total_tokens);
    println!("Average Latency           : {:.1} ms ({:.2} s)", avg_latency, avg_latency / 1000.0);
    println!("Min Latency               : {:.1} ms", min_latency);
    println!("Max Latency               : {:.1} ms", max_latency);
    println!("Average Generation Speed  : {:.2} tokens/sec", avg_speed);
    println!("=================================================================");
}
