use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[repr(i32)]
pub enum RewriteMode {
    Rephrase = 0,
    MakeProfessional = 1,
    MakeAcademic = 2,
    MakeFormal = 3,
    MakeCasual = 4,
    MakeConcise = 5,
    Expand = 6,
    ImproveClarity = 7,
    ImproveVocabulary = 8,
    Simplify = 9,
    ActiveToPassive = 10,
    PassiveToActive = 11,
}

impl RewriteMode {
    pub fn from_i32(val: i32) -> Self {
        match val {
            1 => RewriteMode::MakeProfessional,
            2 => RewriteMode::MakeAcademic,
            3 => RewriteMode::MakeFormal,
            4 => RewriteMode::MakeCasual,
            5 => RewriteMode::MakeConcise,
            6 => RewriteMode::Expand,
            7 => RewriteMode::ImproveClarity,
            8 => RewriteMode::ImproveVocabulary,
            9 => RewriteMode::Simplify,
            10 => RewriteMode::ActiveToPassive,
            11 => RewriteMode::PassiveToActive,
            _ => RewriteMode::Rephrase,
        }
    }

    pub fn title(&self) -> &'static str {
        match self {
            RewriteMode::Rephrase => "Rephrase",
            RewriteMode::MakeProfessional => "Make Professional",
            RewriteMode::MakeAcademic => "Make Academic",
            RewriteMode::MakeFormal => "Make Formal",
            RewriteMode::MakeCasual => "Make Casual",
            RewriteMode::MakeConcise => "Make Concise",
            RewriteMode::Expand => "Expand Sentence",
            RewriteMode::ImproveClarity => "Improve Clarity",
            RewriteMode::ImproveVocabulary => "Improve Vocabulary",
            RewriteMode::Simplify => "Simplify",
            RewriteMode::ActiveToPassive => "Active to Passive",
            RewriteMode::PassiveToActive => "Passive to Active",
        }
    }

    pub fn system_prompt(&self) -> &'static str {
        match self {
            RewriteMode::Rephrase => {
                "You are an expert English writing assistant. Rephrase the input text clearly, preserving the exact original meaning. Output ONLY the rewritten text without conversational filler, notes, or quotes."
            }
            RewriteMode::MakeProfessional => {
                "You are a business communications specialist. Rewrite the text into a polished, respectful, and authoritative professional tone. Output ONLY the rewritten text without conversational filler, notes, or quotes."
            }
            RewriteMode::MakeAcademic => {
                "You are an academic editor. Rewrite the text using scholarly tone, precise terminology, objective voice, and rigorous sentence structure. Output ONLY the rewritten text without conversational filler, notes, or quotes."
            }
            RewriteMode::MakeFormal => {
                "You are a formal writing stylist. Rewrite the text into formal English, eliminating slang, contractions, and colloquialisms. Output ONLY the rewritten text without conversational filler, notes, or quotes."
            }
            RewriteMode::MakeCasual => {
                "You are a friendly writing coach. Rewrite the text into a warm, natural, engaging casual tone. Output ONLY the rewritten text without conversational filler, notes, or quotes."
            }
            RewriteMode::MakeConcise => {
                "You are a minimalist editor. Condense the text by removing filler words and redundancy while keeping all key facts intact. Output ONLY the concise text without conversational filler, notes, or quotes."
            }
            RewriteMode::Expand => {
                "You are an expressive writer. Elaboration and expand the text with vivid context and nuanced description while preserving original intent. Output ONLY the expanded text without conversational filler, notes, or quotes."
            }
            RewriteMode::ImproveClarity => {
                "You are a clarity editor. Restructure awkward phrasing, ambiguous pronouns, and clunky syntax to make the sentence effortless to comprehend. Output ONLY the revised text without conversational filler, notes, or quotes."
            }
            RewriteMode::ImproveVocabulary => {
                "You are a vocabulary expert. Upgrade repetitive and basic words with precise, sophisticated, and evocative diction suitable to the context. Output ONLY the upgraded text without conversational filler, notes, or quotes."
            }
            RewriteMode::Simplify => {
                "You are a plain-language advocate. Simplify complex clauses and arcane jargon into simple, crisp English that anyone can instantly understand. Output ONLY the simplified text without conversational filler, notes, or quotes."
            }
            RewriteMode::ActiveToPassive => {
                "Convert the sentence from active voice into grammatically flawless passive voice. Output ONLY the converted text."
            }
            RewriteMode::PassiveToActive => {
                "Convert the sentence from passive voice into punchy, direct active voice. Output ONLY the converted text."
            }
        }
    }

    /// Format prompt for Qwen 2.5 ChatML format
    pub fn format_chatml_prompt(&self, text: &str) -> String {
        format!(
            "<|im_start|>system\n{}<|im_end|>\n<|im_start|>user\n{}<|im_end|>\n<|im_start|>assistant\n",
            self.system_prompt(),
            text.trim()
        )
    }

    /// Fast, offline heuristic rule-based rephrasing fallback when SLM is not active
    pub fn heuristic_fallback(&self, text: &str) -> String {
        let trimmed = text.trim();
        match self {
            RewriteMode::MakeConcise => {
                let mut s = trimmed.to_string();
                let replacements = [
                    ("in order to", "to"),
                    ("due to the fact that", "because"),
                    ("at this point in time", "now"),
                    ("for the purpose of", "for"),
                    ("in the event that", "if"),
                    ("a large number of", "many"),
                    ("has the ability to", "can"),
                    ("is able to", "can"),
                    ("with regards to", "regarding"),
                    ("on a daily basis", "daily"),
                ];
                for (from, to) in replacements {
                    s = s.replace(from, to);
                    s = s.replace(&from.to_uppercase(), &to.to_uppercase());
                    // Capitalized first letter
                    let cap_from = format!("{}{}", &from[..1].to_uppercase(), &from[1..]);
                    let cap_to = format!("{}{}", &to[..1].to_uppercase(), &to[1..]);
                    s = s.replace(&cap_from, &cap_to);
                }
                s
            }
            RewriteMode::MakeFormal => {
                let mut s = trimmed.to_string();
                let replacements = [
                    ("don't", "do not"),
                    ("can't", "cannot"),
                    ("won't", "will not"),
                    ("didn't", "did not"),
                    ("isn't", "is not"),
                    ("aren't", "are not"),
                    ("wasn't", "was not"),
                    ("weren't", "were not"),
                    ("gonna", "going to"),
                    ("wanna", "want to"),
                    ("kinda", "somewhat"),
                    ("lots of", "numerous"),
                    ("kids", "children"),
                    ("buy", "purchase"),
                ];
                for (from, to) in replacements {
                    s = s.replace(from, to);
                }
                s
            }
            RewriteMode::MakeCasual => {
                let mut s = trimmed.to_string();
                let replacements = [
                    ("do not", "don't"),
                    ("cannot", "can't"),
                    ("will not", "won't"),
                    ("did not", "didn't"),
                    ("is not", "isn't"),
                    ("are not", "aren't"),
                    ("purchase", "buy"),
                    ("commence", "start"),
                    ("terminate", "end"),
                    ("inquire", "ask"),
                    ("utilize", "use"),
                ];
                for (from, to) in replacements {
                    s = s.replace(from, to);
                }
                s
            }
            _ => trimmed.to_string(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RewriteResult {
    pub original: String,
    pub revised: String,
    pub mode: String,
    pub engine: String, // "SLM" or "Heuristic"
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_chatml_formatting() {
        let mode = RewriteMode::MakeProfessional;
        let prompt = mode.format_chatml_prompt("Hey send me that file asap.");
        assert!(prompt.contains("<|im_start|>system"));
        assert!(prompt.contains("<|im_start|>user\nHey send me that file asap."));
        assert!(prompt.ends_with("<|im_start|>assistant\n"));
    }

    #[test]
    fn test_heuristic_fallback_concise() {
        let mode = RewriteMode::MakeConcise;
        let input = "In order to succeed, we must practice on a daily basis.";
        let output = mode.heuristic_fallback(input);
        assert_eq!(output, "To succeed, we must practice daily.");
    }

    #[test]
    fn test_heuristic_fallback_formal() {
        let mode = RewriteMode::MakeFormal;
        let input = "We don't wanna buy lots of stuff.";
        let output = mode.heuristic_fallback(input);
        assert_eq!(output, "We do not want to purchase numerous stuff.");
    }
}

