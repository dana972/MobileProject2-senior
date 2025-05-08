import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final String authUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:5000/api/auth';
  static final String studentUrl = dotenv.env['STUDENT_API_URL'] ?? 'http://127.0.0.1:5000/api/student';
  static final String driverUrl = dotenv.env['DRIVER_API_URL'] ?? 'http://127.0.0.1:5000/api/driver';

  // =======================
  // SIGNUP
  // =======================
  static Future<Map<String, dynamic>> signup({
    required String fullName,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$authUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'phone_number': phoneNumber,
          'password': password,
        }),
      );

      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Empty response from server',
          'status': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Signup failed: $e',
      };
    }
  }

  // =======================
  // LOGIN + TOKEN SAVE
  // =======================
  static Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$authUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': phoneNumber,
          'password': password,
        }),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);

        if (data.containsKey('token')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['token']);
        }

        return data;
      } else {
        return {
          'success': false,
          'message': 'Login failed',
          'status': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Login error: $e',
      };
    }
  }

  // =======================
  // FETCH ATTENDANCE (Web-safe)
  // =======================
  static Future<Map<String, dynamic>?> fetchAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      print('❌ No token found');
      return null;
    }

    final client = BrowserClient();
    try {
      final response = await client.get(
        Uri.parse('$studentUrl/attendance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ Error fetching attendance: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Exception fetching attendance: $e');
      return null;
    } finally {
      client.close();
    }
  }

  // =======================
  // UPDATE DRIVER INFO
  // =======================
  static Future<Map<String, dynamic>> updateDriverInfo({
    required String oldPhoneNumber,
    required String fullName,
    required String newPhoneNumber,
    required String license,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$driverUrl/update/$oldPhoneNumber'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'new_phone_number': newPhoneNumber,
          'license': license,
        }),
      );

      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Empty response from server',
          'status': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Update failed: $e',
      };
    }
  }

  // =======================
  // UPDATE ATTENDANCE
  // =======================
  static Future<bool> updateAttendance({
    required String date,
    required bool isMorning,
    required bool isPresent,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) return false;

    final current = await fetchAttendance();
    if (current == null) return false;

    final Map<String, dynamic> targetDay =
    current[date == DateTime.now().toIso8601String().split('T')[0] ? 'today' : 'tomorrow'];

    final bool attendanceMorning = isMorning ? isPresent : targetDay['attendance_morning'] ?? false;
    final bool attendanceReturn = !isMorning ? isPresent : targetDay['attendance_return'] ?? false;

    final client = BrowserClient();
    try {
      final response = await client.put(
        Uri.parse('$studentUrl/attendance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'date': date,
          'attendance_morning': attendanceMorning,
          'attendance_return': attendanceReturn,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error updating attendance: $e');
      return false;
    } finally {
      client.close();
    }

  }

  // =======================
  // FETCH SCHEDULE (morning/return times)
  // =======================
  static Future<Map<String, dynamic>?> fetchSchedule(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      print('❌ No token found for schedule');
      return null;
    }

    final client = BrowserClient();
    try {
      final uri = Uri.parse('$studentUrl/schedule?date=$date');
      final response = await client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('❌ Error fetching schedule: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Exception fetching schedule: $e');
      return null;
    } finally {
      client.close();
    }
  }

  // =======================
  // UPDATE SCHEDULE (override or delete)
  // =======================
  static Future<bool> updateSchedule({
    required String date,
    required String morningTime,  // format: "HH:mm:ss"
    required String returnTime,   // format: "HH:mm:ss"
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) return false;

    final client = BrowserClient();
    try {
      final response = await client.post(
        Uri.parse('$studentUrl/schedule'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'date': date,
          'morning_time': morningTime,
          'return_time': returnTime,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Schedule updated');
        return true;
      } else {
        print('❌ Failed to update schedule: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Exception updating schedule: $e');
      return false;
    } finally {
      client.close();
    }
  }

}
