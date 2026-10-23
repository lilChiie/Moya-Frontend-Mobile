import '../utils/user_errors.dart';
import 'api_response.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ReportService {
  ReportService({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<Map<String, dynamic>> getMyReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final userId = prefs.getInt('user_id');
      if (token == null || token.isEmpty || userId == null) {
        return {'success': false, 'message': UserErrors.session};
      }
      final url = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.reports}',
      ).replace(queryParameters: {'user_id': userId.toString()});
      final headers = {
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'Authorization': 'Bearer $token',
      };
      final response = await (_client?.get(url, headers: headers) ??
              http.get(url, headers: headers))
          .timeout(const Duration(seconds: 20));
      final body = decodeApiResponse(response);
      if (body is Map && body['success'] == false) {
        return {
          'success': false,
          'message': UserErrors.message(body['message']?.toString()),
        };
      }
      final data =
          body is List
              ? body
              : body is Map
              ? body['data']
              : null;
      if (data is! List) {
        return {'success': false, 'message': UserErrors.unavailable};
      }
      // The shared endpoint may ignore query filters. Never show another user's reports.
      final reports =
          data
              .whereType<Map>()
              .where(
                (report) => report['user_id']?.toString() == userId.toString(),
              )
              .map((report) => Map<String, dynamic>.from(report))
              .toList();
      return {'success': true, 'data': reports};
    } catch (error) {
      return {'success': false, 'message': UserErrors.fromError(error)};
    }
  }

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
        return {'success': false, 'message': UserErrors.session};
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

      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final responseData = decodeApiResponse(
        http.Response(responseBody, response.statusCode),
      );

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
      return {'success': false, 'message': UserErrors.fromError(e)};
    }
  }
}
