pub mod ai_engine;
pub mod ai_rephrase;
pub mod history;
pub mod insights;
pub mod jni_bridge;

use std::ffi::{CStr, CString};
use std::os::raw::c_char;

use harper_core::linting::{LintGroup, Linter};
use harper_core::parsers::PlainEnglish;
use harper_core::spell::FstDictionary;
use harper_core::{Dialect, Document, Lrc};
use serde::{Deserialize, Serialize};

use ai_engine::AiEngine;
use ai_rephrase::RewriteMode;
use history::HistoryStorage;
use insights::InsightsEngine;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Suggestion {
    pub replacement: String,
    pub description: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LintResult {
    pub start: usize,
    pub end: usize,
    pub message: String,
    pub suggestions: Vec<Suggestion>,
    pub lint_kind: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[repr(i32)]
pub enum EnglishDialect {
    American = 0,
    British = 1,
}

impl From<EnglishDialect> for Dialect {
    fn from(d: EnglishDialect) -> Self {
        match d {
            EnglishDialect::American => Dialect::American,
            EnglishDialect::British => Dialect::British,
        }
    }
}

pub struct GrammarEngine {
    dict: Lrc<FstDictionary>,
    dialect: EnglishDialect,
}

impl GrammarEngine {
    pub fn new(dialect: EnglishDialect) -> Self {
        let dict = FstDictionary::curated();
        Self { dict, dialect }
    }

    pub fn set_dialect(&mut self, dialect: EnglishDialect) {
        self.dialect = dialect;
    }

    pub fn check_text(&self, text: &str) -> Vec<LintResult> {
        let parser = PlainEnglish;
        let document = Document::new_curated(text, &parser);
        let mut linter = LintGroup::new_curated(self.dict.clone(), self.dialect.into());
        let lints = linter.lint(&document);

        lints
            .into_iter()
            .map(|lint| {
                let span = lint.span;
                let suggestions = lint
                    .suggestions
                    .into_iter()
                    .map(|s| match s {
                        harper_core::linting::Suggestion::ReplaceWith(chars) => Suggestion {
                            replacement: chars.into_iter().collect(),
                            description: None,
                        },
                        harper_core::linting::Suggestion::InsertAfter(chars) => Suggestion {
                            replacement: chars.into_iter().collect(),
                            description: Some("Insert missing text".to_string()),
                        },
                        harper_core::linting::Suggestion::Remove => Suggestion {
                            replacement: String::new(),
                            description: Some("Remove redundant text".to_string()),
                        },
                    })
                    .collect();

                LintResult {
                    start: span.start,
                    end: span.end,
                    message: lint.message,
                    suggestions,
                    lint_kind: format!("{:?}", lint.lint_kind),
                }
            })
            .collect()
    }
}

// ---------------------------------------------------------------------------
// C ABI for Dart FFI / Flutter / Native Keyboards
// ---------------------------------------------------------------------------

#[no_mangle]
pub extern "C" fn appendix_engine_new(dialect: i32) -> *mut GrammarEngine {
    let dialect = if dialect == 1 {
        EnglishDialect::British
    } else {
        EnglishDialect::American
    };
    let engine = Box::new(GrammarEngine::new(dialect));
    Box::into_raw(engine)
}

#[no_mangle]
pub extern "C" fn appendix_engine_free(engine: *mut GrammarEngine) {
    if !engine.is_null() {
        unsafe {
            drop(Box::from_raw(engine));
        }
    }
}

#[no_mangle]
pub extern "C" fn appendix_engine_set_dialect(engine: *mut GrammarEngine, dialect: i32) {
    if !engine.is_null() {
        let dialect = if dialect == 1 {
            EnglishDialect::British
        } else {
            EnglishDialect::American
        };
        unsafe {
            (*engine).set_dialect(dialect);
        }
    }
}

#[no_mangle]
pub extern "C" fn appendix_engine_check(
    engine: *mut GrammarEngine,
    text: *const c_char,
) -> *mut c_char {
    if engine.is_null() || text.is_null() {
        return std::ptr::null_mut();
    }

    let c_str = unsafe { CStr::from_ptr(text) };
    let input = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    let results = unsafe { (*engine).check_text(input) };

    match serde_json::to_string(&results) {
        Ok(json_str) => match CString::new(json_str) {
            Ok(c_string) => c_string.into_raw(),
            Err(_) => std::ptr::null_mut(),
        },
        Err(_) => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn appendix_insights_analyze(text: *const c_char) -> *mut c_char {
    if text.is_null() {
        return std::ptr::null_mut();
    }

    let c_str = unsafe { CStr::from_ptr(text) };
    let input = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    let insights = InsightsEngine::analyze(input);

    match serde_json::to_string(&insights) {
        Ok(json_str) => match CString::new(json_str) {
            Ok(c_string) => c_string.into_raw(),
            Err(_) => std::ptr::null_mut(),
        },
        Err(_) => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn appendix_ai_load_model(
    model_path: *const c_char,
    tokenizer_path: *const c_char,
) -> *mut c_char {
    if model_path.is_null() || tokenizer_path.is_null() {
        return std::ptr::null_mut();
    }

    let m_str = match unsafe { CStr::from_ptr(model_path) }.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };
    let t_str = match unsafe { CStr::from_ptr(tokenizer_path) }.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    let status = match AiEngine::load_model(m_str, t_str) {
        Ok(s) => s,
        Err(e) => {
            let err_json = serde_json::json!({
                "loaded": false,
                "error": e,
            });
            return CString::new(err_json.to_string())
                .map(|c| c.into_raw())
                .unwrap_or(std::ptr::null_mut());
        }
    };

    match serde_json::to_string(&status) {
        Ok(json_str) => match CString::new(json_str) {
            Ok(c_string) => c_string.into_raw(),
            Err(_) => std::ptr::null_mut(),
        },
        Err(_) => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn appendix_ai_unload_model() -> i32 {
    match AiEngine::unload_model() {
        Ok(_) => 0,
        Err(_) => -1,
    }
}

#[no_mangle]
pub extern "C" fn appendix_ai_status() -> *mut c_char {
    let status = AiEngine::get_status();
    match serde_json::to_string(&status) {
        Ok(json_str) => match CString::new(json_str) {
            Ok(c_string) => c_string.into_raw(),
            Err(_) => std::ptr::null_mut(),
        },
        Err(_) => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn appendix_ai_rewrite(text: *const c_char, mode: i32) -> *mut c_char {
    if text.is_null() {
        return std::ptr::null_mut();
    }

    let c_str = unsafe { CStr::from_ptr(text) };
    let input = match c_str.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    let rewrite_mode = RewriteMode::from_i32(mode);
    let result = AiEngine::rewrite(input, rewrite_mode, None);

    match serde_json::to_string(&result) {
        Ok(json_str) => match CString::new(json_str) {
            Ok(c_string) => c_string.into_raw(),
            Err(_) => std::ptr::null_mut(),
        },
        Err(_) => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn appendix_history_save(
    db_path: *const c_char,
    content: *const c_char,
    word_count: usize,
    readability: f64,
) -> i64 {
    if db_path.is_null() || content.is_null() {
        return -1;
    }

    let db_str = match unsafe { CStr::from_ptr(db_path) }.to_str() {
        Ok(s) => s,
        Err(_) => return -1,
    };

    let content_str = match unsafe { CStr::from_ptr(content) }.to_str() {
        Ok(s) => s,
        Err(_) => return -1,
    };

    match HistoryStorage::save(db_str, content_str, word_count, readability) {
        Ok(id) => id,
        Err(_) => -1,
    }
}

#[no_mangle]
pub extern "C" fn appendix_history_list(db_path: *const c_char, limit: usize) -> *mut c_char {
    if db_path.is_null() {
        return std::ptr::null_mut();
    }

    let db_str = match unsafe { CStr::from_ptr(db_path) }.to_str() {
        Ok(s) => s,
        Err(_) => return std::ptr::null_mut(),
    };

    match HistoryStorage::list(db_str, limit) {
        Ok(entries) => match serde_json::to_string(&entries) {
            Ok(json_str) => match CString::new(json_str) {
                Ok(c_string) => c_string.into_raw(),
                Err(_) => std::ptr::null_mut(),
            },
            Err(_) => std::ptr::null_mut(),
        },
        Err(_) => std::ptr::null_mut(),
    }
}

#[no_mangle]
pub extern "C" fn appendix_history_delete(db_path: *const c_char, id: i64) -> i32 {
    if db_path.is_null() {
        return -1;
    }

    let db_str = match unsafe { CStr::from_ptr(db_path) }.to_str() {
        Ok(s) => s,
        Err(_) => return -1,
    };

    match HistoryStorage::delete(db_str, id) {
        Ok(_) => 0,
        Err(_) => -1,
    }
}

#[no_mangle]
pub extern "C" fn appendix_history_clear(db_path: *const c_char) -> i32 {
    if db_path.is_null() {
        return -1;
    }

    let db_str = match unsafe { CStr::from_ptr(db_path) }.to_str() {
        Ok(s) => s,
        Err(_) => return -1,
    };

    match HistoryStorage::clear(db_str) {
        Ok(_) => 0,
        Err(_) => -1,
    }
}

#[no_mangle]
pub extern "C" fn appendix_string_free(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            drop(CString::from_raw(ptr));
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_grammar_engine_detects_error() {
        let engine = GrammarEngine::new(EnglishDialect::American);
        let results = engine.check_text("This is an test sentence with error.");
        assert!(!results.is_empty(), "Should detect error in sentence");
    }

    #[test]
    fn test_c_abi_insights_and_rewrite() {
        let sample = CString::new("In order to achieve great results, we must practice daily.").unwrap();
        let insights_ptr = appendix_insights_analyze(sample.as_ptr());
        assert!(!insights_ptr.is_null());
        let insights_json = unsafe { CStr::from_ptr(insights_ptr).to_str().unwrap() };
        assert!(insights_json.contains("flesch_reading_ease"));
        appendix_string_free(insights_ptr);

        let rewrite_ptr = appendix_ai_rewrite(sample.as_ptr(), 5); // Make Concise
        assert!(!rewrite_ptr.is_null());
        let rewrite_json = unsafe { CStr::from_ptr(rewrite_ptr).to_str().unwrap() };
        assert!(rewrite_json.contains("To achieve great results"));
        appendix_string_free(rewrite_ptr);
    }
}
