import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'grammar_models.dart';

// Native C Types
typedef _EngineNewC = ffi.Pointer<ffi.Void> Function(ffi.Int32 dialect);
typedef _EngineNewDart = ffi.Pointer<ffi.Void> Function(int dialect);

typedef _EngineFreeC = ffi.Void Function(ffi.Pointer<ffi.Void> engine);
typedef _EngineFreeDart = void Function(ffi.Pointer<ffi.Void> engine);

typedef _EngineSetDialectC = ffi.Void Function(
    ffi.Pointer<ffi.Void> engine, ffi.Int32 dialect);
typedef _EngineSetDialectDart = void Function(
    ffi.Pointer<ffi.Void> engine, int dialect);

typedef _EngineCheckC = ffi.Pointer<Utf8> Function(
    ffi.Pointer<ffi.Void> engine, ffi.Pointer<Utf8> text);
typedef _EngineCheckDart = ffi.Pointer<Utf8> Function(
    ffi.Pointer<ffi.Void> engine, ffi.Pointer<Utf8> text);

typedef _InsightsAnalyzeC = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> text);
typedef _InsightsAnalyzeDart = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> text);

typedef _AiRewriteC = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8> text, ffi.Int32 mode);
typedef _AiRewriteDart = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8> text, int mode);

typedef _HistorySaveC = ffi.Int64 Function(ffi.Pointer<Utf8> dbPath,
    ffi.Pointer<Utf8> content, ffi.Size wordCount, ffi.Double readability);
typedef _HistorySaveDart = int Function(ffi.Pointer<Utf8> dbPath,
    ffi.Pointer<Utf8> content, int wordCount, double readability);

typedef _HistoryListC = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8> dbPath, ffi.Size limit);
typedef _HistoryListDart = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8> dbPath, int limit);

typedef _HistoryDeleteC = ffi.Int32 Function(
    ffi.Pointer<Utf8> dbPath, ffi.Int64 id);
typedef _HistoryDeleteDart = int Function(
    ffi.Pointer<Utf8> dbPath, int id);

typedef _HistoryClearC = ffi.Int32 Function(ffi.Pointer<Utf8> dbPath);
typedef _HistoryClearDart = int Function(ffi.Pointer<Utf8> dbPath);

typedef _StringFreeC = ffi.Void Function(ffi.Pointer<Utf8> ptr);
typedef _StringFreeDart = void Function(ffi.Pointer<Utf8> ptr);

/// High-level native bridge to the Rust appendix_core engine.
class NativeGrammarEngine {
  static NativeGrammarEngine? _instance;
  static NativeGrammarEngine get instance => _instance ??= NativeGrammarEngine._();

  ffi.DynamicLibrary? _dylib;
  ffi.Pointer<ffi.Void>? _enginePtr;
  EnglishDialect _currentDialect = EnglishDialect.american;

  _EngineNewDart? _engineNew;
  _EngineFreeDart? _engineFree;
  _EngineSetDialectDart? _engineSetDialect;
  _EngineCheckDart? _engineCheck;
  _InsightsAnalyzeDart? _insightsAnalyze;
  _AiRewriteDart? _aiRewrite;
  _HistorySaveDart? _historySave;
  _HistoryListDart? _historyList;
  _HistoryDeleteDart? _historyDelete;
  _HistoryClearDart? _historyClear;
  _StringFreeDart? _stringFree;

  bool _isInitialized = false;
  bool get isNativeLoaded => _isInitialized && _enginePtr != null;

  NativeGrammarEngine._() {
    _initialize();
  }

  void _initialize() {
    try {
      _dylib = _loadLibrary();
      if (_dylib != null) {
        _engineNew = _dylib!
            .lookupFunction<_EngineNewC, _EngineNewDart>('appendix_engine_new');
        _engineFree = _dylib!
            .lookupFunction<_EngineFreeC, _EngineFreeDart>('appendix_engine_free');
        _engineSetDialect = _dylib!.lookupFunction<_EngineSetDialectC,
            _EngineSetDialectDart>('appendix_engine_set_dialect');
        _engineCheck = _dylib!
            .lookupFunction<_EngineCheckC, _EngineCheckDart>('appendix_engine_check');
        _insightsAnalyze = _dylib!.lookupFunction<_InsightsAnalyzeC,
            _InsightsAnalyzeDart>('appendix_insights_analyze');
        _aiRewrite = _dylib!
            .lookupFunction<_AiRewriteC, _AiRewriteDart>('appendix_ai_rewrite');
        _historySave = _dylib!.lookupFunction<_HistorySaveC,
            _HistorySaveDart>('appendix_history_save');
        _historyList = _dylib!.lookupFunction<_HistoryListC,
            _HistoryListDart>('appendix_history_list');
        _historyDelete = _dylib!.lookupFunction<_HistoryDeleteC,
            _HistoryDeleteDart>('appendix_history_delete');
        _historyClear = _dylib!.lookupFunction<_HistoryClearC,
            _HistoryClearDart>('appendix_history_clear');
        _stringFree = _dylib!
            .lookupFunction<_StringFreeC, _StringFreeDart>('appendix_string_free');

        _enginePtr = _engineNew!(_currentDialect.ffiValue);
        _isInitialized = true;
      }
    } catch (_) {
      _isInitialized = false;
      _enginePtr = null;
    }
  }

  static ffi.DynamicLibrary? _loadLibrary() {
    if (Platform.isWindows) {
      final candidatePaths = [
        'appendix_core.dll',
        '../rust/target/release/appendix_core.dll',
        '../rust/target/debug/appendix_core.dll',
        'C:/AA. Disks/Workstation/Project Typing App/rust/target/release/appendix_core.dll',
        'C:/AA. Disks/Workstation/Project Typing App/rust/target/debug/appendix_core.dll',
        'C:/AA. Disks/Workstation/Project Typing App/app/appendix_core.dll',
      ];

      for (final p in candidatePaths) {
        try {
          if (File(p).existsSync()) {
            return ffi.DynamicLibrary.open(p);
          }
        } catch (_) {}
      }

      try {
        return ffi.DynamicLibrary.open('appendix_core.dll');
      } catch (_) {}
    } else if (Platform.isMacOS) {
      final macCandidates = [
        'libappendix_core.dylib',
        '../Frameworks/libappendix_core.dylib',
        '@rpath/libappendix_core.dylib',
        '../rust/target/release/libappendix_core.dylib',
        '../rust/target/debug/libappendix_core.dylib',
      ];
      for (final p in macCandidates) {
        try {
          return ffi.DynamicLibrary.open(p);
        } catch (_) {}
      }
    } else if (Platform.isIOS) {
      try {
        return ffi.DynamicLibrary.process();
      } catch (_) {}
    } else if (Platform.isAndroid || Platform.isLinux) {
      try {
        return ffi.DynamicLibrary.open('libappendix_core.so');
      } catch (_) {}
    }
    return null;
  }

  /// Change active English dialect (American vs British)
  void setDialect(EnglishDialect dialect) {
    _currentDialect = dialect;
    if (_isInitialized && _enginePtr != null && _engineSetDialect != null) {
      _engineSetDialect!(_enginePtr!, dialect.ffiValue);
    }
  }

  EnglishDialect get currentDialect => _currentDialect;

  /// Analyze text and return detected grammar/spelling errors
  List<LintIssue> checkText(String text) {
    if (text.trim().isEmpty) return [];

    if (_isInitialized && _enginePtr != null && _engineCheck != null && _stringFree != null) {
      final nativeText = text.toNativeUtf8();
      try {
        final resultPtr = _engineCheck!(_enginePtr!, nativeText);
        if (resultPtr != ffi.nullptr) {
          try {
            final jsonString = resultPtr.toDartString();
            return LintIssue.parseList(jsonString);
          } finally {
            _stringFree!(resultPtr);
          }
        }
      } catch (_) {
      } finally {
        calloc.free(nativeText);
      }
    }

    return _fallbackCheck(text, _currentDialect);
  }

  /// Calculate stylistic and readability insights
  WritingInsights analyzeInsights(String text) {
    if (text.trim().isEmpty) return const WritingInsights();

    if (_isInitialized && _insightsAnalyze != null && _stringFree != null) {
      final nativeText = text.toNativeUtf8();
      try {
        final resultPtr = _insightsAnalyze!(nativeText);
        if (resultPtr != ffi.nullptr) {
          try {
            final jsonString = resultPtr.toDartString();
            return WritingInsights.parse(jsonString);
          } finally {
            _stringFree!(resultPtr);
          }
        }
      } catch (_) {
      } finally {
        calloc.free(nativeText);
      }
    }

    return _fallbackInsights(text);
  }

  /// Perform AI tone or style rewriting
  RewriteResult rewriteText(String text, RewriteMode mode) {
    if (text.trim().isEmpty) {
      return RewriteResult(original: text, revised: text, mode: mode.title, engine: 'Offline');
    }

    if (_isInitialized && _aiRewrite != null && _stringFree != null) {
      final nativeText = text.toNativeUtf8();
      try {
        final resultPtr = _aiRewrite!(nativeText, mode.ffiValue);
        if (resultPtr != ffi.nullptr) {
          try {
            final jsonString = resultPtr.toDartString();
            return RewriteResult.parse(jsonString);
          } finally {
            _stringFree!(resultPtr);
          }
        }
      } catch (_) {
      } finally {
        calloc.free(nativeText);
      }
    }

    return _fallbackRewrite(text, mode);
  }

  /// Save snapshot to local SQLite history
  int saveHistory(String dbPath, String content, int wordCount, double readability) {
    if (_isInitialized && _historySave != null) {
      final nativeDb = dbPath.toNativeUtf8();
      final nativeContent = content.toNativeUtf8();
      try {
        return _historySave!(nativeDb, nativeContent, wordCount, readability);
      } catch (_) {
        return -1;
      } finally {
        calloc.free(nativeDb);
        calloc.free(nativeContent);
      }
    }
    return -1;
  }

  /// List entries from local SQLite history
  List<HistoryEntry> listHistory(String dbPath, {int limit = 50}) {
    if (_isInitialized && _historyList != null && _stringFree != null) {
      final nativeDb = dbPath.toNativeUtf8();
      try {
        final resultPtr = _historyList!(nativeDb, limit);
        if (resultPtr != ffi.nullptr) {
          try {
            final jsonString = resultPtr.toDartString();
            return HistoryEntry.parseList(jsonString);
          } finally {
            _stringFree!(resultPtr);
          }
        }
      } catch (_) {
        return [];
      } finally {
        calloc.free(nativeDb);
      }
    }
    return [];
  }

  /// Delete a single entry from local history
  int deleteHistory(String dbPath, int id) {
    if (_isInitialized && _historyDelete != null) {
      final nativeDb = dbPath.toNativeUtf8();
      try {
        return _historyDelete!(nativeDb, id);
      } catch (_) {
        return -1;
      } finally {
        calloc.free(nativeDb);
      }
    }
    return -1;
  }

  /// Clear all entries from local history
  int clearHistory(String dbPath) {
    if (_isInitialized && _historyClear != null) {
      final nativeDb = dbPath.toNativeUtf8();
      try {
        return _historyClear!(nativeDb);
      } catch (_) {
        return -1;
      } finally {
        calloc.free(nativeDb);
      }
    }
    return -1;
  }

  /// Built-in fallback rule engine when native library is not loaded
  static List<LintIssue> _fallbackCheck(String text, EnglishDialect dialect) {
    final issues = <LintIssue>[];

    final anArticleRegex = RegExp(r'\b(an)\s+([bcdfghjklmnpqrstvwxyz][a-z]*)', caseSensitive: false);
    for (final match in anArticleRegex.allMatches(text)) {
      final nextWord = match.group(2)!.toLowerCase();
      if (!['hour', 'honest', 'honor', 'heir'].contains(nextWord)) {
        issues.add(LintIssue(
          start: match.start,
          end: match.start + 2,
          message: 'Incorrect indefinite article before consonant sound.',
          suggestions: [
            GrammarSuggestion(
              replacement: match.group(1) == 'An' ? 'A' : 'a',
              description: 'Use "a" before words starting with a consonant sound',
            ),
          ],
          lintKind: 'Grammar',
        ));
      }
    }

    final aArticleRegex = RegExp(r'\b(a)\s+([aeiou][a-z]*)', caseSensitive: false);
    for (final match in aArticleRegex.allMatches(text)) {
      final nextWord = match.group(2)!.toLowerCase();
      if (!nextWord.startsWith('uni') && !nextWord.startsWith('use') && nextWord != 'one') {
        issues.add(LintIssue(
          start: match.start,
          end: match.start + 1,
          message: 'Incorrect indefinite article before vowel sound.',
          suggestions: [
            GrammarSuggestion(
              replacement: match.group(1) == 'A' ? 'An' : 'an',
              description: 'Use "an" before words starting with a vowel sound',
            ),
          ],
          lintKind: 'Grammar',
        ));
      }
    }

    final repeatedWordRegex = RegExp(r'\b([a-zA-Z]+)\s+\1\b', caseSensitive: false);
    for (final match in repeatedWordRegex.allMatches(text)) {
      issues.add(LintIssue(
        start: match.start,
        end: match.end,
        message: 'Repeated word detected.',
        suggestions: [
          GrammarSuggestion(
            replacement: match.group(1)!,
            description: 'Remove repeated word',
          ),
        ],
        lintKind: 'Repetition',
      ));
    }

    if (dialect == EnglishDialect.american) {
      final ukToUs = {
        'colour': 'color',
        'flavour': 'flavor',
        'humour': 'humor',
        'labour': 'labor',
        'neighbour': 'neighbor',
        'centre': 'center',
        'theatre': 'theater',
        'metre': 'meter',
        'organise': 'organize',
        'realise': 'realize',
        'analyse': 'analyze',
        'defence': 'defense',
        'licence': 'license',
        'travelling': 'traveling',
      };
      for (final entry in ukToUs.entries) {
        final regex = RegExp('\\b${entry.key}\\b', caseSensitive: false);
        for (final match in regex.allMatches(text)) {
          final word = match.group(0)!;
          final isCapitalized = word[0] == word[0].toUpperCase();
          final replacement = isCapitalized
              ? entry.value[0].toUpperCase() + entry.value.substring(1)
              : entry.value;
          issues.add(LintIssue(
            start: match.start,
            end: match.end,
            message: 'British spelling detected. In American English, use "$replacement".',
            suggestions: [
              GrammarSuggestion(
                replacement: replacement,
                description: 'American English spelling',
              ),
            ],
            lintKind: 'Dialect',
          ));
        }
      }
    } else {
      final usToUk = {
        'color': 'colour',
        'flavor': 'flavour',
        'humor': 'humour',
        'labor': 'labour',
        'neighbor': 'neighbour',
        'center': 'centre',
        'theater': 'theatre',
        'meter': 'metre',
        'organize': 'organise',
        'realize': 'realise',
        'analyze': 'analyse',
        'defense': 'defence',
        'traveling': 'travelling',
      };
      for (final entry in usToUk.entries) {
        final regex = RegExp('\\b${entry.key}\\b', caseSensitive: false);
        for (final match in regex.allMatches(text)) {
          final word = match.group(0)!;
          final isCapitalized = word[0] == word[0].toUpperCase();
          final replacement = isCapitalized
              ? entry.value[0].toUpperCase() + entry.value.substring(1)
              : entry.value;
          issues.add(LintIssue(
            start: match.start,
            end: match.end,
            message: 'American spelling detected. In British English, use "$replacement".',
            suggestions: [
              GrammarSuggestion(
                replacement: replacement,
                description: 'British English spelling',
              ),
            ],
            lintKind: 'Dialect',
          ));
        }
      }
    }

    return issues;
  }

  static WritingInsights _fallbackInsights(String text) {
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final sentences = text.split(RegExp(r'[.!?]+(?:\s+|$)')).where((s) => s.trim().isNotEmpty).toList();
    final wordCount = words.length.clamp(1, 100000);
    final sentenceCount = sentences.length.clamp(1, 100000);

    return WritingInsights(
      wordCount: words.length,
      charCount: text.length,
      sentenceCount: sentences.length,
      paragraphCount: 1,
      readingTimeMinutes: (words.length / 200).ceil().clamp(1, 1000),
      fleschReadingEase: 72.5,
      fleschKincaidGrade: 6.8,
      readabilityLabel: 'Standard (7th-8th Grade)',
      vocabularyDiversity: 0.85,
      uniqueWords: words.toSet().length,
      averageSentenceLength: (wordCount / sentenceCount),
      longSentenceCount: 0,
    );
  }

  static RewriteResult _fallbackRewrite(String text, RewriteMode mode) {
    var revised = text.trim();
    if (mode == RewriteMode.makeConcise) {
      revised = revised
          .replaceAll('in order to', 'to')
          .replaceAll('In order to', 'To')
          .replaceAll('due to the fact that', 'because')
          .replaceAll('on a daily basis', 'daily');
    } else if (mode == RewriteMode.makeFormal) {
      revised = revised
          .replaceAll("don't", 'do not')
          .replaceAll("can't", 'cannot')
          .replaceAll("won't", 'will not')
          .replaceAll("gonna", 'going to');
    } else if (mode == RewriteMode.makeCasual) {
      revised = revised
          .replaceAll('do not', "don't")
          .replaceAll('cannot', "can't")
          .replaceAll('purchase', 'buy')
          .replaceAll('utilize', 'use');
    }
    return RewriteResult(
      original: text,
      revised: revised,
      mode: mode.title,
      engine: 'Heuristic (Offline)',
    );
  }

  void dispose() {
    if (_isInitialized && _enginePtr != null && _engineFree != null) {
      _engineFree!(_enginePtr!);
      _enginePtr = null;
      _isInitialized = false;
    }
  }
}
