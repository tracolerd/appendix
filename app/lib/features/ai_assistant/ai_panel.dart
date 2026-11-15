import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/ffi/grammar_models.dart';
import '../../core/ffi/native_grammar_bindings.dart';
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialText.trim().isNotEmpty) {
      _executeRewrite(_selectedMode);
    }
  }

  void _executeRewrite(RewriteMode mode) {
    setState(() {
      _selectedMode = mode;
      _isLoading = true;
    });

    // Run rewriting via native FFI engine
    Future.microtask(() {
      final res = NativeGrammarEngine.instance.rewriteText(
        widget.initialText,
        mode,
      );
      if (mounted) {
        setState(() {
          _currentResult = res;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final border = widget.isDarkMode ? AppendixTheme.darkBorder : AppendixTheme.lightBorder;
    final surface = widget.isDarkMode ? AppendixTheme.darkSurface : AppendixTheme.lightSurface;
    final textPrimary = widget.isDarkMode ? AppendixTheme.darkTextPrimary : AppendixTheme.lightTextPrimary;
    final textSecondary = widget.isDarkMode ? AppendixTheme.darkTextSecondary : AppendixTheme.lightTextSecondary;

    return Container(
      width: 540,
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
            const SizedBox(height: 12),
            Text(
              'Transform your text locally with zero cloud transmission.',
              style: TextStyle(fontSize: 13, color: textSecondary),
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
                  label: Text(mode.title),
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

            // Comparison View
            if (_isLoading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ] else if (_currentResult != null) ...[
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
        ),
      ),
    );
  }
}
