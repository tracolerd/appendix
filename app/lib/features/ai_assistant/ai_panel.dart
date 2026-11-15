import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/ffi/grammar_models.dart';
import '../../core/ffi/native_grammar_bindings.dart';
import '../../core/services/ai_worker_service.dart';
import '../../core/theme/app_theme.dart';

class AiPanel extends StatefulWidget {
  final String initialText;
  final ValueChanged<String> onApplyRevision;
  final bool isDarkMode;

  const AiPanel({
    super.key,
    required this.initialText,
    required this.onApplyRevision,
    required this.isDarkMode,
  });

  @override
  State<AiPanel> createState() => _AiPanelState();
}

class _AiPanelState extends State<AiPanel> {
  RewriteMode _selectedMode = RewriteMode.rephrase;
  RewriteResult? _currentResult;
  AiModelStatus? _modelStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
    if (widget.initialText.trim().isNotEmpty) {
      _executeRewrite(_selectedMode);
    }
  }

  void _checkModelStatus() {
    try {
      final status = NativeGrammarEngine.instance.getAiStatus();
      setState(() {
        _modelStatus = status;
      });
    } catch (_) {}
  }

  void _executeRewrite(RewriteMode mode) async {
    // If a request is already running, cancel it before starting new mode
    if (_isLoading) {
      AiWorkerService.instance.cancel();
    }

    setState(() {
      _selectedMode = mode;
      _isLoading = true;
    });

    // Execute on dedicated background Dart isolate
    final res = await AiWorkerService.instance.executeRewrite(
      text: widget.initialText,
      mode: mode,
    );

    if (mounted && res != null) {
      setState(() {
        _currentResult = res;
        _isLoading = false;
        _modelStatus = NativeGrammarEngine.instance.getAiStatus();
      });
    }
  }

  void _cancelInference() {
    AiWorkerService.instance.cancel();
    if (mounted) {
      setState(() {
        _isLoading = false;
        _currentResult = RewriteResult(
          original: widget.initialText,
          revised: '',
          mode: _selectedMode.title,
          engine: 'None',
          status: 'cancelled',
          errorMessage: 'Inference cancelled by user',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = widget.isDarkMode ? AppendixTheme.darkBorder : AppendixTheme.lightBorder;
    final surface = widget.isDarkMode ? AppendixTheme.darkSurface : AppendixTheme.lightSurface;
    final textPrimary = widget.isDarkMode ? AppendixTheme.darkTextPrimary : AppendixTheme.lightTextPrimary;
    final textSecondary = widget.isDarkMode ? AppendixTheme.darkTextSecondary : AppendixTheme.lightTextSecondary;

    final isModelLoaded = _modelStatus?.loaded == true ||
        (_currentResult?.engine.contains('Neural') ?? false);

    return Container(
      width: 560,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: border),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.auto_fix_high_rounded, color: AppendixTheme.accentBlue, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Local AI Writing Assistant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Transform your text locally with zero cloud transmission via background worker.',
              style: TextStyle(fontSize: 13, color: textSecondary),
            ),
            const SizedBox(height: 10),

            // Live Model Status Badge
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isModelLoaded ? AppendixTheme.successGreen : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isModelLoaded
                        ? 'Qwen 2.5 0.5B Neural SLM (Local GGUF - Background Isolate)'
                        : 'Local AI: Standby (Place model in models/ directory)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isModelLoaded ? AppendixTheme.successGreen : textSecondary,
                    ),
                  ),
                ),
                if (_modelStatus?.ramMeasured == true && _modelStatus?.ramWorkingSetMb != null) ...[
                  Text(
                    'RAM: ${_modelStatus!.ramWorkingSetMb!.toStringAsFixed(0)} MB',
                    style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Mode Selector Grid
            Text(
              'Select Improvement Goal',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RewriteMode.values.map((mode) {
                final isSelected = _selectedMode == mode;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(mode.title),
                      if (mode.isExperimental) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'EXP',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.orange),
                          ),
                        ),
                      ],
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) _executeRewrite(mode);
                  },
                  selectedColor: AppendixTheme.accentBlue,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : textPrimary,
                  ),
                  backgroundColor: widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
                  side: BorderSide(color: isSelected ? AppendixTheme.accentBlue : border),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Background Loading / Comparison View
            if (_isLoading) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Executing neural rewrite on background isolate...',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.stop_circle_outlined, size: 16, color: Colors.redAccent),
                        label: const Text('Cancel Inference', style: TextStyle(color: Colors.redAccent)),
                        onPressed: _cancelInference,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_currentResult != null) ...[
              if (_currentResult!.status == 'model_not_loaded') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Local AI Model Not Loaded',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentResult!.errorMessage ??
                                  'Please place qwen2.5-0.5b-instruct-q4_k_m.gguf inside the models/ folder.',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_currentResult!.status == 'cancelled') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: textSecondary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Inference was cancelled by user.',
                        style: TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Side by side original vs revised
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'ORIGINAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppendixTheme.accentBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _currentResult!.engine.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppendixTheme.accentBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _currentResult!.original,
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                          decoration: TextDecoration.lineThrough,
                          height: 1.4,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      Text(
                        'REVISED (${_selectedMode.title.toUpperCase()})',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppendixTheme.successGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _currentResult!.revised,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                          height: 1.45,
                        ),
                      ),
                      if (_currentResult?.latencyMs != null && _currentResult!.latencyMs! > 0) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.bolt_rounded, size: 14, color: AppendixTheme.accentBlue),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${(_currentResult!.latencyMs! / 1000).toStringAsFixed(2)}s  •  ${_currentResult!.tokensGenerated ?? 0} tokens  •  ${(_currentResult!.tokensPerSec ?? 0).toStringAsFixed(1)} tok/s',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Accept & Replace'),
                        onPressed: () {
                          widget.onApplyRevision(_currentResult!.revised);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppendixTheme.accentBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _currentResult!.revised));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Revised text copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: border),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
