import 'package:flutter/material.dart';
import '../../../core/ffi/grammar_models.dart';
import '../../../core/theme/app_theme.dart';

class SuggestionSidebar extends StatelessWidget {
  final List<LintIssue> issues;
  final LintIssue? selectedIssue;
  final void Function(LintIssue issue) onSelectIssue;
  final void Function(LintIssue issue, GrammarSuggestion suggestion) onApplySuggestion;
  final void Function(LintIssue issue) onIgnoreIssue;
  final bool isDarkMode;

  const SuggestionSidebar({
    super.key,
    required this.issues,
    required this.selectedIssue,
    required this.onSelectIssue,
    required this.onApplySuggestion,
    required this.onIgnoreIssue,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDarkMode ? AppendixTheme.darkBorder : AppendixTheme.lightBorder;
    final surface = isDarkMode ? AppendixTheme.darkSurface : AppendixTheme.lightSurface;
    final textPrimary = isDarkMode
        ? AppendixTheme.darkTextPrimary
        : AppendixTheme.lightTextPrimary;
    final textSecondary = isDarkMode
        ? AppendixTheme.darkTextSecondary
        : AppendixTheme.lightTextSecondary;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: surface,
        border: Border(left: BorderSide(color: border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Text(
                  'Suggestions',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: issues.isEmpty
                        ? (isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6))
                        : AppendixTheme.accentBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${issues.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: issues.isEmpty
                          ? textSecondary
                          : AppendixTheme.accentBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content list or empty state
          Expanded(
            child: issues.isEmpty
                ? _buildEmptyState(textPrimary, textSecondary)
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: issues.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final issue = issues[index];
                      final isSelected = selectedIssue != null &&
                          selectedIssue!.start == issue.start &&
                          selectedIssue!.end == issue.end;
                      return _buildIssueCard(issue, isSelected, textPrimary, textSecondary, border);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color textPrimary, Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppendixTheme.successGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppendixTheme.successGreen,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Looking Great!',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No grammar or spelling errors detected in your text.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueCard(
    LintIssue issue,
    bool isSelected,
    Color textPrimary,
    Color textSecondary,
    Color border,
  ) {
    final badgeColor = issue.isSpelling
        ? AppendixTheme.errorRed
        : (issue.lintKind.toLowerCase().contains('dialect')
            ? const Color(0xFF8B5CF6)
            : AppendixTheme.warningAmber);

    return InkWell(
      onTap: () => onSelectIssue(issue),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? badgeColor.withValues(alpha: 0.08)
              : (isDarkMode ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? badgeColor : border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kind badge + Ignore icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    issue.lintKind.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => onIgnoreIssue(issue),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              issue.message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textPrimary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),

            // Suggestions buttons
            if (issue.suggestions.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: issue.suggestions.map((suggestion) {
                  return ElevatedButton(
                    onPressed: () => onApplySuggestion(issue, suggestion),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppendixTheme.accentBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_forward_rounded, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          suggestion.replacement.isEmpty
                              ? 'Remove'
                              : suggestion.replacement,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

