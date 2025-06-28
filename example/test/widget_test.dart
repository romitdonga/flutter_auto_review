import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_auto_review_example/main.dart';

void main() {
  testWidgets('Example app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the title is displayed
    expect(find.text('Flutter Auto Review Example'), findsOneWidget);

    // Verify that the counter starts at 0
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Verify that we have the expected buttons
    expect(find.text('Reset Rate Us Data'), findsOneWidget);
    expect(find.text('Show Rate Dialog Manually'), findsOneWidget);
    expect(find.text('Trigger from Settings'), findsOneWidget);
    expect(find.text('Auto Trigger'), findsOneWidget);
    expect(find.text('Check Min App Opens'), findsOneWidget);
    expect(find.text('Check Min Days Since Install'), findsOneWidget);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
