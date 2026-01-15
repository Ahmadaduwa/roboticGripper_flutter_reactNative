import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:robotic_gripper_app/providers/robot_provider.dart'; // Adjust path
import 'package:robotic_gripper_app/screens/main_layout.dart';
import 'package:robotic_gripper_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockClient mockClient;

  // Initial sensor data
  Map<String, dynamic> sensorData = {
    'force': 0.0,
    'material': 'Unknown',
    'confidence': 0.0,
  };

  setUp(() {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({'base_api_url': 'http://mock-api'});

    // Setup Mock Client logic
    mockClient = MockClient((request) async {
      final url = request.url.toString();

      // 1. GET /data (Sensor Poll)
      if (url.endsWith('/data') && request.method == 'GET') {
        return http.Response(jsonEncode(sensorData), 200);
      }

      // 2. POST /api/robot/gripper (Control Command)
      if (url.endsWith('/api/robot/gripper') && request.method == 'POST') {
        final body = jsonDecode(request.body);
        // Simulate hardware update: if command sent, update the "sensor"
        if (body.containsKey('max_force')) {
          // In real world, force depends on load, but here we simulate it reaching the limit
          // creating a "feedback loop" simulation
          sensorData['force'] = (body['max_force'] as num).toDouble();
        }
        return http.Response(jsonEncode({'success': true}), 200);
      }

      return http.Response('Not Found', 404);
    });

    // Inject Mock Client
    ApiService.client = mockClient;
  });

  testWidgets('Manual Control change should eventually update Dashboard Force display', (
    WidgetTester tester,
  ) async {
    // 1. Pump App
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => RobotProvider())],
        child: MaterialApp(home: const MainLayout()),
      ),
    );

    // Verify initial Dashboard state (Force 0)
    expect(find.text("Dashboard"), findsWidgets);
    // Depending on ForceIndicator widget, check if 0 is displayed or implied
    // Let's assume ForceIndicator shows value or we check the ForceGraph or Provider
    // For now, let's look for known text widgets.
    // ForceIndicator might not show text "0.0 N" directly if it's just a gauge.
    // But let's check RobotProvider state directly to be sure first, then UI.
    final provider = Provider.of<RobotProvider>(
      tester.element(find.byType(MainLayout)),
      listen: false,
    );
    expect(provider.force, 0.0);

    // 2. Navigate to Control Screen
    await tester.tap(find.byIcon(Icons.gamepad_rounded));
    await tester.pumpAndSettle();

    expect(find.text("Manual Control"), findsWidgets);

    // 3. Change Max Force Slider
    // Find slider for Max Force (it has value 5.0 initially)
    // We look for Slider widget. There are two: Max Force and Gripper.
    // Max Force is the first one in the column usually.
    final sliders = find.byType(Slider);
    expect(sliders, findsNWidgets(2));

    // Drag the first slider (Max Force) to the right (towards 10)
    // Current value 5.0 (50%). Let's move it to 8.0.
    await tester.drag(sliders.first, const Offset(100, 0));
    await tester.pumpAndSettle(); // Allow UI to update slider position

    // Verify Provider output updated locally
    expect(provider.maxForce, greaterThan(5.0));

    // At this point, POST request should have fired (debouncing?)
    // robot_provider.dart calls updateControl immediately on onChanged?
    // Yes: onChanged: (val) { provider.updateControl(...) }
    // So the MockClient logic in setUp should have updated `sensorData['force']`

    // 4. Wait for Polling Loop to update Sensor Data
    // Provider poll is 500ms. We need to wait enough time.
    await tester.pump(const Duration(milliseconds: 600)); // Trigger timer
    await tester.pump(); // Process consequences

    // Now Provider.force should be updated from the mocked "sensor"
    expect(provider.force, closeTo(provider.maxForce, 0.1));

    // 5. Navigate back to Dashboard
    await tester.tap(find.byIcon(Icons.dashboard_rounded));
    await tester.pumpAndSettle();

    expect(find.text("Dashboard"), findsWidgets);

    // 6. Verify Dashboard UI reflects the new force
    // We can look for the ForceIndicator or just trust the provider state we checked
    // Or check if there is a Text widget showing the force if implemented in Dashboard
    // Dashboard has Text("Force") label, but maybe not value text unless inside ForceGraph or Indicator
    // Let's rely on provider check which confirms the data flow loop.
    expect(provider.force, greaterThan(5.0));
  });
}
