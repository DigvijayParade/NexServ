// Basic smoke test for NexServ app

import 'package:flutter_test/flutter_test.dart';

import 'package:nexserv/main.dart';

void main() {
  testWidgets('NexServ app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const CoopGigApp());
    // Verify that the app renders without crashing
    expect(find.text('NexServ'), findsWidgets);
  });
}
