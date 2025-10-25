import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rebinit_app/main.dart';
// ignore: unused_import
import 'package:rebinit_app/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen displays user info and stats', (WidgetTester tester) async {
    // Mock user ID for testing
    // ignore: unused_local_variable
    const testUserId = 'testUser123';

    // Build the app widget with required parameter
    await tester.pumpWidget(const MyApp(showOnboarding: false));

    // Wait for the widget tree to settle
    await tester.pumpAndSettle();

    // Check if app title/logo exists
    expect(find.text('ReBinIt'), findsOneWidget);

    // Check for greeting text (Hi, User)
    expect(find.textContaining('Hi,'), findsOneWidget);

    // Check that earnings and pickups cards exist
    expect(find.textContaining('Earned'), findsOneWidget);
    expect(find.textContaining('Pickups'), findsOneWidget);

    // Check that the "Have waste to sell?" CTA card exists
    expect(find.textContaining('Have waste to sell?'), findsOneWidget);

    // Check that "Recycle Categories" section exists
    expect(find.text('Recycle Categories'), findsOneWidget);

    // Check that "Recent Pickups" section exists
    expect(find.text('Recent Pickups'), findsOneWidget);

    // Tap on the CTA button (Schedule Pickup)
    final ctaButton = find.widgetWithText(ElevatedButton, 'Schedule a Pickup');
    expect(ctaButton, findsOneWidget);
    await tester.tap(ctaButton);
    await tester.pumpAndSettle();

    // We can now verify if navigation occurred to SellWasteScreen
    // (Assuming SellWasteScreen has a title "Sell Waste")
    expect(find.text('Sell Waste'), findsOneWidget);
  });
}
