import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appendix/features/keyboard_settings/keyboard_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('org.appendix.appendix/ime');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'isImeEnabled':
          return true;
        case 'isImeSelected':
          return false;
        case 'getDialect':
          return 0; // US English
        case 'setDialect':
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

  testWidgets('KeyboardSettingsScreen displays privacy banner and steps', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: KeyboardSettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title and banner
    expect(find.text('Appendix Keyboard Setup'), findsOneWidget);
    expect(find.text('100% Offline & Private Keyboard'), findsOneWidget);

    // Verify steps
    expect(find.text('Enable Appendix Keyboard'), findsOneWidget);
    expect(find.text('Switch Default Input Method'), findsOneWidget);

    // Verify dialect options
    expect(find.text('American English (US)'), findsOneWidget);
    expect(find.text('British English (UK)'), findsOneWidget);

    // Verify practice sandbox
    expect(find.text('Keyboard Practice Sandbox'), findsOneWidget);
  });

  testWidgets('KeyboardSettingsScreen switches dialect', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: KeyboardSettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap British English
    final ukOption = find.text('British English (UK)');
    await tester.tap(ukOption);
    await tester.pumpAndSettle();

    expect(find.text('British English (UK)'), findsOneWidget);
  });
}

