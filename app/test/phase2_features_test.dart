import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:appendix/core/ffi/grammar_models.dart';
import 'package:appendix/core/ffi/native_grammar_bindings.dart';

void main() {
  group('Phase 2 Features Tests', () {
    test('WritingInsights calculates metrics and parses correctly', () {
      final engine = NativeGrammarEngine.instance;
      const sampleText =
          'This is an insightful test paragraph. The software provides great clarity and high quality analysis.';
      final insights = engine.analyzeInsights(sampleText);

      expect(insights.wordCount, greaterThan(10));
      expect(insights.sentenceCount, greaterThan(0));
      expect(insights.fleschReadingEase, greaterThan(0.0));
      expect(insights.vocabularyDiversity, greaterThan(0.0));
      expect(insights.readabilityLabel, isNotEmpty);
    });

    test('AI Rewrite transforms text using specified tone mode', () {
      final engine = NativeGrammarEngine.instance;

      // 1. Test Concise Mode
      const verboseText = 'In order to succeed, we must practice on a daily basis.';
      final conciseResult = engine.rewriteText(verboseText, RewriteMode.makeConcise);
      expect(conciseResult.revised.toLowerCase().contains('in order to'), isFalse);
      expect(conciseResult.mode.contains('Concise'), isTrue);

      // 2. Test Formal Mode
      const informalText = "We don't wanna do this.";
      final formalResult = engine.rewriteText(informalText, RewriteMode.makeFormal);
      expect(formalResult.revised.contains("don't"), isFalse);
      expect(formalResult.mode.contains('Formal'), isTrue);

      // 3. Test Casual Mode
      const rigidText = 'You must utilize this tool.';
      final casualResult = engine.rewriteText(rigidText, RewriteMode.makeCasual);
      expect(casualResult.revised, isNotEmpty);
      if (casualResult.engine.toLowerCase().contains('heuristic')) {
        expect(casualResult.revised.contains('utilize'), isFalse);
      }
      expect(casualResult.mode.contains('Casual'), isTrue);
    });

    test('Local History saves, retrieves, and clears entries', () {
      final engine = NativeGrammarEngine.instance;
      final tempDb = '${Directory.systemTemp.path}/test_app_history_${DateTime.now().millisecondsSinceEpoch}.db';

      // 1. Save entry
      final id1 = engine.saveHistory(tempDb, 'Draft sample 1', 3, 75.0);
      final id2 = engine.saveHistory(tempDb, 'Draft sample 2', 3, 80.0);

      if (engine.isNativeLoaded) {
        expect(id1, greaterThan(0));
        expect(id2, greaterThan(id1));

        // 2. List entries
        final entries = engine.listHistory(tempDb);
        expect(entries.length, 2);
        expect(entries.first.content, 'Draft sample 2');

        // 3. Delete single entry
        final delCode = engine.deleteHistory(tempDb, id1);
        expect(delCode, 0);

        final entriesAfterDel = engine.listHistory(tempDb);
        expect(entriesAfterDel.length, 1);

        // 4. Clear all
        final clearCode = engine.clearHistory(tempDb);
        expect(clearCode, 0);

        final entriesAfterClear = engine.listHistory(tempDb);
        expect(entriesAfterClear.isEmpty, isTrue);

        final dbFile = File(tempDb);
        if (dbFile.existsSync()) {
          dbFile.deleteSync();
        }
      }
    });
  });
}
