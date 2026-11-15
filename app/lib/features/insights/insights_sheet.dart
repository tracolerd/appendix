import 'package:flutter/material.dart';
import '../../core/ffi/grammar_models.dart';
import '../../core/theme/app_theme.dart';

class InsightsSheet extends StatelessWidget {
  final WritingInsights insights;
  final bool isDarkMode;

  const InsightsSheet({
    super.key,
    required this.insights,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDarkMode ? AppendixTheme.darkBorder : AppendixTheme.lightBorder;
    final surface = isDarkMode ? AppendixTheme.darkSurface : AppendixTheme.lightSurface;
    final textPrimary = isDarkMode ? AppendixTheme.darkTextPrimary : AppendixTheme.lightTextPrimary;
    final textSecondary = isDarkMode ? AppendixTheme.darkTextSecondary : AppendixTheme.lightTextSecondary;

    return Container(
      width: 440,
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
            // Title + Close
            Row(
              children: [
                const Icon(Icons.insights_rounded, color: AppendixTheme.accentBlue, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Personal Writing Insights',
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
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Readability Score Hero Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode ? border : const Color(0xFFBBF7D0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppendixTheme.successGreen.withValues(alpha: 0.15),
                      border: Border.all(color: AppendixTheme.successGreen, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '${insights.fleschReadingEase.round()}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppendixTheme.successGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Readability: ${insights.readabilityLabel}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Flesch-Kincaid Grade Level: ${insights.fleschKincaidGrade.toStringAsFixed(1)}',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Text(
              'Style & Structure',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Style metrics grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'Vocab Diversity',
                    value: '${(insights.vocabularyDiversity * 100).round()}%',
                    subtitle: '${insights.uniqueWords} unique words',
                    isDark: isDarkMode,
                    border: border,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    title: 'Avg Sentence Length',
                    value: insights.averageSentenceLength.toStringAsFixed(1),
                    subtitle: 'words per sentence',
                    isDark: isDarkMode,
                    border: border,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ),
              ],
            ),

            if (insights.longSentenceCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppendixTheme.warningAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppendixTheme.warningAmber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppendixTheme.warningAmber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${insights.longSentenceCount} sentence(s) are longer than 25 words. Consider splitting them for clarity.',
                        style: TextStyle(fontSize: 12, color: textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Overused Words section
            if (insights.overusedWords.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Frequently Repeated Words',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: insights.overusedWords.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: border),
                    ),
                    child: Text(
                      '${item.word} (${item.count}x)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Close Insights', style: TextStyle(color: textPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required bool isDark,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 10, color: textSecondary)),
        ],
      ),
    );
  }
}
