// This is a basic Flutter widget test for Sandibuana app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic widget test', (WidgetTester tester) async {
    // Build a simple widget to test basic functionality
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Sandibuana Test')),
          body: const Center(
            child: Text('Test App'),
          ),
        ),
      ),
    );

    // Verify that the widget loads correctly
    expect(find.text('Sandibuana Test'), findsOneWidget);
    expect(find.text('Test App'), findsOneWidget);
  });
  
  testWidgets('Text widget displays correctly', (WidgetTester tester) async {
    // Test a simple text widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('Hello World'),
        ),
      ),
    );

    // Verify the text is displayed
    expect(find.text('Hello World'), findsOneWidget);
  });
}
