import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:task_2/main.dart';

void main() {
  testWidgets('Password generator UI test', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const PasswordGeneratorApp());

    // Verify that slider exists
    expect(find.byType(Slider), findsOneWidget);
    
    // Verify that generate button exists
    expect(find.text('Generate Password'), findsOneWidget);
    
    // More relevant tests for your password generator
  });
}
