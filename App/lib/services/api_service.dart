import 'dart:convert';
import 'package:http/http.dart' as http;
import 'prefs_service.dart';

class ApiService {
  // Header helper
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  static const Duration _defaultTimeout = Duration(seconds: 5);

  static http.Client client = http.Client();

  // 0. Health check (used to enforce online-only mode)
  static Future<bool> checkBackendAvailable() async {
    try {
      final baseUrl = await PrefsService.getBaseUrl();
      final response = await client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(_defaultTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 1. GET /data
  static Future<Map<String, dynamic>?> getSensorData() async {
    try {
      final baseUrl = await PrefsService.getBaseUrl();
      final response = await client.get(Uri.parse('$baseUrl/data'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // 2. POST /api/robot/gripper (Manual Control)
  static Future<bool> sendGripperCommand({
    required int angle,
    required double maxForce,
    required bool switchOn,
  }) async {
    try {
      final baseUrl = await PrefsService.getBaseUrl();
      final body = {
        "angle": angle,
        "max_force": maxForce,
        "switch_on": switchOn,
      };

      final response = await client.post(
        Uri.parse('$baseUrl/api/robot/gripper'),
        headers: _headers,
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 3. POST /api/teach/record - REMOVED

  // 4. POST /api/teach/save - REMOVED

  // 5. GET /api/teach/buffer - REMOVED

  // 6. POST /auto-run/start/{id}
  static Future<bool> startAutoRun(
    int patternId, {
    int cycles = 5,
    double maxForce = 5.0,
    String filename = "run.csv",
  }) async {
    try {
      final baseUrl = await PrefsService.getBaseUrl();
      // Python API expects JSON body
      final body = {
        "pattern_id": patternId,
        "cycles": cycles,
        "max_force": maxForce,
        "filename": filename,
      };

      final response = await client.post(
        Uri.parse('$baseUrl/auto-run/start'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 7. GET /api/patterns - Get all saved patterns from backend
  static Future<List<dynamic>> getPatterns() async {
    try {
      final baseUrl = await PrefsService.getBaseUrl();
      final response = await client.get(Uri.parse('$baseUrl/api/patterns'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // 8. GET /api/patterns/{id} - Get a specific pattern with steps
  static Future<Map<String, dynamic>?> getPattern(int id) async {
    try {
      final baseUrl = await PrefsService.getBaseUrl();
      final response = await client.get(Uri.parse('$baseUrl/api/patterns/$id'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // 9. DELETE /api/patterns/{id} - Delete a pattern from backend
  static Future<bool> deletePattern(int id) async {
    try {
      final baseUrl = await PrefsService.getBaseUrl();
      final response = await client.delete(
        Uri.parse('$baseUrl/api/patterns/$id'),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 10. DELETE /api/teach/buffer/{index} - REMOVED

  // 11. POST /api/teach/execute - REMOVED

  // 12. DELETE /api/teach/buffer/clear - REMOVED

  // 13. POST /api/teach/execute-sequence - Execute pattern steps on backend
  static Future<bool> executeSequence({
    required List<Map<String, dynamic>> steps,
    required double maxForce,
    required double gripperAngle,
    required bool isOn,
    String patternName = "Untitled",
  }) async {
    try {
      final baseUrl = await PrefsService.getBaseUrl();
      final body = jsonEncode({
        "pattern_name": patternName,
        "max_force": maxForce,
        "gripper_angle": gripperAngle,
        "is_on": isOn,
        "steps": steps,
      });
      final response = await client
          .post(
            Uri.parse('$baseUrl/api/teach/execute-sequence'),
            headers: _headers,
            body: body,
          )
          .timeout(_defaultTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 13.5 POST /api/teach/stop - Stop currently running sequence
  static Future<bool> stopSequence() async {
    try {
      final baseUrl = await PrefsService.getBaseUrl();
      final response = await client
          .post(Uri.parse('$baseUrl/api/teach/stop'), headers: _headers)
          .timeout(_defaultTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 14. GET /api/sync/patterns - Pull all patterns (with steps) from backend
  static Future<List<dynamic>> pullPatterns() async {
    try {
      final baseUrl = await PrefsService.getBaseUrl();
      final response = await client
          .get(Uri.parse('$baseUrl/api/sync/patterns'))
          .timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return decoded['patterns'] as List<dynamic>? ?? [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // 15. POST /api/sync/patterns - Push local patterns (with steps) to backend
  static Future<bool> pushPatterns(List<Map<String, dynamic>> patterns) async {
    try {
      final baseUrl = await PrefsService.getBaseUrl();
      final body = jsonEncode({"patterns": patterns});
      final response = await client
          .post(
            Uri.parse('$baseUrl/api/sync/patterns'),
            headers: _headers,
            body: body,
          )
          .timeout(_defaultTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 16. GET /api/history - Get auto run history
  static Future<List<dynamic>> getRunHistory() async {
    try {
      final baseUrl = await PrefsService.getBaseUrl();
      final response = await client.get(Uri.parse('$baseUrl/api/history'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // 17. DELETE /api/history/{id}
  static Future<bool> deleteRunHistory(int id) async {
    try {
      final baseUrl = await PrefsService.getBaseUrl();
      final response = await client.delete(
        Uri.parse('$baseUrl/api/history/$id'),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
