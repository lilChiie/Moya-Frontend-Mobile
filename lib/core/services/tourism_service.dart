import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class TourismService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // GET /api/tourism
  Future<Map<String, dynamic>> getTourismCategories() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tourism}');
    final token = await _getToken();

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Assuming the response is either a list directly, or a map with a 'data' array.
        // E.g. {"data": [{"id": 1, "name": "Nature"}, ...]} OR [{"id": 1, "name": "Nature"}, ...]
        List<dynamic> categoriesList = [];
        
        if (responseData is List) {
          categoriesList = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          categoriesList = responseData['data'] as List<dynamic>;
        }

        return {
          'success': true,
          'data': categoriesList,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to load tourism categories.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }
  // GET /api/tourism/latest
  Future<Map<String, dynamic>> getLatestTourism() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.latestTourism}');
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
          'message': responseData['message'] ?? 'Failed to load latest tourism',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // PUT /api/tourism/{id}
  Future<Map<String, dynamic>> updateTourismCategory(String id, Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tourism}/$id');
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

      final responseData = jsonDecode(response.body);

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
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // DELETE /api/tourism/{id}
  Future<Map<String, dynamic>> deleteTourismCategory(String id) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tourism}/$id');
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

      final responseData = jsonDecode(response.body);

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
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }
}
