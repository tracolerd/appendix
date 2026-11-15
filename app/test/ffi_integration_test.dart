import 'package:flutter_test/flutter_test.dart';
import 'package:appendix/core/ffi/grammar_models.dart';
import 'package:appendix/core/ffi/native_grammar_bindings.dart';

void main() {
  group('FFI Native Integration Tests', () {
    test('NativeGrammarEngine initializes and checks text', () {
      final engine = NativeGrammarEngine.instance;

      // Check whether native or rule fallback is active
      expect(engine.currentDialect, EnglishDialect.american);

      // 1. Test Indefinite Article Error
      final articleIssues = engine.checkText('This is an test.');
      expect(articleIssues, isNotEmpty, reason: 'Should flag "an test"');
      expect(
        articleIssues.any((i) => i.suggestions.any((s) => s.replacement.toLowerCase() == 'a')),
        isTrue,
        reason: 'Suggestion should contain "a"',
      );

      // 2. Test Dialect Detection (US vs UK)
      engine.setDialect(EnglishDialect.american);
      final usIssues = engine.checkText('The colour of the sky is blue.');
      expect(
        usIssues.any((i) => i.suggestions.any((s) => s.replacement.toLowerCase() == 'color')),
        isTrue,
        reason: 'US English should suggest "color" for "colour"',
      );

      engine.setDialect(EnglishDialect.british);
      final ukIssues = engine.checkText('The colour of the sky is blue.');
      expect(
        ukIssues.any((i) => i.suggestions.any((s) => s.replacement.toLowerCase() == 'color')),
        isFalse,
        reason: 'UK English should accept "colour"',
      );
    });
  });
}

