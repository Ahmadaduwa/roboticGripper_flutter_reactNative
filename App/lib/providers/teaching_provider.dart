import 'package:flutter/material.dart';
import '../models/pattern.dart';
import '../models/pattern_step.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';

/// Provider for managing teaching mode state and operations
class TeachingProvider with ChangeNotifier {
  // ==================== State Variables ====================
  
  // Pattern Management
  List<Pattern> _patterns = [];
  Pattern? _currentPattern;
  bool _isLoadingPatterns = false;

  // Step Recording Buffer
  List<PatternStep> _recordingBuffer = [];
  bool _isRecording = false;

  // Current gripper/robot state
  double _currentGripperAngle = 90.0;
  bool _isGripping = false;
  bool _isGripMode = true; // Toggle state for Grip/Release button

  // Execution state
  bool _isExecuting = false;
  int _currentExecutingStep = -1;

  // Sync state
  bool _isSyncing = false;
  String? _lastSyncError;
  DateTime? _lastSyncTime;
  bool _isBackendAvailable = false;

  // ==================== Getters ====================
  
  List<Pattern> get patterns => _patterns;
  Pattern? get currentPattern => _currentPattern;
  bool get isLoadingPatterns => _isLoadingPatterns;
  
  List<PatternStep> get recordingBuffer => _recordingBuffer;
  bool get isRecording => _isRecording;
  
  double get currentGripperAngle => _currentGripperAngle;
  bool get isGripping => _isGripping;
  bool get isGripMode => _isGripMode;
  
  bool get isExecuting => _isExecuting;
  int get currentExecutingStep => _currentExecutingStep;
  
  bool get isSyncing => _isSyncing;
  String? get lastSyncError => _lastSyncError;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isBackendAvailable => _isBackendAvailable;

  // ==================== Initialization ====================
  
  TeachingProvider() {
    _loadPatternsFromDatabase();
  }

  /// Load patterns from local SQLite database
  Future<void> _loadPatternsFromDatabase() async {
    _isLoadingPatterns = true;
    notifyListeners();

    try {
      _patterns = await DatabaseService.instance.getAllPatterns();
      
      // Load steps for each pattern
      for (var i = 0; i < _patterns.length; i++) {
        if (_patterns[i].id != null) {
          final fullPattern = await DatabaseService.instance.getPattern(_patterns[i].id!);
          if (fullPattern != null) {
            _patterns[i] = fullPattern;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading patterns from database: $e');
    } finally {
      _isLoadingPatterns = false;
      notifyListeners();
    }
  }

  // ==================== Pattern Management ====================

  /// Create a new pattern (sets as current)
  void createNewPattern(String name, {String? description}) {
    _currentPattern = Pattern(
      name: name,
      description: description,
      steps: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _recordingBuffer.clear();
    notifyListeners();
  }

  /// Load an existing pattern for editing
  Future<void> loadPattern(int id) async {
    try {
      _currentPattern = await DatabaseService.instance.getPattern(id);
      if (_currentPattern != null) {
        _recordingBuffer = List.from(_currentPattern!.steps);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading pattern: $e');
    }
  }

  /// Save current pattern to database
  Future<bool> saveCurrentPattern() async {
    if (_currentPattern == null) return false;

    try {
      // Update pattern with current buffer
      final updatedPattern = _currentPattern!.copyWith(
        steps: List.from(_recordingBuffer),
        updatedAt: DateTime.now(),
      );

      int patternId;
      if (updatedPattern.id == null) {
        // New pattern
        patternId = await DatabaseService.instance.savePattern(updatedPattern);
        _currentPattern = updatedPattern.copyWith(id: patternId);
      } else {
        // Update existing
        await DatabaseService.instance.updatePattern(updatedPattern);
        _currentPattern = updatedPattern;
      }

      // Reload patterns list
      await _loadPatternsFromDatabase();

      // Push this pattern to backend immediately (CRUD parity)
      try {
        final patternMap = _currentPattern!.toJson();
        final steps = _currentPattern!.steps
            .map((s) => {
                  'step_order': s.stepOrder,
                  'action_type': s.actionType,
                  'params': s.params,
                })
            .toList();
        patternMap['steps'] = steps;
        await ApiService.pushPatterns([patternMap]);
      } catch (e) {
        debugPrint('Warn: failed to push pattern to backend: $e');
      }
      // Then run full sync to reconcile
      await syncWithBackend();
      
      return true;
    } catch (e) {
      debugPrint('Error saving pattern: $e');
      return false;
    }
  }

  /// Delete a pattern
  Future<bool> deletePattern(int id) async {
    try {
      final success = await DatabaseService.instance.deletePattern(id);
      if (success) {
        _patterns.removeWhere((p) => p.id == id);
        if (_currentPattern?.id == id) {
          _currentPattern = null;
          _recordingBuffer.clear();
        }
        notifyListeners();

        // Delete on backend API (best-effort) to keep simulation DB consistent
        try {
          await ApiService.deletePattern(id);
        } catch (e) {
          debugPrint('Warn: failed to delete pattern on backend: $e');
        }

        // Then reconcile both sides
        await syncWithBackend();
      }
      return success;
    } catch (e) {
      debugPrint('Error deleting pattern: $e');
      return false;
    }
  }

  /// Update pattern name
  void updatePatternName(String name) {
    if (_currentPattern != null) {
      _currentPattern = _currentPattern!.copyWith(name: name);
      notifyListeners();
    }
  }

  /// Update pattern description
  void updatePatternDescription(String description) {
    if (_currentPattern != null) {
      _currentPattern = _currentPattern!.copyWith(description: description);
      notifyListeners();
    }
  }

  // ==================== Step Recording ====================

  /// Start recording mode
  void startRecording() {
    _isRecording = true;
    notifyListeners();
  }

  /// Stop recording mode
  void stopRecording() {
    _isRecording = false;
    notifyListeners();
  }

  /// Add a grip step and toggle to release mode
  void addGripStep(double angle) {
    final step = PatternStep(
      stepOrder: _recordingBuffer.length,
      actionType: 'grip',
      params: {'angle': angle},
      createdAt: DateTime.now(),
    );
    _recordingBuffer.add(step);
    _isGripping = true;
    _currentGripperAngle = angle;
    _isGripMode = false; // Toggle to release mode
    notifyListeners();
  }

  /// Add a release step and toggle to grip mode
  void addReleaseStep(double angle) {
    final step = PatternStep(
      stepOrder: _recordingBuffer.length,
      actionType: 'release',
      params: {'angle': angle},
      createdAt: DateTime.now(),
    );
    _recordingBuffer.add(step);
    _isGripping = false;
    _currentGripperAngle = angle;
    _isGripMode = true; // Toggle back to grip mode
    notifyListeners();
  }

  /// Add a wait step to buffer
  void addWaitStep(double duration) {
    final step = PatternStep(
      stepOrder: _recordingBuffer.length,
      actionType: 'wait',
      params: {'duration': duration},
      createdAt: DateTime.now(),
    );
    _recordingBuffer.add(step);
    notifyListeners();
  }

  /// Add a move step to buffer
  void addMoveStep(Map<String, dynamic> jointPositions) {
    final step = PatternStep(
      stepOrder: _recordingBuffer.length,
      actionType: 'move_joints',
      params: jointPositions,
      createdAt: DateTime.now(),
    );
    _recordingBuffer.add(step);
    notifyListeners();
  }

  /// Add current position from robot (fetch from backend)
  Future<bool> addCurrentPosition() async {
    try {
      // Fetch current robot position from backend
      final data = await ApiService.getSensorData();
      if (data == null) return false;

      // Extract joint positions from response
      final jointPositions = {
        'j1': data['j1'] ?? 0.0,
        'j2': data['j2'] ?? 0.0,
        'j3': data['j3'] ?? 0.0,
        'j4': data['j4'] ?? 0.0,
        'j5': data['j5'] ?? 0.0,
        'j6': data['j6'] ?? 0.0,
      };

      addMoveStep(jointPositions);
      return true;
    } catch (e) {
      debugPrint('Error adding current position: $e');
      return false;
    }
  }

  /// Delete a step from buffer
  void deleteStep(int index) {
    if (index >= 0 && index < _recordingBuffer.length) {
      _recordingBuffer.removeAt(index);
      
      // Re-order remaining steps
      for (var i = index; i < _recordingBuffer.length; i++) {
        _recordingBuffer[i] = _recordingBuffer[i].copyWith(stepOrder: i);
      }
      
      notifyListeners();
    }
  }

  /// Clear all steps from buffer
  void clearBuffer() {
    _recordingBuffer.clear();
    notifyListeners();
  }

  /// Move step up in order
  void moveStepUp(int index) {
    if (index > 0 && index < _recordingBuffer.length) {
      final step = _recordingBuffer.removeAt(index);
      _recordingBuffer.insert(index - 1, step);
      _reorderSteps();
      notifyListeners();
    }
  }

  /// Move step down in order
  void moveStepDown(int index) {
    if (index >= 0 && index < _recordingBuffer.length - 1) {
      final step = _recordingBuffer.removeAt(index);
      _recordingBuffer.insert(index + 1, step);
      _reorderSteps();
      notifyListeners();
    }
  }

  /// Reorder all steps
  void _reorderSteps() {
    for (var i = 0; i < _recordingBuffer.length; i++) {
      _recordingBuffer[i] = _recordingBuffer[i].copyWith(stepOrder: i);
    }
  }

  // ==================== Pattern Execution ====================

  /// Execute buffer on backend simulation with manual-control parameters
  Future<bool> executeOnBackend({
    required double maxForce,
    required double gripperAngle,
    required bool isOn,
  }) async {
    if (_recordingBuffer.isEmpty) return false;

    _isExecuting = true;
    _currentExecutingStep = 0;
    notifyListeners();

    try {
      final steps = _recordingBuffer.map((step) => {
            "step_order": step.stepOrder,
            "action_type": step.actionType,
            "params": step.params,
          }).toList();

      final ok = await ApiService.executeSequence(
        steps: steps,
        maxForce: maxForce,
        gripperAngle: gripperAngle,
        isOn: isOn,
        patternName: _currentPattern?.name ?? 'Untitled',
      );
      
      if (ok) {
        // Wait for sequence to finish by polling backend status
        await _waitForSequenceCompletion();
      }
      
      return ok;
    } catch (e) {
      debugPrint('Error executing buffer on backend: $e');
      return false;
    } finally {
      _isExecuting = false;
      _currentExecutingStep = -1;
      notifyListeners();
    }
  }

  /// Poll backend until sequence execution is complete
  Future<void> _waitForSequenceCompletion() async {
    const maxWaitSeconds = 300; // 5 minutes timeout
    const pollInterval = Duration(milliseconds: 500);
    final startTime = DateTime.now();
    
    while (true) {
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      if (elapsed > maxWaitSeconds) {
        debugPrint('⚠️ Sequence timeout after ${maxWaitSeconds}s');
        break;
      }
      
      // Poll backend status
      final data = await ApiService.getSensorData();
      if (data != null) {
        final isRunning = data['is_running'] as bool? ?? false;
        final mode = data['mode'] as String? ?? 'MANUAL';
        
        // Sequence done when mode returns to MANUAL and not running
        if (!isRunning && mode == 'MANUAL') {
          debugPrint('✅ Sequence completed');
          break;
        }
      }
      
      await Future.delayed(pollInterval);
    }
  }

  /// Stop current execution
  void stopExecution() {
    _isExecuting = false;
    _currentExecutingStep = -1;
    notifyListeners();
  }

  // ==================== Backend Sync ====================

  /// Check if backend is available (online-only mode enforcement)
  Future<bool> checkBackendAvailability() async {
    try {
      final available = await ApiService.checkBackendAvailable();
      _isBackendAvailable = available;
      notifyListeners();
      return available;
    } catch (e) {
      _isBackendAvailable = false;
      notifyListeners();
      return false;
    }
  }

  /// Full bidirectional sync: Push local changes first, then pull to reconcile
  Future<bool> syncWithBackend() async {
    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

    try {
      // Step 1: Check backend availability
      final available = await checkBackendAvailability();
      if (!available) {
        throw Exception('Backend not available');
      }

      // Step 2: Push local patterns to backend first (authoritative after CRUD)
      final localPatterns = await DatabaseService.instance.getAllPatterns();
      final pushPayload = <Map<String, dynamic>>[];
      
      for (final pattern in localPatterns) {
        // Load full pattern with steps
        final fullPattern = pattern.id != null 
            ? await DatabaseService.instance.getPattern(pattern.id!)
            : pattern;
        
        if (fullPattern != null) {
          pushPayload.add({
            'id': fullPattern.id,
            'name': fullPattern.name,
            'description': fullPattern.description,
            'steps': fullPattern.steps.map((s) => {
              'step_order': s.stepOrder,
              'action_type': s.actionType,
              'params': s.params,
            }).toList(),
          });
        }
      }
      
      final pushSuccess = await ApiService.pushPatterns(pushPayload);
      debugPrint('Pushed ${pushPayload.length} pattern(s) to backend: $pushSuccess');

      // Step 3: Pull patterns from backend (GET /api/sync/patterns) to reconcile
      final pullResponse = await ApiService.pullPatterns();
      debugPrint('Pulled ${pullResponse.length} pattern(s) from backend');
      
      // Merge pulled patterns into local database
      for (final patternData in pullResponse) {
        if (patternData is! Map<String, dynamic>) continue;
        
        final id = patternData['id'] as int?;
        final name = patternData['name'] as String? ?? 'Unnamed';
        final stepsData = patternData['steps'] as List<dynamic>? ?? [];
        
        // Check if exists locally
        final localPattern = id != null 
            ? await DatabaseService.instance.getPattern(id)
            : await DatabaseService.instance.getPatternByName(name);
        
        if (localPattern == null) {
          // New pattern from backend
          final steps = stepsData.map((s) {
            if (s is! Map<String, dynamic>) return null;
            return PatternStep(
              stepOrder: s['step_order'] as int? ?? 0,
              actionType: s['action_type'] as String? ?? 'wait',
              params: Map<String, dynamic>.from(s['params'] as Map? ?? {}),
              createdAt: DateTime.now(),
            );
          }).whereType<PatternStep>().toList();
          
          final newPattern = Pattern(
            name: name,
            steps: steps,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await DatabaseService.instance.savePattern(newPattern);
        } else {
          // Pattern exists - update with backend copy
          final steps = stepsData.map((s) {
            if (s is! Map<String, dynamic>) return null;
            return PatternStep(
              stepOrder: s['step_order'] as int? ?? 0,
              actionType: s['action_type'] as String? ?? 'wait',
              params: Map<String, dynamic>.from(s['params'] as Map? ?? {}),
              createdAt: DateTime.now(),
            );
          }).whereType<PatternStep>().toList();
          
          final updatedPattern = localPattern.copyWith(
            steps: steps,
            updatedAt: DateTime.now(),
          );
          await DatabaseService.instance.updatePattern(updatedPattern);
        }
      }

      // Step 4: Reload from local database
      await _loadPatternsFromDatabase();
      
      _lastSyncTime = DateTime.now();
      return true;
    } catch (e) {
      _lastSyncError = e.toString();
      debugPrint('Error syncing with backend: $e');
      _isBackendAvailable = false;
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // ==================== Utility Methods ====================

  /// Refresh patterns from database
  Future<void> refreshPatterns() async {
    await _loadPatternsFromDatabase();
  }

  /// Get total number of patterns
  int get patternCount => _patterns.length;

  /// Get current buffer step count
  int get bufferStepCount => _recordingBuffer.length;

  /// Check if buffer has unsaved changes
  bool get hasUnsavedChanges {
    if (_currentPattern == null) return _recordingBuffer.isNotEmpty;
    
    if (_currentPattern!.steps.length != _recordingBuffer.length) return true;
    
    for (var i = 0; i < _recordingBuffer.length; i++) {
      if (_recordingBuffer[i].actionType != _currentPattern!.steps[i].actionType) {
        return true;
      }
    }
    
    return false;
  }
}
