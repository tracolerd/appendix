use std::ffi::{CStr, CString};
use std::os::raw::c_char;

use harper_core::linting::{LintGroup, Linter};
use harper_core::parsers::PlainEnglish;
use harper_core::spell::FstDictionary;
use harper_core::{Dialect, Document, Lrc};
use serde::{Deserialize, Serialize};

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
        println!("Detected {} issues:", results.len());
        for res in &results {
            println!("  [{}..{}] {}: {:?}", res.start, res.end, res.message, res.suggestions);
        }
    }

    #[test]
    fn test_dialect_differences() {
        let us_engine = GrammarEngine::new(EnglishDialect::American);
        let uk_engine = GrammarEngine::new(EnglishDialect::British);

        let us_check = us_engine.check_text("The colour of the car is blue.");
        let uk_check = uk_engine.check_text("The colour of the car is blue.");

        println!("US Check: {} results", us_check.len());
        println!("UK Check: {} results", uk_check.len());
        assert!(!us_check.is_empty(), "US should detect 'colour'");
        assert!(uk_check.is_empty(), "UK should accept 'colour'");
    }

    #[test]
    fn test_c_abi_lifecycle() {
        let engine = appendix_engine_new(0);
        assert!(!engine.is_null());

        let input = CString::new("This is an test.").unwrap();
        let result_ptr = appendix_engine_check(engine, input.as_ptr());
        assert!(!result_ptr.is_null());

        let result_str = unsafe { CStr::from_ptr(result_ptr).to_str().unwrap() };
        println!("C ABI JSON Output: {}", result_str);
        assert!(result_str.contains("Incorrect indefinite article"));

        appendix_string_free(result_ptr);
        appendix_engine_free(engine);
    }
}
