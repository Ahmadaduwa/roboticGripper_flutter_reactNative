import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class RobotProvider with ChangeNotifier {
  // === Data State ===
  double _force = 0.0;
  String _material = "Unknown";
  double _confidence = 0.0;
  bool _isConnected = false;

  // === Graph State ===
  final List<FlSpot> _spots = [];
  double _timeX = 0.0;
  Timer? _pollingTimer;

  // === Control State ===
  double _maxForce = 5.0;
  double _gripperPosition = 90.0;
  bool _isSystemOn = false;

  // === Joint Positions ===
  double _j1 = 0.0;
  double _j2 = 0.0;
  double _j3 = 0.0;
  double _j4 = 0.0;
  double _j5 = 0.0;
  double _j6 = 0.0;

  // === System Status ===
  String _controlMode = "MANUAL";
  bool _isRunning = false;

  // === Teaching State ===
  // === Teaching State ===
  // Moved to TeachingProvider

  // Getters
  double get force => _force;
  String get material => _material;
  double get confidence => _confidence;
  bool get isConnected => _isConnected;
  List<FlSpot> get spots => _spots;
  double get maxForce => _maxForce;
  double get gripperPosition => _gripperPosition;
  bool get isSystemOn => _isSystemOn;
  double get j1 => _j1;
  double get j2 => _j2;
  double get j3 => _j3;
  double get j4 => _j4;
  double get j5 => _j5;
  double get j6 => _j6;
  String get controlMode => _controlMode;
  bool get isRunning => _isRunning;

  RobotProvider() {
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) async {
      final data = await ApiService.getSensorData();

      if (data != null) {
        _isConnected = true;
        _force = (data['force'] as num).toDouble();

        // Sync material and confidence from backend
        if (data.containsKey('material')) {
          _material = data['material'];
          _confidence = (data['confidence'] as num).toDouble();
        }

        // Sync joint positions from backend
        if (data.containsKey('j1')) _j1 = (data['j1'] as num).toDouble();
        if (data.containsKey('j2')) _j2 = (data['j2'] as num).toDouble();
        if (data.containsKey('j3')) _j3 = (data['j3'] as num).toDouble();
        if (data.containsKey('j4')) _j4 = (data['j4'] as num).toDouble();
        if (data.containsKey('j5')) _j5 = (data['j5'] as num).toDouble();
        if (data.containsKey('j6')) _j6 = (data['j6'] as num).toDouble();

        // Sync Status
        if (data.containsKey('mode')) _controlMode = data['mode'];
        if (data.containsKey('is_running')) _isRunning = data['is_running'];

        // Update Graph
        _timeX += 0.5;
        _spots.add(FlSpot(_timeX, _force));
        if (_spots.length > 30) _spots.removeAt(0); // Keep last ~15 seconds
      } else {
        _isConnected = false;
        // Hold last value logic can be implemented here if desired,
        // or just show disconnected status
      }
      notifyListeners();
    });
  }

  // === Control Methods ===
  Future<void> updateControl({
    double? maxForce,
    double? gripperPos,
    bool? isOn,
  }) async {
    if (maxForce != null) _maxForce = maxForce;
    if (gripperPos != null) _gripperPosition = gripperPos;
    if (isOn != null) _isSystemOn = isOn;

    // Send Gripper Command (was Jog)
    await ApiService.sendGripperCommand(
      angle: _gripperPosition.toInt(),
      maxForce: _maxForce,
      switchOn: _isSystemOn,
    );
    notifyListeners();
  }

  /// Force system OFF (for sequence execution)
  Future<void> forceSystemOff() async {
    _isSystemOn = false;
    await ApiService.sendGripperCommand(
      angle: _gripperPosition.toInt(),
      maxForce: _maxForce,
      switchOn: false,
    );
    notifyListeners();
  }

  /// Restore system state (after sequence execution)
  Future<void> restoreSystemState(bool previousState) async {
    _isSystemOn = previousState;
    await ApiService.sendGripperCommand(
      angle: _gripperPosition.toInt(),
      maxForce: _maxForce,
      switchOn: previousState,
    );
    notifyListeners();
  }

  // === Teaching Methods (Legacy Removed) ===
  // Use TeachingProvider for teaching functionality

  // === Backend Sync Methods ===
  // No longer needed - RobotProvider polling handles all backend sync

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
