/// Model representing a single step in a pattern sequence
class PatternStep {
  final int? id;
  final int? patternId;
  final int stepOrder;
  final String actionType; // 'grip', 'release', 'wait', 'move_joints'
  final Map<String, dynamic> params;
  final DateTime? createdAt;

  PatternStep({
    this.id,
    this.patternId,
    required this.stepOrder,
    required this.actionType,
    required this.params,
    this.createdAt,
  });

  // Convert from JSON
  factory PatternStep.fromJson(Map<String, dynamic> json) {
    return PatternStep(
      id: json['id'] as int?,
      patternId: json['pattern_id'] as int?,
      stepOrder: json['step_order'] as int,
      actionType: json['action_type'] as String,
      params: json['params'] is String 
          ? Map<String, dynamic>.from(
              // Handle JSON string
              json['params'] as Map
            )
          : Map<String, dynamic>.from(json['params'] as Map),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  // Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (patternId != null) 'pattern_id': patternId,
      'step_order': stepOrder,
      'action_type': actionType,
      'params': params,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  // Convert to map for SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (patternId != null) 'pattern_id': patternId,
      'step_order': stepOrder,
      'action_type': actionType,
      'params': paramsToString(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  // Helper to convert params to JSON string for SQLite
  String paramsToString() {
    final buffer = StringBuffer('{');
    final entries = params.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      buffer.write('"${entry.key}":');
      if (entry.value is String) {
        buffer.write('"${entry.value}"');
      } else {
        buffer.write('${entry.value}');
      }
      if (i < entries.length - 1) buffer.write(',');
    }
    buffer.write('}');
    return buffer.toString();
  }

  // Create a copy with updated fields
  PatternStep copyWith({
    int? id,
    int? patternId,
    int? stepOrder,
    String? actionType,
    Map<String, dynamic>? params,
    DateTime? createdAt,
  }) {
    return PatternStep(
      id: id ?? this.id,
      patternId: patternId ?? this.patternId,
      stepOrder: stepOrder ?? this.stepOrder,
      actionType: actionType ?? this.actionType,
      params: params ?? Map<String, dynamic>.from(this.params),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Display-friendly description
  String get description {
    switch (actionType.toLowerCase()) {
      case 'grip':
        return 'Grip (Close)';
      case 'release':
        return 'Release (Open)';
      case 'wait':
        return 'Wait ${params['duration'] ?? params['wait_time'] ?? 1}s';
      case 'move_joints':
        final j1 = params['j1']?.toStringAsFixed(0) ?? '0';
        final j2 = params['j2']?.toStringAsFixed(0) ?? '0';
        final j3 = params['j3']?.toStringAsFixed(0) ?? '0';
        final j4 = params['j4']?.toStringAsFixed(0) ?? '0';
        final j5 = params['j5']?.toStringAsFixed(0) ?? '0';
        final j6 = params['j6']?.toStringAsFixed(0) ?? '0';
        return 'Position (J1:$j1° J2:$j2° J3:$j3° J4:$j4° J5:$j5° J6:$j6°)';
      default:
        return actionType;
    }
  }

  @override
  String toString() {
    return 'PatternStep(id: $id, order: $stepOrder, type: $actionType, params: $params)';
  }
}
