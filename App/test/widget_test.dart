import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:robotic_gripper_app/main.dart';
import 'package:robotic_gripper_app/screens/dashboard_screen.dart';

import 'dart:io';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  testWidgets('Dashboard loads and shows basic UI smoke test', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({}); // Mock Prefs

    // Build our app and trigger a frame.
    await tester.pumpWidget(const RoboticGripperApp());

    // Allow time for the Provider layout (Consumer) to build
    await tester.pump();

    // Verify Dashboard is present
    expect(find.byType(DashboardScreen), findsOneWidget);

    // Verify initial disconnected state (mock/default)
    // Note: Provider starts with isConnected = false
    expect(find.text('Disconnected'), findsOneWidget);
    expect(find.text('Force History'), findsOneWidget);
  });
}
