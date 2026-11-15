import 'package:flutter_test/flutter_test.dart';
import 'package:appendix/main.dart';

void main() {
  testWidgets('Appendix app boots and renders main editor', (WidgetTester tester) async {
    await tester.pumpWidget(const AppendixApp());
    await tester.pumpAndSettle();

    // Verify app title and toolbar exist
    expect(find.text('Appendix'), findsOneWidget);
    expect(find.text('US English'), findsOneWidget);
    expect(find.text('UK English'), findsOneWidget);
    expect(find.text('Suggestions'), findsOneWidget);
  });
}
