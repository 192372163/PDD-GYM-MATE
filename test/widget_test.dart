import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmate_ai/screens/notifications_modal.dart';

void main() {
  testWidgets('Notifications modal renders title and notification items', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NotificationsModal(),
        ),
      ),
    );

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.textContaining('Total'), findsOneWidget);
  });
}
