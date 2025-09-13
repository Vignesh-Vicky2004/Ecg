// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecg/main.dart';

void main() {
  testWidgets('App loads without error', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ECGApp());

    // Wait for the app to load
    await tester.pumpAndSettle();

    // Verify that the app loads without throwing an exception
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
