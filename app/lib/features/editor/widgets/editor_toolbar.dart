import 'package:flutter/material.dart';
import '../../../core/ffi/grammar_models.dart';
import '../../../core/theme/app_theme.dart';

class EditorToolbar extends StatelessWidget {
  final EnglishDialect activeDialect;
  final ValueChanged<EnglishDialect> onDialectChanged;
  final VoidCallback onCopy;
  final VoidCallback onClear;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final bool isAnalyzing;
  final int issueCount;

  const EditorToolbar({
    super.key,
    required this.activeDialect,
    required this.onDialectChanged,
    required this.onCopy,
    required this.onClear,
    required this.onToggleTheme,
    required this.isDarkMode,
    required this.isAnalyzing,
    required this.issueCount,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDarkMode ? AppendixTheme.darkBorder : AppendixTheme.lightBorder;
    final surface = isDarkMode ? AppendixTheme.darkSurface : AppendixTheme.lightSurface;
    final textSecondary = isDarkMode
        ? AppendixTheme.darkTextSecondary
        : AppendixTheme.lightTextSecondary;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 600;

          return Row(
            children: [
              // App Logo / Title
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppendixTheme.accentBlue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: Text(
                        'A',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Appendix',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDarkMode
                          ? AppendixTheme.darkTextPrimary
                          : AppendixTheme.lightTextPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Dialect Switcher (US / UK)
              Container(
                height: 30,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDialectPill(
                      dialect: EnglishDialect.american,
                      label: isCompact ? 'US' : 'US English',
                      isSelected: activeDialect == EnglishDialect.american,
                      isDark: isDarkMode,
                    ),
                    _buildDialectPill(
                      dialect: EnglishDialect.british,
                      label: isCompact ? 'UK' : 'UK English',
                      isSelected: activeDialect == EnglishDialect.british,
                      isDark: isDarkMode,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Status indicator (shown if not super compact)
              if (!isCompact)
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isAnalyzing
                              ? AppendixTheme.warningAmber
                              : (issueCount > 0
                                  ? AppendixTheme.errorRed
                                  : AppendixTheme.successGreen),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isAnalyzing
                              ? 'Checking...'
                              : (issueCount > 0
                                  ? '$issueCount issues found'
                                  : 'No errors found'),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Spacer(),

              // Action buttons
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Copy text to clipboard',
                icon: const Icon(Icons.copy_rounded, size: 17),
                onPressed: onCopy,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Clear editor',
                icon: const Icon(Icons.delete_outline_rounded, size: 17),
                onPressed: onClear,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                icon: Icon(
                  isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  size: 17,
                ),
                onPressed: onToggleTheme,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialectPill({
    required EnglishDialect dialect,
    required String label,
    required bool isSelected,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => onDialectChanged(dialect),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppendixTheme.darkSurface : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? (isDark ? AppendixTheme.darkTextPrimary : AppendixTheme.lightTextPrimary)
                : (isDark ? AppendixTheme.darkTextTertiary : AppendixTheme.lightTextTertiary),
          ),
        ),
      ),
    );
  }
}
