import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/editor/widgets/editor_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppendixApp());
}

class AppendixApp extends StatefulWidget {
  const AppendixApp({super.key});

  @override
  State<AppendixApp> createState() => _AppendixAppState();
}

class _AppendixAppState extends State<AppendixApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Appendix — Offline English Writing Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppendixTheme.lightTheme(),
      darkTheme: AppendixTheme.darkTheme(),
      themeMode: _themeMode,
      home: EditorScreen(
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}
