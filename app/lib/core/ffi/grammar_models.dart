import 'dart:convert';

/// Supported English dialects in Appendix.
enum EnglishDialect {
  american(0, 'American English (US)', 'US'),
  british(1, 'British English (UK)', 'UK');

  final int ffiValue;
  final String label;
  final String code;

  const EnglishDialect(this.ffiValue, this.label, this.code);
}

/// A specific suggestion for fixing a detected lint error.
class GrammarSuggestion {
  final String replacement;
  final String? description;

  const GrammarSuggestion({
    required this.replacement,
    this.description,
  });

  factory GrammarSuggestion.fromJson(Map<String, dynamic> json) {
    return GrammarSuggestion(
      replacement: json['replacement'] as String? ?? '',
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'replacement': replacement,
        'description': description,
      };
}

/// A lint issue detected by the engine within the user's text.
class LintIssue {
  final int start;
  final int end;
  final String message;
  final List<GrammarSuggestion> suggestions;
  final String lintKind;

  const LintIssue({
    required this.start,
    required this.end,
    required this.message,
    required this.suggestions,
    required this.lintKind,
  });

  factory LintIssue.fromJson(Map<String, dynamic> json) {
    final rawSuggestions = json['suggestions'] as List<dynamic>? ?? [];
    return LintIssue(
      start: json['start'] as int? ?? 0,
      end: json['end'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      suggestions: rawSuggestions
          .map((s) => GrammarSuggestion.fromJson(s as Map<String, dynamic>))
          .toList(),
      lintKind: json['lint_kind'] as String? ?? 'General',
    );
  }

  static List<LintIssue> parseList(String jsonString) {
    if (jsonString.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((item) => LintIssue.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Whether this issue is primarily a spelling mistake
  bool get isSpelling =>
      lintKind.toLowerCase().contains('spell') ||
      lintKind.toLowerCase().contains('wordchoice');

  /// Safe length of the error span
  int get length => (end >= start) ? (end - start) : 0;
}

/// Frequently repeated non-stop word
class OverusedWord {
  final String word;
  final int count;

  const OverusedWord({required this.word, required this.count});

  factory OverusedWord.fromJson(Map<String, dynamic> json) {
    return OverusedWord(
      word: json['word'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}

/// Comprehensive stylistic and readability insights computed offline
class WritingInsights {
  final int wordCount;
  final int charCount;
  final int sentenceCount;
  final int paragraphCount;
  final int readingTimeMinutes;
  final double fleschReadingEase;
  final double fleschKincaidGrade;
  final String readabilityLabel;
  final double vocabularyDiversity; // 0.0 - 1.0 (TTR)
  final int uniqueWords;
  final List<OverusedWord> overusedWords;
  final double averageSentenceLength;
  final int longSentenceCount;

  const WritingInsights({
    this.wordCount = 0,
    this.charCount = 0,
    this.sentenceCount = 0,
    this.paragraphCount = 0,
    this.readingTimeMinutes = 0,
    this.fleschReadingEase = 100.0,
    this.fleschKincaidGrade = 0.0,
    this.readabilityLabel = 'N/A',
    this.vocabularyDiversity = 1.0,
    this.uniqueWords = 0,
    this.overusedWords = const [],
    this.averageSentenceLength = 0.0,
    this.longSentenceCount = 0,
  });

  factory WritingInsights.fromJson(Map<String, dynamic> json) {
    final rawOverused = json['overused_words'] as List<dynamic>? ?? [];
    return WritingInsights(
      wordCount: json['word_count'] as int? ?? 0,
      charCount: json['char_count'] as int? ?? 0,
      sentenceCount: json['sentence_count'] as int? ?? 0,
      paragraphCount: json['paragraph_count'] as int? ?? 0,
      readingTimeMinutes: json['reading_time_minutes'] as int? ?? 0,
      fleschReadingEase: (json['flesch_reading_ease'] as num?)?.toDouble() ?? 100.0,
      fleschKincaidGrade: (json['flesch_kincaid_grade'] as num?)?.toDouble() ?? 0.0,
      readabilityLabel: json['readability_label'] as String? ?? 'Standard',
      vocabularyDiversity: (json['vocabulary_diversity'] as num?)?.toDouble() ?? 1.0,
      uniqueWords: json['unique_words'] as int? ?? 0,
      overusedWords: rawOverused
          .map((item) => OverusedWord.fromJson(item as Map<String, dynamic>))
          .toList(),
      averageSentenceLength: (json['average_sentence_length'] as num?)?.toDouble() ?? 0.0,
      longSentenceCount: json['long_sentence_count'] as int? ?? 0,
    );
  }

  static WritingInsights parse(String jsonString) {
    if (jsonString.trim().isEmpty) return const WritingInsights();
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return WritingInsights.fromJson(decoded);
    } catch (_) {
      return const WritingInsights();
    }
  }
}

/// Tone, mode, and structural transformation options
enum RewriteMode {
  rephrase(0, 'Rephrase', 'Rewrites clearly while keeping core meaning'),
  makeProfessional(1, 'Professional', 'Polished, authoritative business tone'),
  makeAcademic(2, 'Academic', 'Rigorous, objective scholarly voice'),
  makeFormal(3, 'Formal', 'Eliminates colloquialisms and slang'),
  makeCasual(4, 'Casual', 'Warm, friendly, and natural conversational tone'),
  makeConcise(5, 'Concise', 'Removes redundancy and tightens phrasing'),
  expand(6, 'Expand', 'Elaborates with nuanced, descriptive detail'),
  improveClarity(7, 'Improve Clarity', 'Untangles awkward and convoluted clauses'),
  improveVocabulary(8, 'Elevate Vocabulary', 'Upgrades repetitive and simple words'),
  simplify(9, 'Simplify', 'Plain language that anyone can easily read'),
  activeToPassive(10, 'Active to Passive', 'Converts into passive grammatical voice'),
  passiveToActive(11, 'Passive to Active', 'Converts into direct, active voice');

  final int ffiValue;
  final String title;
  final String description;

  const RewriteMode(this.ffiValue, this.title, this.description);
}

/// Output of an AI rewrite operation
class RewriteResult {
  final String original;
  final String revised;
  final String mode;
  final String engine;

  const RewriteResult({
    required this.original,
    required this.revised,
    required this.mode,
    required this.engine,
  });

  factory RewriteResult.fromJson(Map<String, dynamic> json) {
    return RewriteResult(
      original: json['original'] as String? ?? '',
      revised: json['revised'] as String? ?? '',
      mode: json['mode'] as String? ?? 'Rephrase',
      engine: json['engine'] as String? ?? 'Offline',
    );
  }

  static RewriteResult parse(String jsonString) {
    if (jsonString.trim().isEmpty) {
      return const RewriteResult(original: '', revised: '', mode: '', engine: '');
    }
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return RewriteResult.fromJson(decoded);
    } catch (_) {
      return const RewriteResult(original: '', revised: '', mode: '', engine: '');
    }
  }
}

/// Local SQLite history entry
class HistoryEntry {
  final int id;
  final String timestamp;
  final String content;
  final int wordCount;
  final double readabilityScore;

  const HistoryEntry({
    required this.id,
    required this.timestamp,
    required this.content,
    required this.wordCount,
    required this.readabilityScore,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as int? ?? 0,
      timestamp: json['timestamp'] as String? ?? '',
      content: json['content'] as String? ?? '',
      wordCount: json['word_count'] as int? ?? 0,
      readabilityScore: (json['readability_score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static List<HistoryEntry> parseList(String jsonString) {
    if (jsonString.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((item) => HistoryEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
