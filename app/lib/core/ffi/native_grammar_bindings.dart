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
        _stringFree = _dylib!
            .lookupFunction<_StringFreeC, _StringFreeDart>('appendix_string_free');

        _enginePtr = _engineNew!(_currentDialect.ffiValue);
        _isInitialized = true;
      }
    } catch (e) {
      // Graceful fallback to pure-Dart engine
      _isInitialized = false;
      _enginePtr = null;
    }
  }

  static ffi.DynamicLibrary? _loadLibrary() {
    if (Platform.isWindows) {
      // Possible locations for appendix_core.dll
      final candidatePaths = [
        'appendix_core.dll',
        // When running from project root or IDE
        '../rust/target/release/appendix_core.dll',
        '../rust/target/debug/appendix_core.dll',
        'C:/AA. Disks/Workstation/Project Typing App/rust/target/release/appendix_core.dll',
        'C:/AA. Disks/Workstation/Project Typing App/rust/target/debug/appendix_core.dll',
      ];

      for (final p in candidatePaths) {
        try {
          if (File(p).existsSync()) {
            return ffi.DynamicLibrary.open(p);
          }
        } catch (_) {}
      }

      // Try default dynamic lookup
      try {
        return ffi.DynamicLibrary.open('appendix_core.dll');
      } catch (_) {}
    } else if (Platform.isMacOS) {
      try {
        return ffi.DynamicLibrary.open('libappendix_core.dylib');
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
        // Fall back to rule-based engine if native execution encounters an issue
      } finally {
        calloc.free(nativeText);
      }
    }

    // Built-in rule-based fallback
    return _fallbackCheck(text, _currentDialect);
  }

  /// Built-in fallback rule engine when native library is not loaded
  static List<LintIssue> _fallbackCheck(String text, EnglishDialect dialect) {
    final issues = <LintIssue>[];

    // 1. Indefinite article check ("an test" -> "a test")
    final anArticleRegex = RegExp(r'\b(an)\s+([bcdfghjklmnpqrstvwxyz][a-z]*)', caseSensitive: false);
    for (final match in anArticleRegex.allMatches(text)) {
      final nextWord = match.group(2)!.toLowerCase();
      // Exceptions like "honest", "hour", etc.
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

    // 2. Indefinite article check ("a apple" -> "an apple")
    final aArticleRegex = RegExp(r'\b(a)\s+([aeiou][a-z]*)', caseSensitive: false);
    for (final match in aArticleRegex.allMatches(text)) {
      final nextWord = match.group(2)!.toLowerCase();
      // Exceptions like "university", "unique", "one", "user"
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

    // 3. Repeated word check ("the the", "is is")
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

    // 4. Dialect differences
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

  void dispose() {
    if (_isInitialized && _enginePtr != null && _engineFree != null) {
      _engineFree!(_enginePtr!);
      _enginePtr = null;
      _isInitialized = false;
    }
  }
}

