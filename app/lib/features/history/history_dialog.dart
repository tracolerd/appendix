import 'package:flutter/material.dart';
import '../../core/ffi/grammar_models.dart';
import '../../core/theme/app_theme.dart';

class HistoryDialog extends StatelessWidget {
  final List<HistoryEntry> entries;
  final ValueChanged<HistoryEntry> onRestore;
  final ValueChanged<HistoryEntry> onDelete;
  final VoidCallback onClearAll;
  final bool isDarkMode;

  const HistoryDialog({
    super.key,
    required this.entries,
    required this.onRestore,
    required this.onDelete,
    required this.onClearAll,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDarkMode ? AppendixTheme.darkBorder : AppendixTheme.lightBorder;
    final surface = isDarkMode ? AppendixTheme.darkSurface : AppendixTheme.lightSurface;
    final textPrimary = isDarkMode ? AppendixTheme.darkTextPrimary : AppendixTheme.lightTextPrimary;
    final textSecondary = isDarkMode ? AppendixTheme.darkTextSecondary : AppendixTheme.lightTextSecondary;

    return Dialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border),
      ),
      child: Container(
        width: 500,
        height: 520,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.history_rounded, color: AppendixTheme.accentBlue, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Local Writing History',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                if (entries.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                    label: const Text('Clear All'),
                    style: TextButton.styleFrom(foregroundColor: AppendixTheme.errorRed),
                    onPressed: () {
                      onClearAll();
                      Navigator.of(context).pop();
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),

            // Entries List or Empty
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_toggle_off_rounded, size: 40, color: textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            'No writing history yet',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Saved drafts will be securely archived locally here.',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    entry.timestamp.length > 19
                                        ? entry.timestamp.substring(0, 19).replaceAll('T', ' ')
                                        : entry.timestamp,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('•', style: TextStyle(color: textSecondary)),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${entry.wordCount} words',
                                    style: TextStyle(fontSize: 11, color: textSecondary),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                    onPressed: () => onDelete(entry),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                entry.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textPrimary,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  icon: const Icon(Icons.restore_rounded, size: 14),
                                  label: const Text('Restore Draft'),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    foregroundColor: AppendixTheme.accentBlue,
                                  ),
                                  onPressed: () {
                                    onRestore(entry);
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
