# API Documentation
## Robotic Gripper Control Application v1.0.0

This document describes the REST API endpoints used by the Flutter application to communicate with the Python backend (`simulation.py`).

---

## Table of Contents

1. [Base URL](#base-url)
2. [Authentication](#authentication)
3. [Response Format](#response-format)
4. [Error Handling](#error-handling)
5. [Endpoints](#endpoints)
   - [Health Check](#1-health-check)
   - [Robot Status](#2-robot-status)
   - [Gripper Control](#3-gripper-control)
   - [Pattern Management](#4-pattern-management)
   - [Teaching Mode](#5-teaching-mode)
6. [Data Models](#data-models)
7. [Examples](#examples)

---

## Base URL

Default backend URL:
```
http://localhost:5000
```

For network deployment, replace with:
```
http://<backend-ip>:5000
```

**Note**: All endpoints are prefixed with `/api`

---

## Authentication

Current version: **No authentication required**

Future versions may implement:
- API key authentication
- OAuth 2.0
- JWT tokens

---

## Response Format

All API responses follow standard HTTP status codes and JSON format.

### Success Response

```json
{
  "status": "success",
  "data": { ... },
  "message": "Operation completed successfully"
}
```

### Error Response

```json
{
  "status": "error",
  "error": "Error description",
  "code": "ERROR_CODE"
}
```

### HTTP Status Codes

- `200 OK` - Success
- `201 Created` - Resource created
- `400 Bad Request` - Invalid input
- `404 Not Found` - Resource not found
- `500 Internal Server Error` - Server error

---

## Error Handling

### Client-Side Error Handling

The Flutter app handles errors as follows:

1. **Network Errors**
   - Connection timeout (10 seconds)
   - No internet connection
   - Backend unavailable
   - Fallback: Offline mode

2. **API Errors**
   - Invalid response format
   - Missing required fields
   - Server errors
   - Fallback: Error message displayed to user

3. **Validation Errors**
   - Input validation before sending
   - Range checks (angles, force)
   - Type validation

---

## Endpoints

### 1. Health Check

**Check if backend is available**

#### Request

```http
GET /api/ping
```

#### Response

```json
{
  "status": "ok",
  "message": "Backend is running",
  "version": "1.0.0",
  "timestamp": "2026-01-22T09:03:47Z"
}
```

#### Flutter Implementation

```dart
static Future<bool> checkBackendAvailable() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/ping'),
    ).timeout(const Duration(seconds: 5));
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}
```

---

### 2. Robot Status

**Get current robot state and sensor data**

#### Request

```http
GET /api/robot/status
```

#### Response

```json
{
  "switch_on": true,
  "safety_interlock": true,
  "gripper_angle": 45.5,
  "force": 3.2,
  "material": "Metal",
  "confidence": 0.95,
  "joint_positions": {
    "J1": 10.0,
    "J2": 20.0,
    "J3": 30.0,
    "J4": 0.0,
    "J5": 0.0,
    "J6": 0.0
  },
  "timestamp": "2026-01-22T09:03:47Z"
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `switch_on` | boolean | System power status |
| `safety_interlock` | boolean | Safety lock status |
| `gripper_angle` | float | Current gripper angle (0-180°) |
| `force` | float | Applied force in Newtons (0-10N) |
| `material` | string | Detected material name |
| `confidence` | float | AI detection confidence (0.0-1.0) |
| `joint_positions` | object | 6-axis joint positions in degrees |
| `timestamp` | string | ISO 8601 timestamp |

#### Flutter Implementation

```dart
static Future<Map<String, dynamic>?> getRobotStatus() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/robot/status'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  } catch (e) {
    debugPrint('Error getting robot status: $e');
    return null;
  }
}
```

---

### 3. Gripper Control

**Send control commands to gripper**

#### Request

```http
POST /api/robot/gripper
Content-Type: application/json
```

**Body:**

```json
{
  "angle": 45.0,
  "max_force": 5.0,
  "switch_on": true
}
```

#### Request Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `angle` | float | Yes | - | Target gripper angle (0-180°) |
| `max_force` | float | No | 10.0 | Maximum force limit (0-10N) |
| `switch_on` | boolean | No | true | System power control |

#### Response

```json
{
  "status": "success",
  "message": "Gripper command executed",
  "current_angle": 45.0,
  "current_force": 3.2
}
```

#### Error Response

```json
{
  "status": "error",
  "error": "Invalid angle value",
  "code": "INVALID_ANGLE"
}
```

#### Validation Rules

- `angle`: Must be between 0 and 180
- `max_force`: Must be between 0 and 10
- `switch_on`: Boolean value

#### Flutter Implementation

```dart
static Future<bool> sendGripperCommand({
  required double angle,
  double? maxForce,
  bool? switchOn,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/robot/gripper'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'angle': angle,
        'max_force': maxForce ?? 10.0,
        'switch_on': switchOn ?? true,
      }),
    );
    return response.statusCode == 200;
  } catch (e) {
    debugPrint('Error sending gripper command: $e');
    return false;
  }
}
```

---

### 4. Pattern Management

#### 4.1 Get All Patterns

**Retrieve list of all saved patterns**

##### Request

```http
GET /api/patterns
```

##### Response

```json
[
  {
    "id": 1,
    "name": "Pick and Place",
    "description": "Basic pick and place operation",
    "created_at": "2026-01-20T10:00:00Z",
    "updated_at": "2026-01-20T10:00:00Z",
    "steps": [
      {
        "id": 1,
        "pattern_id": 1,
        "step_order": 0,
        "action_type": "release",
        "params": {"angle": 90},
        "created_at": "2026-01-20T10:00:00Z"
      },
      {
        "id": 2,
        "pattern_id": 1,
        "step_order": 1,
        "action_type": "wait",
        "params": {"duration": 1.0},
        "created_at": "2026-01-20T10:00:00Z"
      }
    ]
  }
]
```

##### Flutter Implementation

```dart
static Future<List<dynamic>> getPatterns() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/patterns'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as List;
    }
    return [];
  } catch (e) {
    debugPrint('Error getting patterns: $e');
    return [];
  }
}
```

---

#### 4.2 Get Specific Pattern

**Retrieve single pattern with all steps**

##### Request

```http
GET /api/patterns/{id}
```

##### Path Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `id` | integer | Pattern ID |

##### Response

```json
{
  "id": 1,
  "name": "Pick and Place",
  "description": "Basic pick and place operation",
  "created_at": "2026-01-20T10:00:00Z",
  "updated_at": "2026-01-20T10:00:00Z",
  "steps": [...]
}
```

##### Error Response (404)

```json
{
  "status": "error",
  "error": "Pattern not found",
  "code": "PATTERN_NOT_FOUND"
}
```

---

#### 4.3 Create Pattern

**Create new pattern with steps**

##### Request

```http
POST /api/patterns
Content-Type: application/json
```

**Body:**

```json
{
  "name": "New Pattern",
  "description": "Pattern description",
  "steps": [
    {
      "step_order": 0,
      "action_type": "grip",
      "params": {"angle": 45}
    },
    {
      "step_order": 1,
      "action_type": "wait",
      "params": {"duration": 2.0}
    }
  ]
}
```

##### Response (201)

```json
{
  "status": "success",
  "message": "Pattern created",
  "pattern_id": 5
}
```

---

#### 4.4 Delete Pattern

**Delete pattern and all its steps**

##### Request

```http
DELETE /api/patterns/{id}
```

##### Response

```json
{
  "status": "success",
  "message": "Pattern deleted"
}
```

##### Flutter Implementation

```dart
static Future<bool> deletePattern(int id) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/patterns/$id'),
    );
    return response.statusCode == 200;
  } catch (e) {
    debugPrint('Error deleting pattern: $e');
    return false;
  }
}
```

---

### 5. Teaching Mode

#### 5.1 Record Step to Buffer

**Add step to teaching buffer**

##### Request

```http
POST /api/teach/record
Content-Type: application/json
```

**Body (Grip):**

```json
{
  "action_type": "grip",
  "params": {
    "angle": 45.0
  }
}
```

**Body (Release):**

```json
{
  "action_type": "release",
  "params": {
    "angle": 90.0
  }
}
```

**Body (Wait):**

```json
{
  "action_type": "wait",
  "params": {
    "duration": 2.0
  }
}
```

##### Response

```json
{
  "status": "success",
  "message": "Step recorded",
  "buffer_size": 3
}
```

---

#### 5.2 Get Teaching Buffer

**Retrieve current teaching buffer**

##### Request

```http
GET /api/teach/buffer
```

##### Response

```json
[
  {
    "step_order": 0,
    "action_type": "grip",
    "params": {"angle": 45}
  },
  {
    "step_order": 1,
    "action_type": "wait",
    "params": {"duration": 1.0}
  }
]
```

---

#### 5.3 Save Buffer as Pattern

**Save teaching buffer as named pattern**

##### Request

```http
POST /api/teach/save
Content-Type: application/json
```

**Body:**

```json
{
  "name": "Pattern Name",
  "description": "Optional description"
}
```

##### Response

```json
{
  "status": "success",
  "message": "Pattern saved",
  "pattern_id": 10
}
```

---

#### 5.4 Execute Buffer

**Test execute current buffer**

##### Request

```http
POST /api/teach/execute
```

##### Response

```json
{
  "status": "success",
  "message": "Buffer executed successfully",
  "execution_time": 5.2
}
```

---

#### 5.5 Delete Buffer Step

**Delete specific step from buffer**

##### Request

```http
DELETE /api/teach/buffer/{index}
```

##### Path Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `index` | integer | Step index (0-based) |

##### Response

```json
{
  "status": "success",
  "message": "Step deleted",
  "buffer_size": 2
}
```

---

#### 5.6 Clear Buffer

**Clear entire teaching buffer**

##### Request

```http
DELETE /api/teach/buffer/clear
```

##### Response

```json
{
  "status": "success",
  "message": "Buffer cleared"
}
```

---

## Data Models

### Pattern

```typescript
interface Pattern {
  id: number;
  name: string;
  description?: string;
  created_at: string;
  updated_at: string;
  steps: PatternStep[];
}
```

### PatternStep

```typescript
interface PatternStep {
  id: number;
  pattern_id: number;
  step_order: number;
  action_type: 'grip' | 'release' | 'wait' | 'move_joints';
  params: {
    angle?: number;      // For grip/release
    duration?: number;   // For wait
    positions?: object;  // For move_joints
  };
  created_at: string;
}
```

### RobotStatus

```typescript
interface RobotStatus {
  switch_on: boolean;
  safety_interlock: boolean;
  gripper_angle: number;
  force: number;
  material: string;
  confidence: number;
  joint_positions: {
    J1: number;
    J2: number;
    J3: number;
    J4: number;
    J5: number;
    J6: number;
  };
  timestamp: string;
}
```

---

## Examples

### Example 1: Complete Pick-and-Place Flow

```dart
// 1. Check backend availability
bool isAvailable = await ApiService.checkBackendAvailable();

if (!isAvailable) {
  print('Backend not available');
  return;
}

// 2. Get current status
var status = await ApiService.getRobotStatus();
print('Current angle: ${status['gripper_angle']}');

// 3. Open gripper
await ApiService.sendGripperCommand(
  angle: 90.0,
  maxForce: 5.0,
  switchOn: true,
);

// 4. Wait
await Future.delayed(Duration(seconds: 1));

// 5. Close gripper
await ApiService.sendGripperCommand(
  angle: 30.0,
  maxForce: 5.0,
  switchOn: true,
);
```

### Example 2: Create and Save Pattern

```dart
// 1. Record steps to buffer
await ApiService.recordStep(actionType: 'release', params: {'angle': 90});
await ApiService.recordStep(actionType: 'wait', params: {'duration': 1.0});
await ApiService.recordStep(actionType: 'grip', params: {'angle': 30});

// 2. Test execution
bool success = await ApiService.executeBuffer();

if (success) {
  // 3. Save pattern
  await ApiService.saveBuffer(name: 'Pick and Place');
  print('Pattern saved!');
}
```

### Example 3: Sync Patterns

```dart
// Pull all patterns from backend
List<dynamic> patterns = await ApiService.getPatterns();

// Save each to local database
for (var patternJson in patterns) {
  Pattern pattern = Pattern.fromJson(patternJson);
  await DatabaseService.instance.savePattern(pattern);
}

print('Synced ${patterns.length} patterns');
```

---

## Rate Limiting

Current version: **No rate limiting**

Future implementations may include:
- Request throttling
- Maximum requests per minute
- Backoff strategies

---

## Webhooks / Real-time Updates

Current version: **Polling-based updates**

The app polls `/api/robot/status` every 1 second for real-time data.

Future implementations may include:
- WebSocket support
- Server-sent events (SSE)
- MQTT integration

---

## Version History

### API v1.0.0 (Current)
- All endpoints documented above
- No breaking changes expected in v1.x

---

## Support

For API issues or questions:
- Review this documentation
- Check backend logs
- Contact development team

---

**Last Updated**: January 22, 2026  
**API Version**: 1.0.0  
**App Version**: 1.0.0
