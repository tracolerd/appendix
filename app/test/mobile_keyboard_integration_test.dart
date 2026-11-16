import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appendix/core/ffi/grammar_models.dart';
import 'package:appendix/features/keyboard_settings/keyboard_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mobile Keyboard Integration & Privacy Tests', () {
    const channel = MethodChannel('org.appendix.appendix/ime');
    final List<MethodCall> log = <MethodCall>[];
    int mockDialect = 0;
    bool mockEnabled = true;
    bool mockSelected = false;

    setUp(() {
      log.clear();
      mockDialect = 0;
      mockEnabled = true;
      mockSelected = false;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'isImeEnabled':
            return mockEnabled;
          case 'isImeSelected':
            return mockSelected;
          case 'getDialect':
            return mockDialect;
          case 'setDialect':
            mockDialect = methodCall.arguments['dialect'] as int;
            return true;
          case 'openImeSettings':
            return true;
          case 'openImePicker':
            return true;
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('EnglishDialect enum correctly maps between index and engine dialect', () {
      expect(EnglishDialect.values[0], equals(EnglishDialect.american));
      expect(EnglishDialect.values[1], equals(EnglishDialect.british));
      expect(EnglishDialect.american.index, equals(0));
      expect(EnglishDialect.british.index, equals(1));
    });

    testWidgets('KeyboardSettingsScreen displays Product & Feature Boundaries card',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: KeyboardSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify privacy banner
      expect(find.text('100% Offline & Private Keyboard'), findsOneWidget);

      // Verify Product & Feature Boundaries card
      expect(find.text('Product & Feature Boundaries'), findsOneWidget);
      expect(
        find.textContaining('Lightweight, fast, 100% offline text input with Harper grammar checking'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Full local neural AI rewriting (Qwen 2.5 0.5B SLM)'),
        findsOneWidget,
      );
    });

    testWidgets('KeyboardSettingsScreen renders platform-specific guidance for Android and iOS',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Test default platform (Android/Fuchsia/Linux/etc)
      await tester.pumpWidget(
        const MaterialApp(
          home: KeyboardSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Enable Appendix Keyboard'), findsOneWidget);
      expect(find.text('Switch Default Input Method'), findsOneWidget);

      // Test on iOS
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: const KeyboardSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Enable Appendix Keyboard on iOS'), findsOneWidget);
      expect(find.text('Switch to Appendix Keyboard'), findsOneWidget);
      expect(find.text('iOS Guide'), findsNWidgets(2));
      expect(
        find.textContaining('Settings > General > Keyboard > Keyboards > Add New Keyboard...'),
        findsOneWidget,
      );
      expect(
        find.textContaining('RequestsOpenAccess=false'),
        findsOneWidget,
      );
    });

    testWidgets('KeyboardSettingsScreen interacts with IME method channel accurately',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: KeyboardSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check that initial status queried the channel
      expect(log.any((call) => call.method == 'isImeEnabled'), isTrue);
      expect(log.any((call) => call.method == 'isImeSelected'), isTrue);
      expect(log.any((call) => call.method == 'getDialect'), isTrue);

      // Tap settings button
      final openSettingsBtn = find.text('Open Keyboard Settings');
      await tester.ensureVisible(openSettingsBtn);
      await tester.tap(openSettingsBtn);
      await tester.pumpAndSettle();

      expect(log.any((call) => call.method == 'openImeSettings'), isTrue);

      // Tap select input method button
      final openPickerBtn = find.text('Select Input Method');
      await tester.ensureVisible(openPickerBtn);
      await tester.tap(openPickerBtn);
      await tester.pumpAndSettle();

      expect(log.any((call) => call.method == 'openImePicker'), isTrue);
    });
  });
}
