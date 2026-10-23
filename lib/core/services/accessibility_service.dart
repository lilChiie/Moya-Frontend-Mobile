import '../utils/user_errors.dart';
import 'api_response.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class AccessibilityService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // GET /api/accessibility
  Future<Map<String, dynamic>> getAccessibilityNeeds() async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.accessibility}',
    );
    final token = await _getToken();

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final responseData = decodeApiResponse(response);

      if (response.statusCode == 200) {
        List<dynamic> dataList = [];

        if (responseData is List) {
          dataList = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          dataList = responseData['data'] as List<dynamic>;
        }

        return {'success': true, 'data': dataList};
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to load accessibility needs.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': UserErrors.fromError(e)};
    }
  }

  // PUT /api/accessibility/{id}
  Future<Map<String, dynamic>> updateAccessibilityNeed(
    String id,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.accessibility}/$id',
    );
    final token = await _getToken();

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      final responseData = decodeApiResponse(response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Update failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': UserErrors.fromError(e)};
    }
  }

  // DELETE /api/accessibility/{id}
  Future<Map<String, dynamic>> deleteAccessibilityNeed(String id) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.accessibility}/$id',
    );
    final token = await _getToken();

    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final responseData = decodeApiResponse(response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Delete failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': UserErrors.fromError(e)};
    }
  }
}
