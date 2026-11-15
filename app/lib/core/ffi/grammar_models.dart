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

