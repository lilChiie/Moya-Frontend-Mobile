import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class DestinationService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // GET /api/destinations
  Future<Map<String, dynamic>> getDestinations() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.destinations}');
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

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<dynamic> dataList = [];
        
        if (responseData is List) {
          dataList = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          dataList = responseData['data'] as List<dynamic>;
        }

        return {
          'success': true,
          'data': dataList,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to load destinations.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }
}
