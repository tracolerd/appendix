import 'dart:isolate';
import '../ffi/grammar_models.dart';
import '../ffi/native_grammar_bindings.dart';

/// Top-level function executed on a dedicated background isolate for AI rewriting.
RewriteResult _isolateRewriteEntry(_RewriteTaskArgs args) {
  final engine = NativeGrammarEngine.instance;
  return engine.rewriteText(args.text, args.mode);
}

/// Top-level function executed on a dedicated background isolate for model loading.
AiModelStatus _isolateLoadModelEntry(_LoadModelTaskArgs args) {
  final engine = NativeGrammarEngine.instance;
  return engine.loadAiModel(
    args.modelPath,
    args.tokenizerPath,
    verifyChecksum: args.verifyChecksum,
  );
}

class _RewriteTaskArgs {
  final String text;
  final RewriteMode mode;

  const _RewriteTaskArgs(this.text, this.mode);
}

class _LoadModelTaskArgs {
  final String modelPath;
  final String tokenizerPath;
  final bool verifyChecksum;

  const _LoadModelTaskArgs(this.modelPath, this.tokenizerPath, this.verifyChecksum);
}

/// Dedicated background AI worker service managing isolates, concurrency, and cancellation.
class AiWorkerService {
  static AiWorkerService? _instance;
  static AiWorkerService get instance => _instance ??= AiWorkerService._();

  AiWorkerService._();

  int _activeRequestId = 0;
  bool _isBusy = false;

  bool get isBusy => _isBusy;
  int get activeRequestId => _activeRequestId;

  /// Execute an AI rewrite on a dedicated background isolate without blocking the UI thread.
  Future<RewriteResult?> executeRewrite({
    required String text,
    required RewriteMode mode,
  }) async {
    final int requestId = ++_activeRequestId;
    _isBusy = true;

    try {
      // Execute synchronous native FFI call on a dedicated background Dart isolate
      final result = await Isolate.run(
        () => _isolateRewriteEntry(_RewriteTaskArgs(text, mode)),
        debugName: 'AiInferenceWorker-$requestId',
      );

      // Concurrency control: if a newer request was dispatched while this was computing, ignore stale result
      if (requestId != _activeRequestId) {
        return null;
      }

      return result;
    } catch (e) {
      if (requestId != _activeRequestId) {
        return null;
      }
      return RewriteResult(
        original: text,
        revised: '',
        mode: mode.title,
        engine: 'None',
        status: 'isolate_error',
        errorMessage: e.toString(),
      );
    } finally {
      if (requestId == _activeRequestId) {
        _isBusy = false;
      }
    }
  }

  /// Request immediate cancellation of currently executing inference.
  void cancel() {
    _activeRequestId++; // Invalidate current request ID
    _isBusy = false;
    NativeGrammarEngine.instance.cancelAi();
  }

  /// Load a model on a dedicated background isolate.
  Future<AiModelStatus> loadModelBackground({
    required String modelPath,
    required String tokenizerPath,
    bool verifyChecksum = false,
  }) async {
    _isBusy = true;
    try {
      final status = await Isolate.run(
        () => _isolateLoadModelEntry(
          _LoadModelTaskArgs(modelPath, tokenizerPath, verifyChecksum),
        ),
        debugName: 'AiModelLoadWorker',
      );
      return status;
    } finally {
      _isBusy = false;
    }
  }
}

