import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class RankService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // GET /api/ranks
  Future<Map<String, dynamic>> getRanks() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.ranks}');
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

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'];
          
          final List<Map<String, dynamic>> parsedData = data.map((e) {
            return {
              'id': e['id'],
              'name': e['name'],
              'min_point': e['min_point'],
              'max_point': e['max_point'],
              'avatar': e['avatar'] != null ? e['avatar'].toString().replaceFirst('http://', 'https://') : null,
            };
          }).toList();
          
          return {
            'success': true,
            'data': parsedData,
          };
        } else {
          return {
            'success': false,
            'message': 'Failed to load ranks data.',
            'data': [],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'data': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Exception occurred: $e',
        'data': [],
      };
    }
  }
}
