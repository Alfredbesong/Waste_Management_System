import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:wastemanagement/app/waste_management_app.dart';

void main() {
  testWidgets('app shows the waste management home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      WasteManagementApp(navigatorKey: GlobalKey<NavigatorState>()),
    );

    expect(find.text('Smart Waste Management'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Authentication'), findsOneWidget);
  });
}
