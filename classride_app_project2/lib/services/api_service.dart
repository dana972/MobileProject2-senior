import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final String authUrl = dotenv.env['API_URL'] ?? 'http://127.0.0.1:5000/api/auth';
  static final String studentUrl = dotenv.env['STUDENT_API_URL'] ?? 'http://127.0.0.1:5000/api/student';
  static final String driverUrl = dotenv.env['DRIVER_API_URL'] ?? 'http://127.0.0.1:5000/api/driver';

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

  static Future<Map<String, dynamic>?> fetchAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return null;

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
        return null;
      }
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

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
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>?> fetchSchedule(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return null;

    final client = BrowserClient();
    try {
      final response = await client.get(
        Uri.parse('$studentUrl/schedule?date=$date'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  static Future<bool> updateSchedule({
    required String date,
    required String morningTime,
    required String returnTime,
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
      return response.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  static Future<List<dynamic>> fetchWeeklySchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return [];

    final client = BrowserClient();
    try {
      final response = await client.get(
        Uri.parse('$studentUrl/weekly-schedule'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (_) {
      return [];
    } finally {
      client.close();
    }
  }

  static Future<bool> updateWeeklySchedule({
    required String dayOfWeek,
    required String morningTime,
    required String returnTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return false;

    final dayMap = {
      "Monday": 1,
      "Tuesday": 2,
      "Wednesday": 3,
      "Thursday": 4,
      "Friday": 5,
      "Saturday": 6,
      "Sunday": 7,
    };

    final dayNumber = dayMap[dayOfWeek];
    if (dayNumber == null) return false;

    final client = BrowserClient();
    try {
      final response = await client.post(
        Uri.parse('$studentUrl/update-weekly-schedule'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'day_of_week': dayNumber,
          'morning_time': morningTime,
          'return_time': returnTime,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }
}
