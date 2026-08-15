import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class NotificationService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // GET /api/notifications/
  Future<Map<String, dynamic>> getNotifications() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notifications}');
    final token = await _getToken();

    try {
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<dynamic> list = [];
        if (responseData is Map && responseData.containsKey('data')) {
          list = responseData['data'] as List<dynamic>? ?? [];
        } else if (responseData is List) {
          list = responseData;
        }

        return {
          'success': true,
          'data': list,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? responseData['msg'] ?? 'Failed to load notifications.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Something went wrong: $e'};
    }
  }

  // PUT /api/notifications/read/{id} (or fallback /api/notifications/{id}/read)
  Future<Map<String, dynamic>> markAsRead(int notificationId) async {
    final token = await _getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      // Primary route: /api/notifications/read/{id}
      var url = Uri.parse('${ApiConstants.baseUrl}/api/notifications/read/$notificationId');
      var response = await http.put(url, headers: headers, body: '');

      if (response.statusCode == 404) {
        // Fallback route: /api/notifications/{id}/read
        url = Uri.parse('${ApiConstants.baseUrl}/api/notifications/$notificationId/read');
        response = await http.put(url, headers: headers, body: '');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Notification marked as read.',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? responseData['msg'] ?? 'Failed to mark notification as read.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Something went wrong: $e'};
    }
  }
}
