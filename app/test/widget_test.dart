import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appendix/main.dart';

void main() {
  testWidgets('Appendix app boots and renders main editor with Phase 2 toolbar', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const AppendixApp());
    await tester.pumpAndSettle();

    // Verify app title and toolbar exist
    expect(find.text('Appendix'), findsOneWidget);
    expect(find.text('US English'), findsOneWidget);
    expect(find.text('UK English'), findsOneWidget);
    expect(find.text('Suggestions'), findsOneWidget);
    expect(find.textContaining('AI'), findsOneWidget);
  });
}
