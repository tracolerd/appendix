import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/ffi/native_grammar_bindings.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/writing_editor_controller.dart';
import 'editor_toolbar.dart';
import 'stats_footer.dart';
import 'suggestion_sidebar.dart';

class EditorScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const EditorScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final WritingEditorController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Default initial demonstration text showcasing grammar, spelling, and dialect detection
    _controller = WritingEditorController(
      text: 'This is an test sentence to showcase Appendix. The colour of the car is bright blue.',
      onIssuesUpdated: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleCopy() {
    if (_controller.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _controller.text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Text copied to clipboard'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _handleClear() {
    if (_controller.text.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Clear Editor?'),
          content: const Text('Are you sure you want to clear all text? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _controller.clear();
                Navigator.of(ctx).pop();
              },
              style: TextButton.styleFrom(foregroundColor: AppendixTheme.errorRed),
              child: const Text('Clear All'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final surface = isDark ? AppendixTheme.darkBackground : AppendixTheme.lightBackground;
    final textPrimary = isDark ? AppendixTheme.darkTextPrimary : AppendixTheme.lightTextPrimary;

    return Scaffold(
      backgroundColor: surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top Toolbar
            EditorToolbar(
              activeDialect: _controller.dialect,
              onDialectChanged: (d) => setState(() => _controller.setDialect(d)),
              onCopy: _handleCopy,
              onClear: _handleClear,
              onToggleTheme: widget.onToggleTheme,
              isDarkMode: isDark,
              isAnalyzing: _controller.isAnalyzing,
              issueCount: _controller.issues.length,
            ),

            // Main Editor + Sidebar Area
            Expanded(
              child: Row(
                children: [
                  // Writing Canvas
                  Expanded(
                    child: Container(
                      color: surface,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: null,
                        expands: true,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.75,
                          color: textPrimary,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.1,
                        ),
                        cursorColor: AppendixTheme.accentBlue,
                        cursorWidth: 2,
                        decoration: InputDecoration(
                          hintText: 'Start writing or paste your text here to begin proofreading...',
                          hintStyle: TextStyle(
                            color: isDark
                                ? AppendixTheme.darkTextTertiary
                                : AppendixTheme.lightTextTertiary,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),

                  // Suggestions Sidebar
                  SuggestionSidebar(
                    issues: _controller.issues,
                    selectedIssue: _controller.selectedIssue,
                    onSelectIssue: (issue) => _controller.selectIssue(issue),
                    onApplySuggestion: (issue, suggestion) =>
                        _controller.applySuggestion(issue, suggestion),
                    onIgnoreIssue: (issue) => _controller.ignoreIssue(issue),
                    isDarkMode: isDark,
                  ),
                ],
              ),
            ),

            // Bottom Stats Footer
            StatsFooter(
              stats: _controller.stats,
              isDarkMode: isDark,
              isNativeLoaded: NativeGrammarEngine.instance.isNativeLoaded,
            ),
          ],
        ),
      ),
    );
  }
}

