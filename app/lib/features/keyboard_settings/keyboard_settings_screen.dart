import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/ffi/grammar_models.dart';
import '../../core/ffi/native_grammar_bindings.dart';
import '../../core/theme/app_theme.dart';

/// Keyboard settings and onboarding screen for Android IME.
class KeyboardSettingsScreen extends StatefulWidget {
  const KeyboardSettingsScreen({super.key});

  @override
  State<KeyboardSettingsScreen> createState() => _KeyboardSettingsScreenState();
}

class _KeyboardSettingsScreenState extends State<KeyboardSettingsScreen>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('org.appendix.appendix/ime');

  bool _isImeEnabled = false;
  bool _isImeSelected = false;
  int _currentDialect = 0; // 0 = US, 1 = UK
  bool _isLoading = true;

  final TextEditingController _testInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _testInputController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    try {
      final isEnabled = await _channel.invokeMethod<bool>('isImeEnabled') ?? false;
      final isSelected = await _channel.invokeMethod<bool>('isImeSelected') ?? false;
      final dialect = await _channel.invokeMethod<int>('getDialect') ?? 0;

      if (mounted) {
        setState(() {
          _isImeEnabled = isEnabled;
          _isImeSelected = isSelected;
          _currentDialect = dialect;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openSettings() async {
    try {
      await _channel.invokeMethod('openImeSettings');
    } catch (_) {}
  }

  Future<void> _openPicker() async {
    try {
      await _channel.invokeMethod('openImePicker');
    } catch (_) {}
  }

  Future<void> _setDialect(int dialect) async {
    try {
      await _channel.invokeMethod('setDialect', {'dialect': dialect});
      NativeGrammarEngine.instance.setDialect(
        dialect == 1 ? EnglishDialect.british : EnglishDialect.american,
      );
      setState(() {
        _currentDialect = dialect;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppendixTheme.darkBackground : AppendixTheme.lightBackground;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Appendix Keyboard Setup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Privacy & Offline Guarantee Banner
                      _buildPrivacyBanner(isDark),
                      const SizedBox(height: 24),

                      // Step 1: Enable in Settings
                      _buildStepCard(
                        isDark: isDark,
                        stepNumber: 1,
                        title: 'Enable Appendix Keyboard',
                        description:
                            'Add Appendix to your list of active keyboards in Android Settings.',
                        isCompleted: _isImeEnabled,
                        actionLabel: 'Open Keyboard Settings',
                        actionIcon: Icons.settings,
                        onAction: _openSettings,
                      ),
                      const SizedBox(height: 16),

                      // Step 2: Switch active IME
                      _buildStepCard(
                        isDark: isDark,
                        stepNumber: 2,
                        title: 'Switch Default Input Method',
                        description:
                            'Choose Appendix Keyboard as your current typing method.',
                        isCompleted: _isImeSelected,
                        actionLabel: 'Select Input Method',
                        actionIcon: Icons.keyboard,
                        onAction: _openPicker,
                      ),
                      const SizedBox(height: 24),

                      // Dialect Selection
                      _buildDialectCard(isDark),
                      const SizedBox(height: 24),

                      // Live Typing Sandbox
                      _buildTestSandbox(isDark),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPrivacyBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppendixTheme.successGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppendixTheme.successGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield, color: AppendixTheme.successGreen, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '100% Offline & Private Keyboard',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? AppendixTheme.darkTextPrimary : AppendixTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No internet access requested. Your typing is analyzed locally with Rust Harper without sending a single byte to any cloud.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppendixTheme.darkTextSecondary : AppendixTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required bool isDark,
    required int stepNumber,
    required String title,
    required String description,
    required bool isCompleted,
    required String actionLabel,
    required IconData actionIcon,
    required VoidCallback onAction,
  }) {
    final cardBg = isDark ? AppendixTheme.darkSurface : AppendixTheme.lightSurface;
    final borderColor = isCompleted
        ? AppendixTheme.successGreen.withValues(alpha: 0.4)
        : (isDark ? AppendixTheme.darkBorder : AppendixTheme.lightBorder);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isCompleted
                    ? AppendixTheme.successGreen
                    : AppendixTheme.accentBlue,
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '$stepNumber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppendixTheme.successGreen.withValues(alpha: 0.15)
                      : AppendixTheme.warningAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCompleted ? 'Enabled' : 'Action Required',
                  style: TextStyle(
                    color: isCompleted ? AppendixTheme.successGreen : AppendixTheme.warningAmber,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              color: isDark ? AppendixTheme.darkTextSecondary : AppendixTheme.lightTextSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAction,
            icon: Icon(actionIcon, size: 18),
            label: Text(actionLabel),
            style: FilledButton.styleFrom(
              backgroundColor: isCompleted
                  ? (isDark ? AppendixTheme.darkBorder : AppendixTheme.lightBorder)
                  : AppendixTheme.accentBlue,
              foregroundColor: isCompleted
                  ? (isDark ? AppendixTheme.darkTextPrimary : AppendixTheme.lightTextPrimary)
                  : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialectCard(bool isDark) {
    final cardBg = isDark ? AppendixTheme.darkSurface : AppendixTheme.lightSurface;
    final border = isDark ? AppendixTheme.darkBorder : AppendixTheme.lightBorder;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'English Dialect',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select whether Harper checks spelling using American or British conventions.',
            style: TextStyle(
              color: isDark ? AppendixTheme.darkTextSecondary : AppendixTheme.lightTextSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDialectOption(
                  isDark: isDark,
                  label: 'American English (US)',
                  sublabel: 'Color, Center, Organize',
                  isSelected: _currentDialect == 0,
                  onTap: () => _setDialect(0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDialectOption(
                  isDark: isDark,
                  label: 'British English (UK)',
                  sublabel: 'Colour, Centre, Organise',
                  isSelected: _currentDialect == 1,
                  onTap: () => _setDialect(1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDialectOption({
    required bool isDark,
    required String label,
    required String sublabel,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final border = isDark ? AppendixTheme.darkBorder : AppendixTheme.lightBorder;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppendixTheme.accentBlue.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppendixTheme.accentBlue : border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected
                      ? AppendixTheme.accentBlue
                      : (isDark ? AppendixTheme.darkTextTertiary : AppendixTheme.lightTextTertiary),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isSelected
                          ? (isDark ? AppendixTheme.darkTextPrimary : AppendixTheme.lightTextPrimary)
                          : (isDark ? AppendixTheme.darkTextSecondary : AppendixTheme.lightTextSecondary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                sublabel,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppendixTheme.darkTextTertiary : AppendixTheme.lightTextTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSandbox(bool isDark) {
    final cardBg = isDark ? AppendixTheme.darkSurface : AppendixTheme.lightSurface;
    final border = isDark ? AppendixTheme.darkBorder : AppendixTheme.lightBorder;
    final inputBg = isDark ? AppendixTheme.darkBackground : AppendixTheme.lightBackground;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Keyboard Practice Sandbox',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap below to activate your keyboard. Try typing typos like "teh" or "seperate" to see suggestions appear on the candidate bar.',
            style: TextStyle(
              color: isDark ? AppendixTheme.darkTextSecondary : AppendixTheme.lightTextSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _testInputController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Type here to test Appendix Keyboard...',
              filled: true,
              fillColor: inputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: border),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
