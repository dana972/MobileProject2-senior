import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final String authUrl = '${dotenv.env['API_URL'] ?? 'http://127.0.0.1:5000'}/api/auth';
  static final String studentUrl = dotenv.env['STUDENT_API_URL'] ?? 'http://127.0.0.1:5000/api/student';
  static final String driverUrl = dotenv.env['DRIVER_API_URL'] ?? 'http://127.0.0.1:5000/api/driver';
  static final String chatUrl =
      '${dotenv.env['API_URL'] ?? 'http://127.0.0.1:5000'}/api/chat';
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
          await prefs.setString('phone_number', phoneNumber); // ✅ ADD THIS LINE

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

    final client = http.Client();
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

    final client = http.Client();
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

    final client = http.Client();
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

    final client = http.Client();
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

    final client = http.Client();
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
    required int dayOfWeek,
    required String morningTime,
    required String returnTime,
    required bool attendanceMorning,
    required bool attendanceReturn,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return false;

    final body = {
      'day_of_week': dayOfWeek,
      'morning_time': morningTime,
      'return_time': returnTime,
      'attendance_morning': attendanceMorning,
      'attendance_return': attendanceReturn,
    };

    final client = http.Client();
    try {
      final response = await client.post(
        Uri.parse('$studentUrl/update-weekly-schedule'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }


  static Future<List<dynamic>> fetchAssignedTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return [];

    final client = http.Client();
    try {
      final response = await client.get(
        Uri.parse('$studentUrl/assigned-trips'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['trips'] ?? [];
        }
      }

      return [];
    } catch (_) {
      return [];
    } finally {
      client.close();
    }
  }

  static Future<Map<String, dynamic>?> fetchActiveTrip() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return null;

    final client = http.Client();
    try {
      final response = await client.get(
        Uri.parse('$studentUrl/active-trip'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['trip'] != null) {
          return data['trip'];
        }
      }

      return null;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }

  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token'); // Or await prefs.clear(); to remove all data
  }


  static Future<Map<String, dynamic>?> getOrCreateChat(String phone1, String phone2) async {
    final uri = Uri.parse('$chatUrl/get-or-create');
    final response = await http.post(
      Uri.parse('${dotenv.env['API_URL'] ?? 'http://127.0.0.1:5000'}/api/chat/get-or-create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone1': phone1, 'phone2': phone2}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body)['chat'];
    } else {
      return null;
    }
  }
  static Future<List<dynamic>> fetchChatMessages(String chatId) async {
    final uri = Uri.parse('$chatUrl/$chatId/messages');
    final response = await http.get(
      Uri.parse('${dotenv.env['API_URL'] ?? 'http://127.0.0.1:5000'}/api/chat/$chatId/messages'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['messages'];
    } else {
      return [];
    }
  }
  static Future<bool> sendChatMessage({required String chatId,
    required String senderPhone,
    required String messageText, }) async {
    final uri = Uri.parse('$chatUrl/send');


    final response = await http.post(
      Uri.parse('${dotenv.env['API_URL'] ?? 'http://127.0.0.1:5000'}/api/chat/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'chatId': chatId,
        'senderPhone': senderPhone,
        'messageText': messageText,
      }),
    );

    return response.statusCode == 201;
  }

  static Future<List<Map<String, dynamic>>> fetchChatList(String myPhone) async {
    final uri = Uri.parse('$chatUrl/list/$myPhone');
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL'] ?? 'http://127.0.0.1:5000'}/api/chat/list/$myPhone'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['chats'].map((chat) {
            return {
              'chat_id': chat['chat_id'],
              'other_participant': chat['other_participant'],
              'other_participant_name': chat['other_participant_name'], // 👈 Use this
              'last_message': chat['last_message'],
              'last_message_time': chat['last_message_time'],
            };
          }));
        }
      }

      return [];
    } catch (e) {
      print("Error fetching chat list: $e");
      return [];
    }
  }


  static Future<List<Map<String, dynamic>>> fetchDriverAssignedTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phone_number'); // Ensure this is stored at login
    print('📱 Driver phone from prefs: $phone');

    if (phone == null) return [];

    final uri = Uri.parse('$driverUrl/trips/$phone');
    print('📡 Constructed driver trip URL: $uri');

    try {
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['trips'] != null) {
          return List<Map<String, dynamic>>.from(data['trips']);
        }
      }
      return [];
    } catch (e) {
      print("❌ Error fetching driver assigned trips: $e");
      return [];
    }
  }


  static Future<bool> activateTrip(int tripId) async {
    final uri = Uri.parse('$driverUrl/trip/$tripId/activate');

    try {
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print("✅ Trip $tripId activated successfully.");
        return true;
      } else {
        print("❌ Failed to activate trip $tripId: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error activating trip $tripId: $e");
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchActiveTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phone_number'); // Get the driver phone number
    if (phone == null) return [];

    final uri = Uri.parse('$driverUrl/trips/$phone/active'); // You may need to update this URL as per your backend.

    try {
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['trips'] != null) {
          return List<Map<String, dynamic>>.from(data['trips']);
        }
      }
      return [];
    } catch (e) {
      print("❌ Error fetching active trips: $e");
      return [];
    }
  }


  // Function to update payment status for a student in a trip
  static Future<bool> updatePaymentStatus({
    required int tripId,
    required String studentPhone,
    required bool paid,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return false;

    final client = http.Client();
    try {
      final response = await client.put(
        Uri.parse('$driverUrl/trip/$tripId/payment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'tripId': tripId,
          'studentPhone': studentPhone,
          'paid': paid,
        }),
      );

      return response.statusCode == 200; // Return true if the update was successful
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }
// Mark a trip as completed
  static Future<bool> completeTrip(int tripId) async {
    final uri = Uri.parse('$driverUrl/trip/$tripId/complete');

    try {
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print("✅ Trip $tripId completed successfully.");
        return true;
      } else {
        print("❌ Failed to complete trip $tripId: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error completing trip $tripId: $e");
      return false;
    }
  }


  // Fetch Completed Trips for a Driver
  static Future<List<Map<String, dynamic>>> fetchCompletedTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phone_number'); // Ensure this is stored at login
    print('📱 Driver phone from prefs: $phone');

    if (phone == null) return [];

    final uri = Uri.parse('$driverUrl/trips/$phone/completed');  // Update this URL based on your backend

    try {
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['trips'] != null) {
          return List<Map<String, dynamic>>.from(data['trips']);
        }
      }
      return [];
    } catch (e) {
      print("❌ Error fetching completed trips: $e");
      return [];
    }
  }


  static Future<bool> deleteWeeklyScheduleDay(String dayName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return false;

    final client = http.Client();
    try {
      final response = await client.delete(
        Uri.parse('$studentUrl/weekly-schedule/$dayName'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

}




