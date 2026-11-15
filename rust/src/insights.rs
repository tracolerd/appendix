use std::collections::{HashMap, HashSet};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WritingInsights {
    pub word_count: usize,
    pub char_count: usize,
    pub sentence_count: usize,
    pub paragraph_count: usize,
    pub reading_time_minutes: usize,
    pub flesch_reading_ease: f64,
    pub flesch_kincaid_grade: f64,
    pub readability_label: String,
    pub vocabulary_diversity: f64, // Type-Token Ratio (0.0 to 1.0)
    pub unique_words: usize,
    pub overused_words: Vec<OverusedWord>,
    pub average_sentence_length: f64,
    pub long_sentence_count: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OverusedWord {
    pub word: String,
    pub count: usize,
}

pub struct InsightsEngine;

impl InsightsEngine {
    /// Analyze text and compute rich, offline readability and stylistic insights.
    pub fn analyze(text: &str) -> WritingInsights {
        let trimmed = text.trim();
        if trimmed.is_empty() {
            return WritingInsights {
                word_count: 0,
                char_count: 0,
                sentence_count: 0,
                paragraph_count: 0,
                reading_time_minutes: 0,
                flesch_reading_ease: 100.0,
                flesch_kincaid_grade: 0.0,
                readability_label: "N/A".to_string(),
                vocabulary_diversity: 1.0,
                unique_words: 0,
                overused_words: Vec::new(),
                average_sentence_length: 0.0,
                long_sentence_count: 0,
            };
        }

        let char_count = trimmed.chars().count();

        // Paragraphs
        let paragraphs: Vec<&str> = trimmed.split("\n\n").filter(|p| !p.trim().is_empty()).collect();
        let paragraph_count = paragraphs.len().max(1);

        // Sentences
        let sentences: Vec<&str> = trimmed
            .split(|c| c == '.' || c == '!' || c == '?')
            .map(|s| s.trim())
            .filter(|s| !s.is_empty())
            .collect();
        let sentence_count = sentences.len().max(1);

        // Words
        let mut total_syllables: usize = 0;
        let mut words: Vec<String> = Vec::new();
        let mut word_frequencies: HashMap<String, usize> = HashMap::new();

        for word in trimmed.split_whitespace() {
            let cleaned: String = word
                .chars()
                .filter(|c| c.is_alphabetic())
                .collect::<String>()
                .to_lowercase();

            if !cleaned.is_empty() {
                total_syllables += Self::count_syllables(&cleaned);
                *word_frequencies.entry(cleaned.clone()).or_insert(0) += 1;
                words.push(cleaned);
            }
        }

        let word_count = words.len().max(1);
        let unique_words = word_frequencies.len();

        // Type-Token Ratio
        let vocabulary_diversity = (unique_words as f64) / (word_count as f64);

        // Reading time (~200 words per minute)
        let reading_time_minutes = (word_count / 200).max(1);

        // Average sentence length
        let average_sentence_length = (word_count as f64) / (sentence_count as f64);

        // Long sentences (> 25 words)
        let mut long_sentence_count = 0;
        for s in &sentences {
            let s_words = s.split_whitespace().count();
            if s_words > 25 {
                long_sentence_count += 1;
            }
        }

        // Flesch Reading Ease: 206.835 - 1.015 * (words/sentences) - 84.6 * (syllables/words)
        let words_per_sentence = (word_count as f64) / (sentence_count as f64);
        let syllables_per_word = (total_syllables as f64) / (word_count as f64);

        let mut flesch_reading_ease = 206.835 - (1.015 * words_per_sentence) - (84.6 * syllables_per_word);
        if flesch_reading_ease < 0.0 {
            flesch_reading_ease = 0.0;
        } else if flesch_reading_ease > 100.0 {
            flesch_reading_ease = 100.0;
        }

        // Flesch-Kincaid Grade Level: 0.39 * (words/sentences) + 11.8 * (syllables/words) - 15.59
        let mut flesch_kincaid_grade = (0.39 * words_per_sentence) + (11.8 * syllables_per_word) - 15.59;
        if flesch_kincaid_grade < 0.0 {
            flesch_kincaid_grade = 0.0;
        }

        // Readability Label
        let readability_label = match flesch_reading_ease {
            score if score >= 80.0 => "Very Easy (5th Grade)".to_string(),
            score if score >= 70.0 => "Easy (6th Grade)".to_string(),
            score if score >= 60.0 => "Standard (7th-8th Grade)".to_string(),
            score if score >= 50.0 => "Fairly Difficult (High School)".to_string(),
            score if score >= 30.0 => "Difficult (College)".to_string(),
            _ => "Very Difficult (Graduate)".to_string(),
        };

        // Overused words: words used >= 3 times that are not common stop words
        let stop_words: HashSet<&'static str> = [
            "the", "be", "to", "of", "and", "a", "in", "that", "have", "i", "it", "for", "not",
            "on", "with", "he", "as", "you", "do", "at", "this", "but", "his", "by", "from",
            "they", "we", "say", "her", "she", "or", "an", "will", "my", "one", "all", "would",
            "there", "their", "what", "so", "up", "out", "if", "about", "who", "get", "which",
            "go", "me", "is", "am", "are", "was", "were", "been", "has", "had",
        ]
        .iter()
        .copied()
        .collect();

        let mut overused: Vec<OverusedWord> = word_frequencies
            .into_iter()
            .filter(|(w, c)| *c >= 3 && !stop_words.contains(w.as_str()) && w.len() > 3)
            .map(|(word, count)| OverusedWord { word, count })
            .collect();

        overused.sort_by(|a, b| b.count.cmp(&a.count));
        overused.truncate(6);

        WritingInsights {
            word_count,
            char_count,
            sentence_count,
            paragraph_count,
            reading_time_minutes,
            flesch_reading_ease: (flesch_reading_ease * 10.0).round() / 10.0,
            flesch_kincaid_grade: (flesch_kincaid_grade * 10.0).round() / 10.0,
            readability_label,
            vocabulary_diversity: (vocabulary_diversity * 100.0).round() / 100.0,
            unique_words,
            overused_words: overused,
            average_sentence_length: (average_sentence_length * 10.0).round() / 10.0,
            long_sentence_count,
        }
    }

    /// Approximate English syllable counter using standard linguistic rules
    pub fn count_syllables(word: &str) -> usize {
        let w = word.to_lowercase();
        if w.len() <= 3 {
            return 1;
        }

        let mut count = 0;
        let mut prev_is_vowel = false;
        let vowels = ['a', 'e', 'i', 'o', 'u', 'y'];

        let chars: Vec<char> = w.chars().collect();
        let len = chars.len();

        for i in 0..len {
            let c = chars[i];
            let is_vowel = vowels.contains(&c);

            // Silent 'e' at the end of word (e.g. "game", "tone"), unless preceded by 'l' (like "apple", "bottle")
            if i == len - 1 && c == 'e' {
                if i >= 2 && chars[i - 1] == 'l' && !vowels.contains(&chars[i - 2]) {
                    count += 1;
                }
                break;
            }

            if is_vowel && !prev_is_vowel {
                count += 1;
            }
            prev_is_vowel = is_vowel;
        }

        if count == 0 {
            1
        } else {
            count
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_syllable_counter() {
        assert_eq!(InsightsEngine::count_syllables("cat"), 1);
        assert_eq!(InsightsEngine::count_syllables("apple"), 2);
        assert_eq!(InsightsEngine::count_syllables("beautiful"), 3);
        assert_eq!(InsightsEngine::count_syllables("understanding"), 4);
    }

    #[test]
    fn test_insights_analysis() {
        let text = "The quick brown fox jumps over the lazy dog. This is a very clean and simple document.";
        let insights = InsightsEngine::analyze(text);

        assert!(insights.word_count >= 15);
        assert_eq!(insights.sentence_count, 2);
        assert!(insights.flesch_reading_ease > 50.0);
        assert!(insights.vocabulary_diversity > 0.5);
    }
}
