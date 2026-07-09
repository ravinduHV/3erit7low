import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test - Dummy widget builds', (WidgetTester tester) async {
    // Build a simple container and verify it builds.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('MeritFlow'),
          ),
        ),
      ),
    );

    expect(find.text('MeritFlow'), findsOneWidget);
  });
}
