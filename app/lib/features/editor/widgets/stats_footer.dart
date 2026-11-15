import 'package:flutter/material.dart';
import '../controllers/writing_editor_controller.dart';
import '../../../core/theme/app_theme.dart';

class StatsFooter extends StatelessWidget {
  final WritingStats stats;
  final bool isDarkMode;
  final bool isNativeLoaded;

  const StatsFooter({
    super.key,
    required this.stats,
    required this.isDarkMode,
    required this.isNativeLoaded,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDarkMode ? AppendixTheme.darkBorder : AppendixTheme.lightBorder;
    final surface = isDarkMode ? AppendixTheme.darkSurface : AppendixTheme.lightSurface;
    final textSecondary = isDarkMode
        ? AppendixTheme.darkTextSecondary
        : AppendixTheme.lightTextSecondary;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 600;

          return Row(
            children: [
              // Metrics
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMetric('Words', stats.wordCount, textSecondary),
                      const SizedBox(width: 14),
                      _buildMetric('Characters', stats.charCount, textSecondary),
                      if (!isCompact) ...[
                        const SizedBox(width: 14),
                        _buildMetric('Sentences', stats.sentenceCount, textSecondary),
                        const SizedBox(width: 14),
                        Text(
                          '~${stats.readingTimeMinutes} min read',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Offline privacy badge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppendixTheme.successGreen,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isCompact
                        ? '100% Offline'
                        : (isNativeLoaded
                            ? 'Offline • Harper Core (Rust)'
                            : 'Offline • Rule Engine'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetric(String label, int value, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label.toLowerCase(),
          style: TextStyle(
            fontSize: 12,
            color: textColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
