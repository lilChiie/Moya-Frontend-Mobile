import '../utils/user_errors.dart';
import 'api_response.dart';
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
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.destinations}',
    );
    final token = await _getToken();

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'ngrok-skip-browser-warning': 'true',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 401 || response.statusCode == 422) {
        return {'success': false, 'message': UserErrors.session};
      }

      final responseData = decodeApiResponse(response);

      if (response.statusCode == 200) {
        final dataList =
            responseData is List
                ? responseData
                : responseData is Map
                ? responseData['data'] ?? responseData['destinations']
                : null;
        if (dataList is! List) {
          return {'success': false, 'message': UserErrors.unavailable};
        }

        return {'success': true, 'data': dataList};
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ??
              responseData['msg'] ??
              UserErrors.unavailable,
        };
      }
    } catch (e) {
      return {'success': false, 'message': UserErrors.fromError(e)};
    }
  }
}
