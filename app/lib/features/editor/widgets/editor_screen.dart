import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/ffi/native_grammar_bindings.dart';
import '../../../core/theme/app_theme.dart';
import '../../ai_assistant/ai_panel.dart';
import '../../history/history_dialog.dart';
import '../../insights/insights_sheet.dart';
import '../../keyboard_settings/keyboard_settings_screen.dart';
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

  String get _dbPath {
    final tempDir = Directory.systemTemp.path;
    return '$tempDir/appendix_history.db';
  }

  @override
  void initState() {
    super.initState();
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

  void _handleOpenAi() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write or paste text before using AI Assistant.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: AiPanel(
          initialText: text,
          isDarkMode: widget.isDarkMode,
          onApplyRevision: (revised) {
            _controller.text = revised;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Revision applied to editor.')),
            );
          },
        ),
      ),
    );
  }

  void _handleOpenInsights() {
    final text = _controller.text.trim();
    final insights = NativeGrammarEngine.instance.analyzeInsights(text);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Center(
        child: InsightsSheet(
          insights: insights,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
  }

  void _handleSaveDraft() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final insights = NativeGrammarEngine.instance.analyzeInsights(text);
    final id = NativeGrammarEngine.instance.saveHistory(
      _dbPath,
      text,
      insights.wordCount,
      insights.fleschReadingEase,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(id > 0 ? 'Draft snapshot saved locally.' : 'Saved to local history.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleOpenHistory() {
    final entries = NativeGrammarEngine.instance.listHistory(_dbPath);

    showDialog(
      context: context,
      builder: (ctx) => HistoryDialog(
        entries: entries,
        isDarkMode: widget.isDarkMode,
        onRestore: (entry) {
          _controller.text = entry.content;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Draft restored to editor.')),
          );
        },
        onDelete: (entry) {
          NativeGrammarEngine.instance.deleteHistory(_dbPath, entry.id);
          Navigator.of(ctx).pop();
          _handleOpenHistory();
        },
        onClearAll: () {
          NativeGrammarEngine.instance.clearHistory(_dbPath);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('History cleared.')),
          );
        },
      ),
    );
  }

  void _handleOpenKeyboard() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const KeyboardSettingsScreen()),
    );
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
            // Top Toolbar with AI & Insights
            EditorToolbar(
              activeDialect: _controller.dialect,
              onDialectChanged: (d) => setState(() => _controller.setDialect(d)),
              onOpenAi: _handleOpenAi,
              onOpenInsights: _handleOpenInsights,
              onOpenHistory: _handleOpenHistory,
              onSaveDraft: _handleSaveDraft,
              onOpenKeyboard: _handleOpenKeyboard,
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
