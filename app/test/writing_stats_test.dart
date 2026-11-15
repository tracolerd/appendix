import 'package:flutter_test/flutter_test.dart';
import 'package:appendix/features/editor/controllers/writing_editor_controller.dart';

void main() {
  group('WritingStats Tests', () {
    test('Calculates accurate metrics for empty text', () {
      final stats = WritingStats.fromText('');
      expect(stats.wordCount, 0);
      expect(stats.charCount, 0);
      expect(stats.sentenceCount, 0);
      expect(stats.paragraphCount, 0);
    });

    test('Calculates metrics for sample paragraph', () {
      const text =
          'This is the first sentence. Here is the second sentence! And a third?';
      final stats = WritingStats.fromText(text);

      expect(stats.wordCount, 13);
      expect(stats.sentenceCount, 3);
      expect(stats.paragraphCount, 1);
      expect(stats.charCount, text.length);
      expect(stats.readingTimeMinutes, 1);
    });

    test('Calculates multiple paragraphs correctly', () {
      const text = 'Paragraph one.\n\nParagraph two.\n\nParagraph three.';
      final stats = WritingStats.fromText(text);

      expect(stats.paragraphCount, 3);
      expect(stats.sentenceCount, 3);
      expect(stats.wordCount, 6);
    });
  });
}
