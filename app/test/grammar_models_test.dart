import 'package:flutter_test/flutter_test.dart';
import 'package:appendix/core/ffi/grammar_models.dart';

void main() {
  group('GrammarModels Tests', () {
    test('LintIssue parses JSON correctly', () {
      const json = '''
      [
        {
          "start": 8,
          "end": 10,
          "message": "Incorrect indefinite article.",
          "suggestions": [
            {"replacement": "a", "description": "Use 'a' before consonants"}
          ],
          "lint_kind": "Grammar"
        }
      ]
      ''';

      final issues = LintIssue.parseList(json);
      expect(issues.length, 1);
      expect(issues.first.start, 8);
      expect(issues.first.end, 10);
      expect(issues.first.length, 2);
      expect(issues.first.message, 'Incorrect indefinite article.');
      expect(issues.first.suggestions.length, 1);
      expect(issues.first.suggestions.first.replacement, 'a');
      expect(issues.first.suggestions.first.description, "Use 'a' before consonants");
      expect(issues.first.isSpelling, isFalse);
    });

    test('LintIssue identifies spelling issues', () {
      final issue = LintIssue(
        start: 0,
        end: 5,
        message: 'Misspelled word',
        suggestions: [
          const GrammarSuggestion(replacement: 'color'),
        ],
        lintKind: 'Spelling',
      );

      expect(issue.isSpelling, isTrue);
    });

    test('EnglishDialect enums have expected values', () {
      expect(EnglishDialect.american.ffiValue, 0);
      expect(EnglishDialect.british.ffiValue, 1);
      expect(EnglishDialect.american.code, 'US');
      expect(EnglishDialect.british.code, 'UK');
    });
  });
}

