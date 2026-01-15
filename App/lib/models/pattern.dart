import 'pattern_step.dart';

/// Model representing a complete pattern with its steps
class Pattern {
  final int? id;
  final String name;
  final String? description;
  final List<PatternStep> steps;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Pattern({
    this.id,
    required this.name,
    this.description,
    List<PatternStep>? steps,
    this.createdAt,
    this.updatedAt,
  }) : steps = steps ?? [];

  // Convert from JSON (from backend API)
  factory Pattern.fromJson(Map<String, dynamic> json) {
    return Pattern(
      id: json['id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String?,
      steps: (json['steps'] as List<dynamic>?)
              ?.map((step) => PatternStep.fromJson(step as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // Convert from SQLite map
  factory Pattern.fromMap(Map<String, dynamic> map) {
    return Pattern(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      steps: [], // Steps loaded separately
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  // Convert to JSON (for backend API)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      'steps': steps.map((step) => step.toJson()).toList(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Convert to map for SQLite (without steps)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  Pattern copyWith({
    int? id,
    String? name,
    String? description,
    List<PatternStep>? steps,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pattern(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      steps: steps ?? List<PatternStep>.from(this.steps),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get total duration of all wait steps
  double get totalDuration {
    return steps.fold(0.0, (sum, step) {
      if (step.actionType.toLowerCase() == 'wait') {
        return sum + (step.params['duration'] as num? ?? 
                     step.params['wait_time'] as num? ?? 0).toDouble();
      }
      return sum;
    });
  }

  // Get number of steps
  int get stepCount => steps.length;

  // Get formatted last modified time
  String get lastModified {
    if (updatedAt != null) {
      final now = DateTime.now();
      final difference = now.difference(updatedAt!);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    }
    return 'Unknown';
  }

  @override
  String toString() {
    return 'Pattern(id: $id, name: $name, steps: ${steps.length})';
  }
}
