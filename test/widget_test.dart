import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beacon/main.dart';

void main() {
  testWidgets('Beacon app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BeaconApp());

    // Verify that app starts
    expect(find.text('Beacon'), findsOneWidget);
  });
}
