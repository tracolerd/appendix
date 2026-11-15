import 'package:flutter_test/flutter_test.dart';
import 'package:appendix/core/ffi/grammar_models.dart';
import 'package:appendix/features/editor/controllers/writing_editor_controller.dart';

void main() {
  group('WritingEditorController Tests', () {
    test('Initializes with provided text and calculates stats', () {
      final controller = WritingEditorController(
        text: 'The quick brown fox jumps over the lazy dog.',
      );

      expect(controller.stats.wordCount, 9);
      expect(controller.stats.sentenceCount, 1);
      controller.dispose();
    });

    test('Applies suggestion and updates text and cursor position', () {
      final controller = WritingEditorController(
        text: 'This is an test sentence.',
      );

      const issue = LintIssue(
        start: 8,
        end: 10,
        message: 'Incorrect indefinite article',
        suggestions: [
          GrammarSuggestion(replacement: 'a'),
        ],
        lintKind: 'Grammar',
      );

      controller.applySuggestion(issue, issue.suggestions.first);

      expect(controller.text, 'This is a test sentence.');
      expect(controller.selection.baseOffset, 9);
      controller.dispose();
    });

    test('Ignores issue properly', () {
      final controller = WritingEditorController(
        text: 'This is an test sentence.',
      );

      const issue = LintIssue(
        start: 8,
        end: 10,
        message: 'Incorrect indefinite article',
        suggestions: [
          GrammarSuggestion(replacement: 'a'),
        ],
        lintKind: 'Grammar',
      );

      controller.ignoreIssue(issue);
      expect(controller.issues.contains(issue), isFalse);
      controller.dispose();
    });

    test('Dialect switching triggers re-analysis', () {
      final controller = WritingEditorController(
        text: 'The colour of the car.',
      );

      controller.setDialect(EnglishDialect.british);
      expect(controller.dialect, EnglishDialect.british);

      controller.setDialect(EnglishDialect.american);
      expect(controller.dialect, EnglishDialect.american);

      controller.dispose();
    });
  });
}

