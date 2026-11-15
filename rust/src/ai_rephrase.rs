use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
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
    pub fn from_i32(val: i32) -> Option<Self> {
        match val {
            0 => Some(RewriteMode::Rephrase),
            1 => Some(RewriteMode::MakeProfessional),
            2 => Some(RewriteMode::MakeAcademic),
            3 => Some(RewriteMode::MakeFormal),
            4 => Some(RewriteMode::MakeCasual),
            5 => Some(RewriteMode::MakeConcise),
            6 => Some(RewriteMode::Expand),
            7 => Some(RewriteMode::ImproveClarity),
            8 => Some(RewriteMode::ImproveVocabulary),
            9 => Some(RewriteMode::Simplify),
            10 => Some(RewriteMode::ActiveToPassive),
            11 => Some(RewriteMode::PassiveToActive),
            _ => None,
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
            RewriteMode::ActiveToPassive => "Active to Passive (Experimental)",
            RewriteMode::PassiveToActive => "Passive to Active (Experimental)",
        }
    }

    pub fn is_experimental(&self) -> bool {
        matches!(
            self,
            RewriteMode::ActiveToPassive | RewriteMode::PassiveToActive
        )
    }

    pub fn system_prompt(&self) -> &'static str {
        match self {
            RewriteMode::Rephrase => {
                "You are an expert English writing assistant. Rephrase the input text with natural, fluent wording while preserving the exact original meaning. Output ONLY the rewritten text without quotes, conversational filler, or commentary."
            }
            RewriteMode::MakeProfessional => {
                "You are a business communications specialist. Rewrite the text into a polished, respectful, and authoritative professional tone suitable for corporate correspondence. Expand contractions (e.g. use 'do not' instead of 'don't'). Output ONLY the rewritten text without quotes or commentary."
            }
            RewriteMode::MakeAcademic => {
                "You are an academic editor. Rewrite the text using scholarly tone, precise terminology, objective voice, and rigorous sentence structure. Eliminate contractions and casual expressions. Output ONLY the rewritten text without quotes or commentary."
            }
            RewriteMode::MakeFormal => {
                "You are an executive formal writing stylist. Rewrite the text into an elevated, distinguished, formal register. Strictly eliminate slang, contractions, and colloquialisms. Output ONLY the rewritten text without quotes or commentary."
            }
            RewriteMode::MakeCasual => {
                "You are a friendly writing coach. Rewrite the text into a warm, natural, engaging casual tone with friendly, conversational phrasing. Output ONLY the rewritten text without quotes or commentary."
            }
            RewriteMode::MakeConcise => {
                "You are a minimalist editor. Condense the text by removing filler words, circumlocution, and redundancy while keeping ALL key facts intact. Output ONLY the concise text without quotes or commentary."
            }
            RewriteMode::Expand => {
                "You are an articulate writing assistant. Elaborate and enhance the sentence with descriptive nuance and refined vocabulary. CRITICAL RULE: Do NOT invent fictional facts, unauthorized agendas, unmentioned participants, or fake locations. Keep strict factual consistency with the original statement. Output ONLY the rewritten text without quotes or commentary."
            }
            RewriteMode::ImproveClarity => {
                "You are a clarity editor. Restructure awkward phrasing, ambiguous pronouns, and clunky syntax to make the sentence effortless to comprehend. Output ONLY the revised text without quotes or commentary."
            }
            RewriteMode::ImproveVocabulary => {
                "You are a vocabulary expert. Upgrade repetitive and basic words with precise, sophisticated, and evocative diction suitable to the context. Output ONLY the upgraded text without quotes or commentary."
            }
            RewriteMode::Simplify => {
                "You are a plain-language editor. Simplify complex vocabulary and difficult phrasing into clear, everyday English. CRITICAL RULE: Preserve ALL key facts, conditions, times, and core reasoning without dropping important details. Output ONLY the simplified text without quotes or commentary."
            }
            RewriteMode::ActiveToPassive => {
                "You are a precise grammar transformation tool. Convert the given active voice sentence into passive voice.\nRules:\n1. The direct object/receiver of the action becomes the grammatical subject.\n2. Use the correct auxiliary verb ('is', 'was', 'were', 'has been') + past participle.\n3. The original doer/subject must be placed in a 'by [agent]' prepositional phrase at the end.\n4. DO NOT swap who performs the action and who receives it.\n5. Output ONLY the converted passive sentence without quotes or notes."
            }
            RewriteMode::PassiveToActive => {
                "You are a precise grammar transformation tool. Convert the given passive voice sentence into active voice.\nRules:\n1. Identify the agent performing the action in the 'by [agent]' phrase.\n2. Place that agent at the beginning as the grammatical subject.\n3. Convert the verb to active voice matching the original tense.\n4. Place the receiver of the action in the object position.\n5. DO NOT swap who performs the action and who receives it.\n6. Output ONLY the converted active sentence without quotes or notes."
            }
        }
    }

    /// Format prompt for Qwen 2.5 ChatML format with mode-tailored user prompts
    pub fn format_chatml_prompt(&self, text: &str) -> String {
        let trimmed = text.trim();
        let user_prompt = match self {
            RewriteMode::ActiveToPassive => {
                format!(
                    "Convert this active voice sentence into passive voice. Make sure the receiver becomes the subject and the doer is in a 'by...' phrase:\nSentence: {}\nPassive:",
                    trimmed
                )
            }
            RewriteMode::PassiveToActive => {
                format!(
                    "Convert this passive voice sentence into active voice. Make sure the agent in 'by...' becomes the grammatical subject:\nSentence: {}\nActive:",
                    trimmed
                )
            }
            RewriteMode::Expand => {
                format!(
                    "Elaborate this sentence with descriptive depth while preserving strict factual consistency and adding no fictional details: {}",
                    trimmed
                )
            }
            RewriteMode::Simplify => {
                format!(
                    "Simplify this sentence into clear plain English without losing any facts, conditions, or reasoning: {}",
                    trimmed
                )
            }
            RewriteMode::MakeConcise => {
                format!(
                    "Make this sentence concise by removing wordiness and redundancy: {}",
                    trimmed
                )
            }
            _ => trimmed.to_string(),
        };

        format!(
            "<|im_start|>system\n{}<|im_end|>\n<|im_start|>user\n{}<|im_end|>\n<|im_start|>assistant\n",
            self.system_prompt(),
            user_prompt
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
                    ("haven't", "have not"),
                    ("hasn't", "has not"),
                    ("wouldn't", "would not"),
                    ("couldn't", "could not"),
                    ("shouldn't", "should not"),
                    ("kids", "children"),
                    ("guy", "person"),
                    ("guys", "individuals"),
                    ("a lot of", "numerous"),
                    ("tons of", "substantial quantities of"),
                ];
                for (from, to) in replacements {
                    s = s.replace(from, to);
                    let cap_from = format!("{}{}", &from[..1].to_uppercase(), &from[1..]);
                    let cap_to = format!("{}{}", &to[..1].to_uppercase(), &to[1..]);
                    s = s.replace(&cap_from, &cap_to);
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
    pub engine: String,
    pub latency_ms: Option<f64>,
    pub prompt_eval_ms: Option<f64>,
    pub token_eval_ms: Option<f64>,
    pub tokens_generated: Option<usize>,
    pub tokens_per_sec: Option<f64>,
    pub model_name: Option<String>,
    pub status: String,
    pub error_message: Option<String>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_chatml_formatting() {
        let mode = RewriteMode::Rephrase;
        let prompt = mode.format_chatml_prompt("This is a test sentence.");
        assert!(prompt.starts_with("<|im_start|>system\n"));
        assert!(prompt.contains("<|im_start|>user\nThis is a test sentence.<|im_end|>\n"));
        assert!(prompt.ends_with("<|im_start|>assistant\n"));
    }

    #[test]
    fn test_heuristic_fallback_formal() {
        let mode = RewriteMode::MakeFormal;
        let input = "I don't think kids should eat tons of candy.";
        let output = mode.heuristic_fallback(input);
        assert!(output.contains("do not"));
        assert!(output.contains("children"));
    }

    #[test]
    fn test_heuristic_fallback_concise() {
        let mode = RewriteMode::MakeConcise;
        let input = "In order to succeed, we must act on a daily basis.";
        let output = mode.heuristic_fallback(input);
        assert!(output.contains("To succeed"));
        assert!(output.contains("daily"));
    }
}
