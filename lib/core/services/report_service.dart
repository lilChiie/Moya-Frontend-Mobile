import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ReportService {
  Future<Map<String, dynamic>> submitReport({
    required int destinationId,
    required String userNotes,
    required File image,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reports}');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        return {
          'success': false,
          'message': 'User ID not found. Please log in again.',
        };
      }

      var request = http.MultipartRequest('POST', url);
      
      final token = prefs.getString('access_token');
      
      request.headers.addAll({
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      request.fields['user_id'] = userId.toString();
      request.fields['destination_id'] = destinationId.toString();
      request.fields['user_notes'] = userNotes;

      request.files.add(
        await http.MultipartFile.fromPath('image', image.path),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final responseData = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Report submitted successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to submit report',
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
