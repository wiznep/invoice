import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoice/main.dart';

void main() {
  testWidgets('App loads with loading screen', (WidgetTester tester) async {
    await tester.pumpWidget(const InvoiceApp());

    // Verify the app title is shown during loading
    expect(find.text('Invoice'), findsOneWidget);
  });
}
