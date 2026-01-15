import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/pattern.dart';
import '../models/pattern_step.dart';

/// Database service for managing patterns and steps in SQLite
class DatabaseService {
  static Database? _database;
  static const String _dbName = 'robotic_gripper.db';
  static const int _dbVersion = 1;

  // Table names
  static const String _patternsTable = 'patterns';
  static const String _stepsTable = 'pattern_steps';

  // Singleton pattern
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  /// Get database instance (lazy initialization)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create tables on first run
  Future<void> _onCreate(Database db, int version) async {
    // Create patterns table
    await db.execute('''
      CREATE TABLE $_patternsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create pattern_steps table
    await db.execute('''
      CREATE TABLE $_stepsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pattern_id INTEGER NOT NULL,
        step_order INTEGER NOT NULL,
        action_type TEXT NOT NULL,
        params TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (pattern_id) REFERENCES $_patternsTable (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_steps_pattern_id ON $_stepsTable (pattern_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_steps_order ON $_stepsTable (pattern_id, step_order)
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema changes here
  }

  // ==================== Pattern Operations ====================

  /// Save a new pattern with its steps
  Future<int> savePattern(Pattern pattern) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      // Insert pattern
      final patternId = await txn.insert(_patternsTable, {
        if (pattern.id != null) 'id': pattern.id,
        'name': pattern.name,
        'description': pattern.description,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Insert steps
      for (var i = 0; i < pattern.steps.length; i++) {
        final step = pattern.steps[i];
        await txn.insert(_stepsTable, {
          'pattern_id': patternId,
          'step_order': i,
          'action_type': step.actionType,
          'params': step.paramsToString(),
          'created_at': now,
        });
      }

      return patternId;
    });
  }

  /// Update an existing pattern
  Future<bool> updatePattern(Pattern pattern) async {
    if (pattern.id == null) return false;

    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      // Update pattern metadata
      final updateCount = await txn.update(
        _patternsTable,
        {
          'name': pattern.name,
          'description': pattern.description,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [pattern.id],
      );

      if (updateCount == 0) return false;

      // Delete old steps
      await txn.delete(
        _stepsTable,
        where: 'pattern_id = ?',
        whereArgs: [pattern.id],
      );

      // Insert new steps
      for (var i = 0; i < pattern.steps.length; i++) {
        final step = pattern.steps[i];
        await txn.insert(_stepsTable, {
          'pattern_id': pattern.id,
          'step_order': i,
          'action_type': step.actionType,
          'params': step.paramsToString(),
          'created_at': now,
        });
      }

      return true;
    });
  }

  /// Get all patterns (without steps)
  Future<List<Pattern>> getAllPatterns() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _patternsTable,
      orderBy: 'updated_at DESC',
    );

    return maps.map((map) => Pattern.fromMap(map)).toList();
  }

  /// Get a single pattern with all its steps
  Future<Pattern?> getPattern(int id) async {
    final db = await database;

    // Get pattern
    final patternMaps = await db.query(
      _patternsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (patternMaps.isEmpty) return null;

    final pattern = Pattern.fromMap(patternMaps.first);

    // Get steps
    final stepMaps = await db.query(
      _stepsTable,
      where: 'pattern_id = ?',
      whereArgs: [id],
      orderBy: 'step_order ASC',
    );

    final steps = stepMaps.map((map) {
      // Parse JSON params
      final paramsString = map['params'] as String;
      final params = jsonDecode(paramsString) as Map<String, dynamic>;

      return PatternStep(
        id: map['id'] as int,
        patternId: map['pattern_id'] as int,
        stepOrder: map['step_order'] as int,
        actionType: map['action_type'] as String,
        params: params,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
    }).toList();

    return pattern.copyWith(steps: steps);
  }

  /// Get pattern by name
  Future<Pattern?> getPatternByName(String name) async {
    final db = await database;

    final patternMaps = await db.query(
      _patternsTable,
      where: 'name = ?',
      whereArgs: [name],
    );

    if (patternMaps.isEmpty) return null;

    final pattern = Pattern.fromMap(patternMaps.first);
    final id = pattern.id;

    if (id == null) return pattern;

    // Get steps
    final stepMaps = await db.query(
      _stepsTable,
      where: 'pattern_id = ?',
      whereArgs: [id],
      orderBy: 'step_order ASC',
    );

    final steps = stepMaps.map((map) {
      final paramsString = map['params'] as String;
      final params = jsonDecode(paramsString) as Map<String, dynamic>;

      return PatternStep(
        id: map['id'] as int,
        patternId: map['pattern_id'] as int,
        stepOrder: map['step_order'] as int,
        actionType: map['action_type'] as String,
        params: params,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
    }).toList();

    return pattern.copyWith(steps: steps);
  }

  /// Delete a pattern and all its steps
  Future<bool> deletePattern(int id) async {
    final db = await database;
    final count = await db.delete(
      _patternsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    return count > 0;
  }

  /// Delete a specific step from a pattern
  Future<bool> deleteStep(int stepId) async {
    final db = await database;
    final count = await db.delete(
      _stepsTable,
      where: 'id = ?',
      whereArgs: [stepId],
    );
    return count > 0;
  }

  /// Clear all patterns and steps
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(_stepsTable);
      await txn.delete(_patternsTable);
    });
  }

  /// Get pattern count
  Future<int> getPatternCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_patternsTable',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
