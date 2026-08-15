import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ReviewService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // GET /api/destinations/{id} → reviews are inside the response
  Future<Map<String, dynamic>> getDestinationReviews(int destinationId) async {
    final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.destinations}$destinationId');
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
        List<dynamic> reviews = [];
        Map<String, dynamic>? destDetail;

        if (responseData is Map) {
          if (responseData.containsKey('data') && responseData['data'] is Map) {
            destDetail = responseData['data'] as Map<String, dynamic>;
            if (destDetail.containsKey('reviews')) {
              reviews = destDetail['reviews'] as List? ?? [];
            }
          } else if (responseData.containsKey('reviews')) {
            reviews = responseData['reviews'] as List? ?? [];
          }
        } else if (responseData is List) {
          reviews = responseData;
        }

        return {
          'success': true,
          'data': reviews,
          'destination': destDetail,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? responseData['msg'] ?? 'Failed to load reviews..',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Something went wrong.: $e'};
    }
  }

  // POST /api/destinations/{id}/add-review
  Future<Map<String, dynamic>> addReview({
    required int destinationId,
    required String review,
  }) async {
    final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.destinations}$destinationId/add-review');
    final token = await _getToken();

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'comment': review}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Review added successfully.!',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? responseData['msg'] ?? 'Failed to send review.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Something went wrong.: $e'};
    }
  }
}
