# Teaching Mode System - Implementation Guide

## Overview

This document describes the Teaching Mode system implementation for the Robotic Gripper application. The system allows users to program gripper movement sequences without writing code (No-code Programming).

## System Architecture

### 1. Data Models

#### PatternStep (`lib/models/pattern_step.dart`)
Represents a single step in a pattern sequence.

**Properties:**
- `id`: Database ID (auto-increment)
- `patternId`: Foreign key to parent pattern
- `stepOrder`: Execution order (0-based index)
- `actionType`: Type of action ('grip', 'release', 'wait', 'move_joints')
- `params`: JSON object containing step-specific parameters
- `createdAt`: Timestamp

**Key Methods:**
- `fromJson()`: Convert from JSON (API response)
- `toMap()`: Convert to SQLite format
- `description`: Human-readable step description
- `paramsToString()`: Convert params to JSON string for SQLite

**Example Usage:**
```dart
final gripStep = PatternStep(
  stepOrder: 0,
  actionType: 'grip',
  params: {'angle': 45.0},
  createdAt: DateTime.now(),
);
```

#### Pattern (`lib/models/pattern.dart`)
Represents a complete pattern with multiple steps.

**Properties:**
- `id`: Database ID
- `name`: Pattern name (unique)
- `description`: Optional description
- `steps`: List of PatternStep objects
- `createdAt`: Creation timestamp
- `updatedAt`: Last modification timestamp

**Computed Properties:**
- `totalDuration`: Sum of all wait durations
- `stepCount`: Number of steps
- `lastModified`: Formatted time string

**Example Usage:**
```dart
final pattern = Pattern(
  name: 'Pick and Place',
  description: 'Basic pick and place operation',
  steps: [
    PatternStep(stepOrder: 0, actionType: 'release', params: {'angle': 90}),
    PatternStep(stepOrder: 1, actionType: 'wait', params: {'duration': 1.0}),
    PatternStep(stepOrder: 2, actionType: 'grip', params: {'angle': 45}),
  ],
);
```

### 2. Database Layer

#### DatabaseService (`lib/services/database_service.dart`)
Manages SQLite database operations for offline storage.

**Database Schema:**

```sql
-- Patterns Table
CREATE TABLE patterns (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- Pattern Steps Table
CREATE TABLE pattern_steps (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pattern_id INTEGER NOT NULL,
  step_order INTEGER NOT NULL,
  action_type TEXT NOT NULL,
  params TEXT NOT NULL,  -- JSON string
  created_at TEXT NOT NULL,
  FOREIGN KEY (pattern_id) REFERENCES patterns (id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX idx_steps_pattern_id ON pattern_steps (pattern_id);
CREATE INDEX idx_steps_order ON pattern_steps (pattern_id, step_order);
```

**Key Methods:**
- `savePattern(Pattern)`: Save new pattern with steps (transaction)
- `updatePattern(Pattern)`: Update existing pattern
- `getAllPatterns()`: Get all patterns (without steps)
- `getPattern(int id)`: Get pattern with all steps
- `getPatternByName(String)`: Find pattern by name
- `deletePattern(int id)`: Delete pattern (cascade deletes steps)
- `deleteStep(int stepId)`: Delete individual step
- `clearAllData()`: Reset database

**Usage Example:**
```dart
final db = DatabaseService.instance;

// Save pattern
final patternId = await db.savePattern(myPattern);

// Load pattern
final pattern = await db.getPattern(patternId);

// Update pattern
await db.updatePattern(pattern.copyWith(name: 'New Name'));

// Delete pattern
await db.deletePattern(patternId);
```

### 3. API Service

#### Enhanced ApiService (`lib/services/api_service.dart`)
Extended with pattern management endpoints.

**New API Methods:**

```dart
// 7. GET /api/patterns - Get all saved patterns
static Future<List<dynamic>> getPatterns()

// 8. GET /api/patterns/{id} - Get specific pattern with steps
static Future<Map<String, dynamic>?> getPattern(int id)

// 9. DELETE /api/patterns/{id} - Delete pattern from backend
static Future<bool> deletePattern(int id)

// 10. DELETE /api/teach/buffer/{index} - Delete step from buffer
static Future<bool> deleteBufferStep(int index)

// 11. POST /api/teach/execute - Test/execute current buffer
static Future<bool> executeBuffer()

// 12. DELETE /api/teach/buffer/clear - Clear entire buffer
static Future<bool> clearBuffer()
```

**Backend Integration:**
All methods handle network errors gracefully and return appropriate types (null/empty/false on failure).

### 4. State Management

#### TeachingProvider (`lib/providers/teaching_provider.dart`)
Central state management for Teaching Mode.

**State Variables:**
- `_patterns`: List of all patterns (loaded from database)
- `_currentPattern`: Currently editing pattern
- `_recordingBuffer`: Current sequence being recorded
- `_isRecording`: Recording mode flag
- `_currentGripperAngle`: Current gripper position
- `_isExecuting`: Execution in progress flag
- `_currentExecutingStep`: Index of currently executing step

**Pattern Management Methods:**
```dart
// Create new pattern
void createNewPattern(String name, {String? description})

// Load existing pattern for editing
Future<void> loadPattern(int id)

// Save current pattern to database
Future<bool> saveCurrentPattern()

// Delete pattern
Future<bool> deletePattern(int id)

// Update metadata
void updatePatternName(String name)
void updatePatternDescription(String description)
```

**Step Recording Methods:**
```dart
// Start/stop recording
void startRecording()
void stopRecording()

// Add different step types
void addGripStep(double angle)
void addReleaseStep(double angle)
void addWaitStep(double duration)
void addMoveStep(Map<String, dynamic> jointPositions)

// Manage steps
void deleteStep(int index)
void clearBuffer()
void moveStepUp(int index)
void moveStepDown(int index)
```

**Execution Methods:**
```dart
// Execute current buffer (test mode)
Future<bool> executeCurrentBuffer()

// Stop execution
void stopExecution()
```

**Sync Methods:**
```dart
// Sync with backend
Future<bool> syncWithBackend()

// Refresh patterns from database
Future<void> refreshPatterns()
```

**Computed Properties:**
```dart
int get patternCount           // Total patterns
int get bufferStepCount        // Steps in buffer
bool get hasUnsavedChanges     // Check for unsaved changes
```

### 5. User Interface

#### TeachingScreen (`lib/screens/teaching_screen.dart`)
Main UI for Teaching Mode with two views: List View and Detail View.

**View 1: Pattern List View**

Components:
- Pattern cards showing:
  - Name and description
  - Number of steps
  - Last modified time
  - Delete button
- "Create New Pattern" button
- Sync button (in app bar)

Features:
- Load patterns from database on init
- Click pattern to edit
- Delete with confirmation dialog
- Sync with backend server

**View 2: Pattern Detail/Editor View**

Components:

1. **Pattern Info Card**
   - Editable name field
   - Editable description field

2. **Action Controller**
   - GRIP button (orange) - Add grip step
   - RELEASE button (blue) - Add release step
   - Grip angle input field
   - Release angle input field
   - Wait duration input field
   - ADD WAIT button

3. **Recorded Sequence List**
   - Shows all steps in order
   - Each step displays:
     - Step number
     - Action type icon (color-coded)
     - Description
     - Move up/down buttons
     - Delete button
   - "Clear All" button
   - Empty state message

4. **Testing Area**
   - "PLAY SEQUENCE" button
   - Executes current buffer step-by-step
   - Shows execution progress
   - Can be stopped mid-execution

5. **Save Button**
   - Saves pattern to database
   - Returns to list view on success

**Color Coding:**
- Grip steps: Orange (#FF6F00)
- Release steps: Blue (#1976D2)
- Wait steps: Purple (#7B1FA2)
- Move steps: Green (#388E3C)

**Dialogs:**
- Create Pattern Dialog (name + description input)
- Delete Confirmation Dialog
- Clear Buffer Confirmation Dialog

## Data Flow

### Recording a New Pattern

```
1. User clicks "CREATE NEW PATTERN"
   ↓
2. Dialog opens for name/description input
   ↓
3. TeachingProvider.createNewPattern() creates empty pattern
   ↓
4. Detail view opens
   ↓
5. User adds steps using action buttons
   ↓
6. Each action calls provider methods (addGripStep, addWaitStep, etc.)
   ↓
7. Steps added to _recordingBuffer
   ↓
8. UI updates via notifyListeners()
   ↓
9. User clicks "SAVE PATTERN"
   ↓
10. TeachingProvider.saveCurrentPattern()
    ↓
11. DatabaseService.savePattern() saves to SQLite
    ↓
12. Pattern list refreshes
    ↓
13. Returns to list view
```

### Executing a Pattern

```
1. User opens pattern in detail view
   ↓
2. Pattern steps loaded into buffer
   ↓
3. User clicks "PLAY SEQUENCE"
   ↓
4. TeachingProvider.executeCurrentBuffer() starts
   ↓
5. For each step:
   - Set _currentExecutingStep index
   - UI highlights current step (green)
   - Execute action via API:
     * Grip/Release → ApiService.sendGripperCommand()
     * Wait → Future.delayed()
     * Move → (future implementation)
   - Small delay between steps
   ↓
6. Execution completes
   ↓
7. UI shows success/failure message
   ↓
8. _currentExecutingStep reset to -1
```

### Syncing with Backend

```
1. User clicks sync button
   ↓
2. TeachingProvider.syncWithBackend()
   ↓
3. ApiService.getPatterns() fetches backend patterns
   ↓
4. For each backend pattern:
   - Check if exists locally (by name)
   - If new: save to local database
   - If exists: compare updatedAt timestamps
   - If backend newer: update local version
   ↓
5. Refresh patterns from database
   ↓
6. UI updates with synced patterns
   ↓
7. Show success/error message
```

## Backend API Requirements

The Teaching Mode system expects the following backend endpoints:

### Teaching/Recording Endpoints

```
POST /api/teach/record
Body: {
  "action_type": "grip" | "release" | "wait" | "move_joints",
  "wait_time": 1.0  // optional, for wait actions
}
Response: 200 OK

GET /api/teach/buffer
Response: [
  {
    "action_type": "grip",
    "params": {...}
  },
  ...
]

POST /api/teach/save
Body: {
  "name": "Pattern Name"
}
Response: 200 OK

POST /api/teach/execute
Response: 200 OK

DELETE /api/teach/buffer/{index}
Response: 200 OK

DELETE /api/teach/buffer/clear
Response: 200 OK
```

### Pattern Management Endpoints

```
GET /api/patterns
Response: [
  {
    "id": 1,
    "name": "Pattern 1",
    "description": "...",
    "created_at": "2026-01-10T12:00:00Z",
    "updated_at": "2026-01-10T12:00:00Z",
    "steps": [...]
  },
  ...
]

GET /api/patterns/{id}
Response: {
  "id": 1,
  "name": "Pattern 1",
  "description": "...",
  "steps": [
    {
      "id": 1,
      "pattern_id": 1,
      "step_order": 0,
      "action_type": "grip",
      "params": {"angle": 45},
      "created_at": "2026-01-10T12:00:00Z"
    },
    ...
  ]
}

DELETE /api/patterns/{id}
Response: 200 OK
```

### Control Endpoint (Existing)

```
POST /api/robot/gripper
Body: {
  "angle": 45,
  "max_force": 5.0,
  "switch_on": true
}
Response: 200 OK
```

## Usage Examples

### Creating a Simple Pick-and-Place Pattern

```dart
// 1. Create new pattern
provider.createNewPattern('Pick and Place', description: 'Basic operation');

// 2. Add steps
provider.addReleaseStep(90.0);    // Open gripper
provider.addWaitStep(0.5);        // Wait
provider.addGripStep(45.0);       // Close gripper
provider.addWaitStep(1.0);        // Hold
provider.addReleaseStep(90.0);    // Release

// 3. Test execution
await provider.executeCurrentBuffer();

// 4. Save if successful
await provider.saveCurrentPattern();
```

### Loading and Modifying Existing Pattern

```dart
// Load pattern by ID
await provider.loadPattern(patternId);

// Add new step
provider.addWaitStep(2.0);

// Move step up
provider.moveStepUp(2);

// Delete step
provider.deleteStep(0);

// Save changes
await provider.saveCurrentPattern();
```

### Syncing with Backend

```dart
// Sync patterns
final success = await provider.syncWithBackend();

if (success) {
  print('Synced at: ${provider.lastSyncTime}');
} else {
  print('Sync failed: ${provider.lastSyncError}');
}
```

## Testing Checklist

- [ ] Create new pattern
- [ ] Add grip step
- [ ] Add release step
- [ ] Add wait step
- [ ] Delete step
- [ ] Move step up/down
- [ ] Clear all steps
- [ ] Execute pattern
- [ ] Save pattern
- [ ] Load pattern
- [ ] Edit pattern name
- [ ] Edit pattern description
- [ ] Delete pattern
- [ ] Sync with backend
- [ ] Handle offline mode
- [ ] Handle API errors
- [ ] Test with empty database
- [ ] Test with multiple patterns

## Future Enhancements

1. **Pattern Duplication**: Clone existing patterns
2. **Step Templates**: Pre-defined step combinations
3. **Pattern Import/Export**: JSON file support
4. **Visual Timeline**: Graphical step editor
5. **Loop Support**: Repeat sequences
6. **Conditional Steps**: If/then logic
7. **Variable Speed**: Different execution speeds
8. **Pattern Categories**: Organize by type/function
9. **Search/Filter**: Find patterns quickly
10. **Backup/Restore**: Cloud backup integration

## Performance Considerations

- Database queries are optimized with indexes
- Pattern list loads without steps initially (lazy loading)
- Steps loaded only when pattern is opened
- Sync operation uses timestamps to minimize data transfer
- UI updates use ChangeNotifier efficiently (minimal rebuilds)
- Large pattern lists use ListView for memory efficiency

## Error Handling

All critical operations include error handling:
- Database operations catch exceptions and return false/null
- API calls catch network errors gracefully
- UI shows appropriate error messages
- Unsaved changes detection prevents data loss
- Transaction rollback on database errors

## Accessibility

- All interactive elements have proper tap targets (min 48x48)
- Color coding supplemented with icons
- Text contrast meets WCAG standards
- Form fields have labels
- Dialogs have clear actions

---

**Implementation Status**: ✅ Complete

**Last Updated**: January 10, 2026

**Dependencies**:
- flutter_sdk: ^3.10.3
- provider: ^6.1.5
- sqflite: ^2.4.2
- http: ^1.6.0
- google_fonts: ^6.3.3
