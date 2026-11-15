import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/ffi/grammar_models.dart';
import '../../../core/ffi/native_grammar_bindings.dart';
import '../../../core/theme/app_theme.dart';

class WritingStats {
  final int wordCount;
  final int charCount;
  final int charCountNoSpaces;
  final int sentenceCount;
  final int paragraphCount;
  final int readingTimeMinutes;

  const WritingStats({
    this.wordCount = 0,
    this.charCount = 0,
    this.charCountNoSpaces = 0,
    this.sentenceCount = 0,
    this.paragraphCount = 0,
    this.readingTimeMinutes = 0,
  });

  factory WritingStats.fromText(String text) {
    if (text.trim().isEmpty) return const WritingStats();

    final charCount = text.length;
    final charCountNoSpaces = text.replaceAll(RegExp(r'\s+'), '').length;

    // Word count based on whitespace boundaries
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final wordCount = words.length;

    // Sentence count
    final sentences = text
        .split(RegExp(r'[.!?]+(?:\s+|$)'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final sentenceCount = sentences.isEmpty ? (text.trim().isNotEmpty ? 1 : 0) : sentences.length;

    // Paragraph count
    final paragraphs = text
        .split(RegExp(r'\n+'))
        .where((p) => p.trim().isNotEmpty)
        .toList();
    final paragraphCount = paragraphs.isEmpty ? (text.trim().isNotEmpty ? 1 : 0) : paragraphs.length;

    // Reading time (average 200 words per minute)
    final readingTimeMinutes = (wordCount / 200).ceil();

    return WritingStats(
      wordCount: wordCount,
      charCount: charCount,
      charCountNoSpaces: charCountNoSpaces,
      sentenceCount: sentenceCount,
      paragraphCount: paragraphCount,
      readingTimeMinutes: readingTimeMinutes > 0 ? readingTimeMinutes : 1,
    );
  }
}

class WritingEditorController extends TextEditingController {
  final NativeGrammarEngine _engine = NativeGrammarEngine.instance;

  Timer? _debounceTimer;
  List<LintIssue> _issues = [];
  final Set<String> _ignoredFingerprints = {};
  LintIssue? _selectedIssue;

  WritingStats _stats = const WritingStats();
  bool _isAnalyzing = false;

  List<LintIssue> get issues => List.unmodifiable(_issues);
  LintIssue? get selectedIssue => _selectedIssue;
  WritingStats get stats => _stats;
  bool get isAnalyzing => _isAnalyzing;
  EnglishDialect get dialect => _engine.currentDialect;

  final void Function()? onIssuesUpdated;

  WritingEditorController({String? text, this.onIssuesUpdated}) : super(text: text) {
    addListener(_onTextChanged);
    if (text != null && text.isNotEmpty) {
      _analyzeImmediately();
    }
  }

  void _onTextChanged() {
    _stats = WritingStats.fromText(text);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _runAnalysis();
    });
  }

  void setDialect(EnglishDialect newDialect) {
    _engine.setDialect(newDialect);
    _analyzeImmediately();
  }

  void selectIssue(LintIssue? issue) {
    _selectedIssue = issue;
    notifyListeners();
  }

  void applySuggestion(LintIssue issue, GrammarSuggestion suggestion) {
    if (issue.start < 0 || issue.end > text.length || issue.start > issue.end) {
      return;
    }

    final prefix = text.substring(0, issue.start);
    final suffix = text.substring(issue.end);
    final newText = prefix + suggestion.replacement + suffix;

    final newCursorPos = issue.start + suggestion.replacement.length;

    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );

    _selectedIssue = null;
    _analyzeImmediately();
  }

  void ignoreIssue(LintIssue issue) {
    final fingerprint = '${issue.start}_${issue.end}_${issue.message}';
    _ignoredFingerprints.add(fingerprint);
    _issues.removeWhere((i) => i.start == issue.start && i.end == issue.end);
    _selectedIssue = null;
    notifyListeners();
    onIssuesUpdated?.call();
  }

  void _analyzeImmediately() {
    _debounceTimer?.cancel();
    _runAnalysis();
  }

  void _runAnalysis() {
    if (text.trim().isEmpty) {
      _issues = [];
      _selectedIssue = null;
      notifyListeners();
      onIssuesUpdated?.call();
      return;
    }

    _isAnalyzing = true;
    notifyListeners();

    try {
      final rawIssues = _engine.checkText(text);
      // Filter out ignored
      _issues = rawIssues.where((issue) {
        final fingerprint = '${issue.start}_${issue.end}_${issue.message}';
        return !_ignoredFingerprints.contains(fingerprint);
      }).toList();

      // If selected issue is no longer valid, clear it
      if (_selectedIssue != null) {
        final exists = _issues.any((i) =>
            i.start == _selectedIssue!.start && i.end == _selectedIssue!.end);
        if (!exists) {
          _selectedIssue = null;
        }
      }
    } finally {
      _isAnalyzing = false;
      notifyListeners();
      onIssuesUpdated?.call();
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (_issues.isEmpty || text.isEmpty) {
      return TextSpan(text: text, style: style);
    }

    final spans = <InlineSpan>[];
    int currentOffset = 0;

    // Sort issues by start offset to render in linear order
    final sortedIssues = List<LintIssue>.from(_issues)
      ..sort((a, b) => a.start.compareTo(b.start));

    for (final issue in sortedIssues) {
      // Validate offsets
      if (issue.start < currentOffset || issue.end > text.length || issue.start >= issue.end) {
        continue;
      }

      // Add regular unhighlighted text before the issue
      if (issue.start > currentOffset) {
        spans.add(TextSpan(
          text: text.substring(currentOffset, issue.start),
          style: style,
        ));
      }

      // Add highlighted text with squiggly error underline
      final isSelected = _selectedIssue != null &&
          _selectedIssue!.start == issue.start &&
          _selectedIssue!.end == issue.end;

      final underlineColor = issue.isSpelling
          ? AppendixTheme.errorRed
          : AppendixTheme.warningAmber;

      spans.add(TextSpan(
        text: text.substring(issue.start, issue.end),
        style: style?.copyWith(
          backgroundColor: isSelected ? underlineColor.withValues(alpha: 0.15) : null,
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.wavy,
          decorationColor: underlineColor,
          decorationThickness: 1.8,
        ),
      ));

      currentOffset = issue.end;
    }

    // Trailing unhighlighted text
    if (currentOffset < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentOffset),
        style: style,
      ));
    }

    return TextSpan(children: spans, style: style);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    removeListener(_onTextChanged);
    super.dispose();
  }
}

